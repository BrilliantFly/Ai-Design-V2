#!/usr/bin/env node
/**
 * biz-info-collector / validate-output.js
 *
 * 校验 AI 联网采集产出的 JSON 是否符合字段规范（templates/fields.json）。
 *
 * 用法：
 *   node validate-output.js <file.json>                  # 集合模式（含 meta + 各对象数组）
 *   node validate-output.js <file.json> --type industry  # 单对象模式（文件为记录数组）
 *   node validate-output.js <file.json> --strict         # 缺少来源也按 error
 *
 * 退出码：0 = 无 error；1 = 存在 error。
 */
const fs = require('fs');
const path = require('path');

const SCHEMA_PATH = path.join(__dirname, '..', 'templates', 'fields.json');
const META_KEYS = new Set(['_sources', '_notes', '_relations', '_confidence']);

function parseArgs(argv) {
    const args = { file: null, type: null, strict: false };
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === '--type') args.type = argv[++i];
        else if (a === '--strict') args.strict = true;
        else if (!a.startsWith('--')) args.file = a;
    }
    return args;
}

function isEmpty(v) {
    if (v === undefined || v === null) return true;
    if (typeof v === 'string') return v.trim() === '';
    if (Array.isArray(v)) return v.length === 0;
    return false;
}

function isUrl(s) { return /^https?:\/\/\S+/i.test(String(s)); }

function main() {
    const args = parseArgs(process.argv.slice(2));

    if (!args.file) {
        console.error('用法: node validate-output.js <file.json> [--type <objectKey>] [--strict]');
        process.exit(2);
    }
    if (!fs.existsSync(SCHEMA_PATH)) {
        console.error('[FATAL] 找不到字段规范：' + SCHEMA_PATH);
        process.exit(2);
    }
    const schema = JSON.parse(fs.readFileSync(SCHEMA_PATH, 'utf8'));
    const objects = schema.objects || {};

    const abs = path.resolve(process.cwd(), args.file);
    if (!fs.existsSync(abs)) { console.error('[ERROR] 文件不存在: ' + abs); process.exit(1); }

    let data;
    try { data = JSON.parse(fs.readFileSync(abs, 'utf8')); }
    catch (e) { console.error('[ERROR] JSON 解析失败: ' + e.message); process.exit(1); }

    // 归一化为 { objectKey: [records] } + meta
    let buckets = {};
    let meta = null;
    if (args.type) {
        if (!Array.isArray(data)) { console.error('[ERROR] --type 模式下文件应为记录数组'); process.exit(1); }
        buckets[args.type] = data;
    } else if (Array.isArray(data)) {
        console.error('[ERROR] 文件是数组，请用 --type <objectKey> 指定对象类型');
        process.exit(1);
    } else {
        meta = data.meta || null;
        for (const [k, v] of Object.entries(data)) {
            if (k === 'meta') continue;
            if (!Array.isArray(v)) { console.error(`[WARN] 跳过非数组字段: ${k}`); continue; }
            buckets[k] = v;
        }
    }

    const errors = [];
    const warnings = [];
    const err = (m) => errors.push(m);
    const warn = (m) => warnings.push(m);

    if (!args.type) {
        if (!meta) warn('缺少 meta（建议含 topic/collectedAt/sourcesSummary）');
        else {
            if (isEmpty(meta.topic)) warn('meta.topic 为空');
            if (isEmpty(meta.collectedAt)) warn('meta.collectedAt 为空');
        }
    }

    let totalRecords = 0;
    for (const [key, records] of Object.entries(buckets)) {
        const def = schema.objects[key];
        if (!def) { warn(`未知对象「${key}」：不在 fields.json 中，已跳过校验`); continue; }
        const fields = def.fields || {};
        const required = def.required || [];
        const privacy = new Set(def.privacy || []);

        if (!records.length) { warnings.push(`对象「${key}」为空（0 条）`); continue; }

        records.forEach((rec, idx) => {
            totalRecords++;
            const where = `${key}[#${idx + 1}]`;
            if (typeof rec !== 'object' || rec === null || Array.isArray(rec)) {
                err(`${where}: 记录不是对象`); return;
            }
            const keys = Object.keys(rec);

            // 必填
            required.forEach(f => {
                if (isEmpty(rec[f])) err(`${where} 缺少必填字段 ${f}（${fields[f] || ''}）`);
            });

            // 隐私（禁止出现且非空）
            privacy.forEach(f => {
                if (!isEmpty(rec[f])) err(`${where} 含不采集的隐私字段「${f}」(${fields[f] || ''})，请删除`);
            });

            // 来源
            const hasContent = Object.entries(rec).some(([k, v]) => !k.startsWith('_') && !isEmpty(v));
            if (isEmpty(rec._sources)) {
                const msg = `${key}[#${idx}] 缺少 _sources（非空字段无法溯源）`;
                if (args.strict && hasContent) err(where + ' 缺少 _sources：非空字段必须可溯源'); else warn(where + ' 缺少 _sources');
            } else if (!Array.isArray(rec._sources)) {
                err(`${where}._sources 应为数组`);
            } else {
                rec._sources.forEach((s, i) => { if (!isUrl(s)) warn(`${where}._sources[${i}] 不是 URL: ${JSON.stringify(s)}`); });
            }

            // 必填缺失但整条为空时，额外提示
            if (isEmpty(rec) || Object.keys(rec).filter(k => !META_KEYS.has(k)).length === 0) {
                warn(`${where} 没有任何业务字段`);
            }

            // 未知字段
            for (const k of Object.keys(rec)) {
                if (META_KEYS.has(k)) continue;
                if (!(k in fields)) warn(`${where} 未知字段「${k}」（不在字段模板，可能是笔误）`);
            }
            // 隐私字段出现但为空 -> 提示移除
            privacy.forEach(p => {
                if (Object.prototype.hasOwnProperty.call(rec, p) && isEmpty(rec[p])) {
                    warn(`${key}[#${idx}] 含隐私字段「${p}」但为空，建议直接删除该键`);
                }
            });
        });
    }

    console.log('=== 采集结果校验 ===');
    console.log(`文件: ${abs}`);
    console.log(`模式: ${args.type ? '单对象(' + args.type + ')' : '集合'}${args.strict ? ' · strict' : ''}`);
    console.log(`对象: ${Object.keys(buckets).length} 个，记录: ${totalRecords} 条`);
    console.log('');

    if (warnings.length) {
        console.log(`--- WARNING (${warnings.length}) ---`);
        warnings.forEach(w => console.log('  ⚠ ' + w));
        console.log('');
    }
    if (errors.length) {
        console.log(`--- ERROR (${errors.length}) ---`);
        errors.forEach(e => console.log('  ✗ ' + e));
        console.log('');
        console.log('结论: 未通过 ✗');
        process.exit(1);
    }
    console.log('结论: 通过 ✓' + (warnings.length ? `（有 ${warnings.length} 条 warning）` : ''));
    process.exit(0);
}

main();

#!/usr/bin/env node
/**
 * biz-info-collector / to-sql.js
 *
 * 把「联网采集结果 JSON」转换为可直接执行的 INSERT SQL：
 *   - 字段名 → 数据库列名（templates/db-mapping.json）
 *   - 自动生成主键 id（雪花，bigint，非自增）
 *   - 自动补系统字段：create_time / update_time（毫秒）、软删列（del_flag / deleted）
 *   - 处理关联关系：行业-产品/企业/市场、企业-产品、客户-行业、行业 parent、客户-企业、画像-客户
 *   - 隐私字段不落库
 *
 * 用法：
 *   node to-sql.js collected/xxx.json
 *   node to-sql.js collected/xxx.json --out out.sql
 *   node to-sql.js collected/xxx.json --dry-run          # 只打印统计，不写文件
 *   node to-sql.js collected/xxx.json --truncate         # 超长字段按列长度截断
 *   node to-sql.js industry.json --type industry         # 输入是单对象数组
 */
const fs = require('fs');
const path = require('path');

const MAPPING_PATH = path.join(__dirname, '..', 'templates', 'db-mapping.json');

// ---------- 参数 ----------
function parseArgs(argv) {
  const a = { file: null, out: null, dryRun: false, truncate: false, noTx: false, type: null };
  for (let i = 0; i < argv.length; i++) {
    const s = argv[i];
    if (s === '--out') a.out = argv[++i];
    else if (s === '--type') a.type = argv[++i];
    else if (s === '--dry-run') a.dryRun = true;
    else if (s === '--truncate') a.truncate = true;
    else if (s === '--no-transaction') a.noTx = true;
    else if (!s.startsWith('--')) a.file = s;
  }
  return a;
}

// ---------- 工具 ----------
const isEmpty = (v) => v === undefined || v === null || (typeof v === 'string' && v.trim() === '') || (Array.isArray(v) && v.length === 0);
const norm = (v) => String(v == null ? '' : v).replace(/\s+/g, '').toLowerCase();
const toArray = (v) => (Array.isArray(v) ? v : (v == null || v === '' ? [] : [v]));

function sqlStr(s) {
  return "'" + String(s).replace(/\\/g, '\\\\').replace(/'/g, "''") + "'";
}

function fmt(type, v) {
  switch (type) {
    case 'int': {
      const n = parseInt(v, 10);
      return Number.isNaN(n) ? 'NULL' : String(n);
    }
    case 'decimal': {
      const n = Number(v);
      return Number.isNaN(n) ? 'NULL' : String(n);
    }
    case 'date': {
      const s = String(v).trim();
      if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return sqlStr(s);
      const d = new Date(s);
      if (!Number.isNaN(d.getTime())) return sqlStr(d.toISOString().slice(0, 10));
      return sqlStr(s);
    }
    default:
      return sqlStr(v);
  }
}

// ---------- 雪花 id ----------
const EPOCH = 1288834974657n;
let seq = 0;
function nextId() {
  const t = BigInt(Date.now() - Number(EPOCH));
  seq = (seq + 1) & 0xfff;
  return ((t << 22n) | (1n << 12n) | BigInt(seq)).toString();
}

// ---------- 主流程 ----------
function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.file) { console.error('用法: node to-sql.js <collected.json> [--out x.sql] [--dry-run] [--truncate] [--type <object>]'); process.exit(2); }

  let mapping;
  try { mapping = JSON.parse(fs.readFileSync(MAPPING_PATH, 'utf8')); }
  catch (e) { console.error('[ERROR] 读取映射失败 ' + MAPPING_PATH + ': ' + e.message); process.exit(1); }

  const abs = path.resolve(process.cwd(), args.file);
  if (!fs.existsSync(abs)) { console.error('[ERROR] 文件不存在: ' + abs); process.exit(1); }
  let data;
  try { data = JSON.parse(fs.readFileSync(abs, 'utf8')); }
  catch (e) { console.error('[ERROR] JSON 解析失败: ' + e.message); process.exit(1); }

  // 归一化
  let buckets = {};
  if (args.type) {
    if (!Array.isArray(data)) { console.error('[ERROR] --type 模式下文件应为数组'); process.exit(1); }
    buckets[args.type] = data;
  } else if (Array.isArray(data)) {
    console.error('[ERROR] 文件是数组，请加 --type <object>'); process.exit(1);
  } else {
    for (const [k, v] of Object.entries(data)) { if (k !== 'meta' && Array.isArray(v)) buckets[k] = v; }
  }

  const objects = mapping.objects || {};
  const warnings = [];

  // 生成 id + 名称索引
  const ids = {};       // obj -> [id]
  const index = {};     // obj -> { normName: id }
  for (const [obj, recs] of Object.entries(buckets)) {
    ids[obj] = [];
    index[obj] = index[obj] || {};
    const m = objects[obj];
    for (const r of recs) {
      const id = nextId();
      ids[obj].push(id);
      if (m && m.nameField && !isEmpty(r[m.nameField])) index[obj][norm(r[m.nameField])] = id;
    }
  }
  const lookup = (obj, name) => (index[obj] && index[obj][norm(name)]) || null;

  // 各对象 INSERT
  const now = Date.now();
  const insertStmts = []; // { obj, table, sql }
  const counts = {};
  const tableOrder = Object.keys(buckets);

  for (const obj of tableOrder) {
    const m = objects[obj];
    if (!m) { warnings.push(`对象「${obj}」不在 db-mapping.json，已跳过`); continue; }
    const privacy = new Set(m.privacy || []);
    const soft = m.softDelete || 'del_flag';
    const fkDefs = (mapping.foreignKeys || []).filter(f => f.object === obj);

    buckets[obj].forEach((rec, i) => {
      const cols = ['id'];
      const vals = [ids[obj][i]];
      const seen = new Set(['id', soft]);

      // 普通字段
      for (const [k, v] of Object.entries(rec)) {
        if (k.startsWith('_')) continue;
        const def = m.fields[k];
        if (!def) { warnings.push(`${obj}[#${i + 1}] 未知字段「${k}」已忽略`); continue; }
        if (privacy.has(k)) { warnings.push(`${obj}[#${i + 1}] 隐私字段「${k}」不落库`); continue; }
        if (isEmpty(v)) continue;
        let val = v;
        if (def.max && String(val).length > def.max) {
          warnings.push(`${obj}[#${i + 1}].${k} 超长(${String(val).length}>${def.max})` + (args.truncate ? ' 已截断' : ''));
          if (args.truncate) val = String(val).slice(0, def.max);
        }
        cols.push(k); vals.push(fmt(def.type, val)); seen.add(k);
      }

      // 默认值
      for (const [k, dv] of Object.entries(m.defaults || {})) {
        if (seen.has(k) || privacy.has(k)) continue;
        cols.push(k); vals.push(fmt(m.fields[k] ? m.fields[k].type : 'int', dv)); seen.add(k);
      }

      // 外键（parent_id / company_id / customer_id 等）
      for (const fk of fkDefs) {
        const rels = rec._relations || {};
        const val = toArray(rels[fk.rel])[0];
        if (isEmpty(val)) continue;
        if (seen.has(fk.field)) continue;
        const mid = lookup(fk.to, val);
        if (!mid) { warnings.push(`${obj}[#${i + 1}] 外键 ${fk.field} 未匹配到 ${fk.to}「${val}」`); continue; }
        cols.push(fk.field); vals.push(mid); seen.add(fk.field);
      }

      cols.push('create_time', 'update_time', soft);
      vals.push(String(now), String(now), '0');

      const sql = `INSERT INTO ${m.table} (${cols.join(', ')}) VALUES (${vals.join(', ')});`;
      insertStmts.push({ obj, table: m.table, sql });
      counts[m.table] = (counts[m.table] || 0) + 1;
    });
  }

  // 关联表
  const relStmts = [];
  const seenRel = new Set();
  for (const [, cfg] of Object.entries(mapping.relations || {})) {
    for (const pair of cfg.pairs || []) {
      const fromRecs = buckets[pair.from];
      if (!fromRecs) continue;
      fromRecs.forEach((rec, i) => {
        const list = toArray(rec._relations && rec._relations[pair.rel]);
        for (const name of list) {
          const matchId = lookup(pair.to, name);
          if (!matchId) { warnings.push(`关联未命中: ${pair.from}[#${i + 1}].${pair.rel} → ${pair.to}「${name}」`); continue; }
          const colVal = {};
          for (const [col, src] of Object.entries(pair.map)) colVal[col] = src === 'self' ? ids[pair.from][i] : matchId;
          for (const [k, v] of Object.entries(cfg.extra || {})) colVal[k] = v;
          const key = cfg.table + '|' + cfg.columns.map(c => colVal[c]).join('|');
          if (seenRel.has(key)) continue;
          seenRel.add(key);
          const cols = ['id', ...cfg.columns, 'create_time', 'update_time', 'del_flag'];
          const vals = [nextId(), ...cfg.columns.map(c => colVal[c]), String(now), String(now), '0'];
          relStmts.push(`INSERT INTO ${cfg.table} (${cols.join(', ')}) VALUES (${vals.join(', ')});`);
          counts[cfg.table] = (counts[cfg.table] || 0) + 1;
        }
      });
    }
  }

  // 输出
  const lines = [];
  lines.push('-- ============================================================');
  lines.push('-- biz-info-collector · 采集结果转 SQL');
  lines.push('-- 源文件: ' + path.basename(abs));
  lines.push('-- 生成时间: ' + new Date().toISOString());
  lines.push('-- 目标库: ' + (mapping.db || '(unknown)'));
  lines.push('-- 说明: id 由脚本生成(雪花)；create_time/update_time 为毫秒时间戳；关联表在主表之后');
  lines.push('-- ============================================================');
  lines.push('SET NAMES utf8mb4;');
  lines.push('');
  if (!args.noTx) lines.push('START TRANSACTION;');
  lines.push('');
  for (const s of insertStmts) {
    lines.push(`-- ${objects[s.obj] ? objects[s.obj].table : s.table}`);
    lines.push(s.sql);
  }
  if (relStmts.length) {
    lines.push('');
    lines.push('-- ---------- 关联关系 ----------');
    for (const s of relStmts) lines.push(s);
  }
  lines.push('');
  if (!args.noTx) lines.push('COMMIT;');
  const sqlText = lines.join('\n') + '\n';

  // 统计
  console.log('=== 采集结果转 SQL ===');
  console.log('源文件: ' + abs);
  console.log('记录统计:');
  for (const [t, c] of Object.entries(counts)) console.log(`  ${t}: ${c}`);
  console.log('总语句: ' + (insertStmts.length + relStmts.length));
  if (warnings.length) {
    console.log('');
    console.log(`--- WARNING (${warnings.length}) ---`);
    warnings.forEach(w => console.log('  ⚠ ' + w));
  }
  console.log('');

  if (args.dryRun) { console.log('--dry-run：未写文件'); return; }
  const outPath = args.out ? path.resolve(process.cwd(), args.out) : abs.replace(/\.json$/i, '') + '.sql';
  fs.writeFileSync(outPath, sqlText, 'utf8');
  console.log('已写出: ' + outPath);
}

main();

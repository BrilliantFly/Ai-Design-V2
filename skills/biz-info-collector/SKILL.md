---
name: biz-info-collector
description: 依据「喵百科」业务管理的数据结构，指导 AI 通过联网检索采集 行业 / 行业企业(平台) / 行业市场 / 行业产品 / 客户 / 客户企业 的资料，产出「字段与业务表对齐的结构化 JSON + 人读 Markdown 调研报告」，并可把结果转换为带关联关系的入库 SQL。当需要联网调研某个行业、盘点代表企业与市场、建立行业/企业/客户资料底稿、或把采集数据导入数据库时使用。触发词：行业调研、联网收集行业信息、收集企业信息、行业市场调研、客户信息采集、biz info collect、采集行业数据、生成入库SQL、采集结果入库。
---

# 业务信息联网采集（行业 · 企业 · 市场 · 客户）

把「业务管理」的数据结构当作**采集目标模板**，交给 AI **在网络上检索、抽取、填字段**，产出：

1. **结构化数据**（JSON，字段名与业务表列名一一对应，可后续导入）；
2. **调研报告**（Markdown，人读）。

> ⚠️ 本技能**不读取数据库**。数据库表结构只用于定义「采集哪些字段」。
> 所有数据由 AI 通过联网检索获得，**每条须带来源 URL**。

## 何时使用

- 要为某个行业建立资料底稿（定义、技术、产业链、格局、财务指标）。
- 要盘点某行业的代表企业 / 平台及其产品、市场表现。
- 要梳理某行业的市场与商业模式（需求、商机、九要素、竞争）。
- 要为一个客户（个人/企业）补齐背景资料（职业、企业、需求）。
- 在写设计文档 / 报告 / 原型前，需要先把行业背景作为上下文。

## 数据来源（本技能）

- **联网检索**：`websearch` 找来源 → `webfetch` 抓正文。
- **字段模板**：
  - 人读：`references/field-templates.md`（每个对象的字段清单 + 必填 + 采集提示）；
  - 机读：`templates/fields.json`（校验脚本与模板的**唯一数据源**）。
- **来源建议**：`references/sources.md`（各对象推荐来源与检索关键词模板）。
- **输出骨架**：`templates/collection.template.json`、`templates/report.md`。
- **入库映射**：`templates/db-mapping.json`（对象→表、字段类型/长度、软删列、外键与关联表；供 `scripts/to-sql.js` 使用）。

## 采集对象与业务表映射

| 对象 key | 业务表 | 说明 |
|----------|--------|------|
| `industry` | `biz_industry` | 行业主表（定义/技术/产业链/格局/财务） |
| `industry_product` | `biz_industry_product` | 行业产品 |
| `industry_enterprise` | `biz_industry_enterprise` | 行业企业/平台 |
| `industry_market` | `biz_industry_market` | 行业市场/商业模式九要素 |
| `customer` | `biz_customer` | 客户（个人/企业） |
| `customer_company` | `biz_customer_company` | 客户所属企业 |
| `customer_profile` | `biz_customer_profile` | 客户深度画像（分析性字段） |

> 关系（行业⇄产品/企业/市场、客户⇄行业）用记录里的 `_relations` 表达，见下方输出规范。

## 采集流程

```
📋 采集步骤：
1. 定对象与范围（行业/企业/市场/客户 + 地区/时间/关键词）      [ ]
2. 读字段模板（field-templates.md，确定字段与必填）             [ ]
3. 列检索计划（每字段组 → 关键词 → 目标来源）                  [ ]
4. 联网采集（websearch 定位 → webfetch 抽取原件）              [ ]
5. 逐字段填值 + 标来源（缺失留空、存疑标 _note）               [ ]
6. 汇总产出 JSON + Markdown 报告，落盘 collected/              [ ]
7. 运行校验脚本，修到通过                                     [ ]
8. （可选）生成入库 SQL：node scripts/to-sql.js <json>         [ ]
```

**Step 1 定对象与范围** — 明确要采的对象（可单个也可全量）与范围（行业名、企业名、地区、时间窗）。范围越小越准。

**Step 2 读字段模板** — 打开 `references/field-templates.md`，确认该对象的**必填字段**与**不采集字段**（隐私）。**不要采集模板之外的字段**。

**Step 3 列检索计划** — 按字段组拆解检索项，例如「市场规模」→ `"{行业} 市场规模 2025 报告"`；来源优先级见 `references/sources.md`。优先权威源（政府/协会/研报/企业官网/年报）。

**Step 4 联网采集** — 用 `websearch` 定位候选来源，用 `webfetch` 抓取原文；**只依据原文事实填值**，不要凭常识编造。

**Step 5 逐字段填值 + 标来源** — 每个非空字段都要能追溯到来源：
- 记录 `_sources`：该记录用到的 URL 列表；
- 关键结论可在 `_notes` 里标 `字段=短评（来源）`；
- 查不到 → 留空（不要写「未知/无数据」占位）；
- 多源冲突 → 取最权威/最新，并在 `_notes` 注明差异。

**Step 6 汇总产出** — 按 `templates/collection.template.json` 生成 JSON，按 `templates/report.md` 生成报告，写入 `collected/`（命名 `biz-info-<主题>-<日期>.{json,md}`）。

**Step 7 校验** — `node scripts/validate-output.js collected/<file>.json`，修到无 error。

**Step 8（可选）生成入库 SQL** — 需要把结果落库时，执行 `node scripts/to-sql.js collected/<file>.json`，会依据 `templates/db-mapping.json` 生成 `INSERT` 语句（自动生成 id、补系统字段、处理关联关系）。详见下方「导出为入库 SQL」。

## 输出规范

### 结构化 JSON

```json
{
  "meta": {
    "topic": "AI 行业调研",
    "scope": "中国 · 2024-2026",
    "collectedAt": "2026-10-10",
    "collector": "ai",
    "sourcesSummary": "政府/协会/研报/企业官网"
  },
  "industry": [
    {
      "industry_name": "人工智能",
      "definition": "……",
      "market_size": "2025 年约 3000 亿元（来源：IDC）",
      "_relations": { "products": ["大模型平台"], "enterprises": ["某公司"] },
      "_sources": ["https://..."],
      "_notes": { "market_size": "各家口径差异大，取 IDC" }
    }
  ],
  "industry_enterprise": [],
  "industry_market": [],
  "industry_product": [],
  "customer": [],
  "customer_company": [],
  "customer_profile": []
}
```

约定：
- 顶层 key 用**对象 key**（见映射表），值为记录数组；无数据用空数组。
- 字段名与业务表列名一致；标签见 `templates/fields.json`。
- `_relations` / `_sources` / `_notes` / `_confidence` 为元字段，不参与字段完整性校验。
- 查不到的字段**省略或留空字符串**，不要编造。

### Markdown 报告

按 `templates/report.md`：概览 → 各对象分节 → 每个字段值 + 来源 → 待核实清单。

## 质量与边界

- **必须可溯源**：任何非空字段都能对应到 `_sources` 中的来源；无来源即视为待核实。
- **只采公开信息**：不采集个人隐私（手机号、邮箱、家庭住址、家庭情况、婚姻状况等，见模板 `privacy`）；这类字段留空。
- **时效**：优先最近 1-2 年数据，注明数据年份。
- **不编造**：无法确认就留空并在报告中列入「待核实」。
- **区分事实与推断**：分析性字段（`customer_profile.*`、`*.strategy`、`*.value_info`）须标注「推断」，并说明依据。
- **合规**：遵守目标网站条款，只做只读检索与引用，标注出处。

## 校验脚本

```bash
# 校验采集结果（读取 templates/fields.json 作为字段规范）
node scripts/validate-output.js collected/biz-info-ai-2026-10-10.json

# 严格模式：把缺失来源也当作 error
node scripts/validate-output.js collected/xxx.json --strict

# 输入是单对象数组时，显式指定对象类型
node scripts/validate-output.js collected/industry.json --type industry
```

输出 error / warning 清单，exit code 非 0 表示存在 error。

## 导出为入库 SQL

需要把采集结果落库时，用 `scripts/to-sql.js` 生成可直接执行的 `INSERT` 语句（含关联关系）：

```bash
node scripts/to-sql.js collected/biz-info-ai-2026-10-10.json        # 输出同名 .sql
node scripts/to-sql.js collected/xxx.json --out out.sql
node scripts/to-sql.js collected/xxx.json --dry-run                # 只看统计，不写文件
node scripts/to-sql.js collected/xxx.json --truncate               # 超长字段按列长截断
node scripts/to-sql.js industry.json --type industry               # 输入是单对象数组
```

脚本依据 `templates/db-mapping.json` 完成：

- **字段→列**：对象 key 映射到业务表，字段名即列名；**隐私字段不落库**；未知字段忽略并告警。
- **主键**：`id` 为 bigint 非自增，脚本生成雪花 id。
- **系统字段**：自动补 `create_time`/`update_time`（毫秒）与软删列（`biz_customer`/`biz_customer_company` 用 `deleted`，其余用 `del_flag`）。
- **默认值**：行业 `visibility=1,sort=0`、企业 `is_listed=0`、客户 `customer_type=1,status=1`。
- **关联关系**（先主表后关联表，自动去重、未命中告警）：
  - 行业 ↔ 产品 / 企业 / 市场：`biz_industry_product_rel` / `biz_industry_enterprise_rel` / `biz_industry_market_rel`
  - 企业 ↔ 产品：`biz_enterprise_product_rel`
  - 客户 ↔ 行业：`biz_customer_industry`
  - 外键：行业 `parent_id`（父行业）、客户 `company_id`（客户企业）、画像 `customer_id`（客户）
- 输出包裹在 `START TRANSACTION; … COMMIT;` 中（`--no-transaction` 可关闭）。

> ⚠️ 关联按**名称**匹配（如产品用 `product_name`、行业用 `industry_name`）。因此 `_relations` 里的名称必须与目标记录的**名称字段完全一致**（空格无关），否则会出现在 WARNING「关联未命中」中。
> 建议先 `--dry-run` 看统计与告警，再用「事务 + ROLLBACK」在目标库做一次语法/约束验证，确认无误后再正式执行。

## 完成清单

- [ ] 对象与范围已明确
- [ ] 字段模板已核对（含隐私字段排除）
- [ ] 每个非空字段有来源；冲突已注明
- [ ] JSON 通过 `validate-output.js`（无 error）
- [ ] 报告已生成并列出「待核实」
- [ ] 产出落盘到 `collected/`
- [ ] （如需入库）`to-sql.js` 生成 SQL 且无「关联未命中」告警

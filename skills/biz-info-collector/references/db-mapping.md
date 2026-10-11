# 入库映射（采集 JSON → 业务表）

本文件说明 `scripts/to-sql.js` 如何把采集结果转换为 `INSERT` SQL。
**机读配置**：`templates/db-mapping.json`（脚本唯一数据源）；本文件为人工说明。

> 目标库：`know_boot_v1`。所有 `id` 为 `bigint` **非自增**，由脚本生成雪花 id。

## 1. 对象 → 表

| 对象 key | 业务表 | 名称字段 | 软删列 |
|----------|--------|----------|--------|
| `industry` | `biz_industry` | `industry_name` | `del_flag` |
| `industry_product` | `biz_industry_product` | `product_name` | `del_flag` |
| `industry_enterprise` | `biz_industry_enterprise` | `enterprise_name` | `del_flag` |
| `industry_market` | `biz_industry_market` | —（无名称字段） | `del_flag` |
| `customer` | `biz_customer` | `name` | `deleted` |
| `customer_company` | `biz_customer_company` | `name` | `deleted` |
| `customer_profile` | `biz_customer_profile` | —（靠 `customer_id`） | `del_flag` |

> 注意软删列名**不统一**：`biz_customer` / `biz_customer_company` 用 `deleted`，其余用 `del_flag`。

## 2. 系统字段（脚本自动补）

| 列 | 值 |
|----|----|
| `id` | 雪花 id（`bigint`，非自增，脚本生成） |
| `create_time` / `update_time` | 当前毫秒时间戳 |
| `del_flag` / `deleted` | `0` |

## 3. 默认值（脚本在字段缺失时补）

| 表 | 默认 |
|----|------|
| `biz_industry` | `visibility=1`、`sort=0` |
| `biz_industry_enterprise` | `is_listed=0` |
| `biz_customer` | `customer_type=1`、`status=1` |

## 4. 隐私字段（不落库）

`biz_customer`：`phone`、`email`、`family_situation`、`marital_status`。
脚本遇到这些字段会跳过并告警（正常应在校验阶段就被拦下）。

## 4.1 字段长度

`templates/db-mapping.json` 中每个字符串字段带 `max`（列长度）。超过时脚本 **WARNING**；加 `--truncate` 才按列长截断，否则交由数据库报错（更安全，避免静默丢字）。

## 5. 关联关系

脚本**先生成主表 INSERT，再生成关联表 INSERT**，并对关联行去重；匹配不到目标记 WARNING。

| 关联 | 关联表 | 键列 | 来源（`_relations`） |
|------|--------|------|----------------------|
| 行业 ↔ 产品 | `biz_industry_product_rel` | `industry_id`,`product_id` | `industry.products[]` / `industry_product.industry` |
| 行业 ↔ 企业 | `biz_industry_enterprise_rel` | `industry_id`,`enterprise_id` | `industry.enterprises[]` / `industry_enterprise.industries[]` |
| 行业 ↔ 市场 | `biz_industry_market_rel` | `industry_id`,`market_id` | `industry_market.industry` |
| 企业 ↔ 产品 | `biz_enterprise_product_rel` | `enterprise_id`,`product_id` | `industry_enterprise.products[]` |
| 客户 ↔ 行业 | `biz_customer_industry` | `customer_id`,`industry_id`,`relation_type`,`is_main` | `customer.industries[]`（`relation_type=1,is_main=0`） |

### 外键（写入主表列，非关联表）

| 对象 | 列 | 来源 `_relations` | 指向 |
|------|----|-------------------|------|
| `industry` | `parent_id` | `parent`（父行业名） | `industry.industry_name` |
| `customer` | `company_id` | `company`（企业名） | `customer_company.name` |
| `customer_profile` | `customer_id` | `customer`（客户名） | `customer.name` |

### 匹配规则

- 关联值可为**字符串或字符串数组**；按目标对象**名称字段**做匹配。
- 匹配前会去掉所有空白并转小写（`norm`），所以 `AI芯片(GPU)` 与 `AI 芯片(GPU)` 视为同名。
- **找不到目标**（或名称不完全一致）→ 记入 WARNING「关联未命中」，该条关联**不生成**。
- 关联表行同样补 `id` / `create_time` / `update_time` / `del_flag`。

## 4. 使用与验证

```bash
node scripts/to-sql.js collected/<file>.json            # 生成同名 .sql
node scripts/to-sql.js collected/<file>.json --dry-run  # 只看统计与告警
```

验证 SQL 是否可执行（不影响数据）：把生成文件里的 `COMMIT;` 换成 `ROLLBACK;` 后执行，或
`START TRANSACTION` 内试跑再回滚。当前样本（AI、新能源汽车）已用此法验证通过。

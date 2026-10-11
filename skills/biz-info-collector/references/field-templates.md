# 字段采集模板（对齐业务管理表）

> 这是 AI 的**采集目标清单**。字段名 = 业务表列名；中文字段名来自列注释。
> 机读版本见 `../templates/fields.json`（校验脚本以此为规范）。
> 规则：**必填** 必须给出；**不采集** 字段一律留空；其余字段尽力而为，查不到就留空。

图例：`★` 必填 ｜ `🔒` 不采集（隐私）｜ `△` 建议采集

---

## 1. `industry` — 行业（表 `biz_industry`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `industry_name` | 行业名称 | ★ | 标准行业名（尽量用官方/研报口径） |
| `definition` | 行业定义（边界说明） | ★ | 行业边界、包含与不包含什么 |
| `technology` | 核心技术 | △ | 行业所需关键技术/设计能力 |
| `industry_code` | 行业代码 | | 国标/统计口径代码（如 GB/T 4754） |
| `tags` | 标签 | | 关键词，逗号分隔 |
| `upstream_chain` | 上游产业链 | △ | 原材料/核心零部件/供应商 |
| `midstream_chain` | 中游产业链 | △ | 制造/集成/平台环节 |
| `downstream_channel` | 下游销售渠道 | △ | 面向客户的渠道 |
| `downstream_marketing` | 下游营销方式 | | 主要营销/获客方式 |
| `development_overview` | 行业发展概况 | △ | 发展阶段与格局综述 |
| `market_size` | 市场规模 | △ | **带单位与年份**，注明来源 |
| `growth_potential` | 增长潜力/增速 | △ | CAGR / 增速预测 |
| `dynamic_info` | 动态信息 | △ | 政策、社会文化、技术、市场变化 |
| `value_info` | 价值信息 | △ | 行业价值/机会评估 |
| `industry_resources` | 行业资源 | | 关键资源/资质/协会/人脉 |
| `strategy` | 如何把握 | | 布局策略/竞争打法（标注推断） |
| `gross_profit` | 毛利润 | | 典型值（注明口径） |
| `gross_margin` | 毛利率(%) | | 行业平均 |
| `net_profit` | 净利润 | | 行业平均 |
| `net_margin` | 净利率(%) | | 行业平均 |
| `visibility` | 可见性 | | 默认 `1`（公开） |
| `sort` | 排序 | | 默认 `0` |

`_relations`：`products[]`、`enterprises[]`、`markets[]`、`parent`（上级行业名）。

---

## 2. `industry_product` — 行业产品（表 `biz_industry_product`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `product_name` | 产品名称 | ★ | 代表性产品/产品品类 |
| `product_concept` | 产品概念（核心定义） | ★ | 一句话讲清是什么 |
| `category` | 产品分类 | | 归类 |
| `consumer_insight` | 消费者洞察 | △ | 谁买、为什么买、痛点 |
| `benefit_promise` | 利益承诺 | | 给客户的核心利益 |
| `support_point` | 支撑点 | | 承诺的依据（技术/服务） |
| `core_product` | 核心产品 | | 核心价值层 |
| `basic_product` | 基础产品 | | 基本效用层 |
| `additional_product` | 附加产品 | | 服务/售后/增值 |
| `potential_product` | 潜在产品 | | 未来延伸 |
| `life_cycle` | 产品生命周期 | | 导入/成长/成熟/衰退 |
| `upstream_chain` / `midstream_chain` | 上下游 | | 该产品的产业链位置 |
| `downstream_channel` / `downstream_marketing` | 渠道/营销 | | |
| `dynamic_info` / `value_info` / `strategy` | 动态/价值/如何把握 | | 分析性字段标推断 |

---

## 3. `industry_enterprise` — 行业企业/平台（表 `biz_industry_enterprise`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `enterprise_name` | 企业/平台名称 | ★ | 工商全称优先 |
| `enterprise_type` | 企业/平台类型 | △ | 生产商/经销商/平台/SaaS服务商（可多值，逗号分隔） |
| `established_date` | 成立时间 | △ | YYYY-MM-DD |
| `registered_capital` | 注册资本 | △ | 工商登记 |
| `paid_capital` | 实缴资本 | △ | 工商登记 |
| `scale` | 企业规模（人数） | △ | 大型/中型/小型 或人数区间 |
| `insured_count` | 参保人数 | | 工商/招聘平台 |
| `is_listed` | 是否上市 | | `0`/`1` |
| `main_business` | 主要业务 | △ | |
| `core_technology` | 核心技术 | △ | |
| `products` | 产品/服务 | △ | |
| `market_performance` | 市场表现 | △ | 营收/市占率（注明年份） |
| `competitors` | 主要竞争对手 | △ | |
| `advantage` / `disadvantage` | 优势/不足 | | |
| `upstream_chain` / `midstream_chain` / `downstream_channel` / `downstream_marketing` | 上下游 | | |
| `dynamic_info` / `value_info` / `industry_resources` / `strategy` | 动态/价值/资源/如何把握 | | 分析性字段标推断 |
| `address` | 企业地址 | | 公开注册地址 |
| `contact_name` | 联系人姓名 | | 仅公开的企业联系人 |
| `contact_phone` | 公开联系电话 | | **仅企业公开电话**，非个人手机 |
| `contact_position` | 联系人职务 | | |

`_relations`：`industries[]`、`products[]`。

---

## 4. `industry_market` — 行业市场/商业模式（表 `biz_industry_market`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `demand` | 市场需求 | ★ | 客群规模/痛点 |
| `value_proposition` | 价值主张 | ★ | 为客户创造什么价值 |
| `opportunity` | 商机 | △ | 可切入的机会点 |
| `customer_segment` | 客户细分 | △ | |
| `channel` | 渠道通路 | △ | |
| `customer_relation` | 客户关系 | | 如何建立/维护 |
| `revenue_source` | 收入来源 | △ | |
| `key_resource` | 关键资源 | △ | |
| `key_partner` | 关键伙伴 | △ | |
| `key_activity` | 关键活动 | △ | |
| `cost_structure` | 成本结构 | △ | |
| `value_evaluation` | 价值评价 | | |
| `value_distribution` | 价值分配 | | 产业链利润分配 |
| `competition_method` | 竞争手段 | | 行业/产品/企业三层 |
| `promo_channel` | 推广引流 | | 企业/产品两维度 |
| `dynamic_info` / `value_info` / `strategy` | 动态/价值/如何把握 | | 分析性字段标推断 |
| `gross_profit` / `gross_margin` / `net_profit` / `net_margin` | 财务 | | 注明口径与年份 |

> 九要素（`value_proposition`/`customer_segment`/`channel`/`customer_relation`/`revenue_source`/`key_resource`/`key_partner`/`key_activity`/`cost_structure`）来自商业模式画布。

---

## 5. `customer` — 客户（表 `biz_customer`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `name` | 客户姓名 | ★ | |
| `gender` | 性别 | 🔒? | `0/1/2`；公开人物可采，普通个人不采 |
| `age` | 年龄 | | 可采公开年龄区间 |
| `address` | 所在城市 | | **仅城市/公开层面**，不采详细住址 |
| `region_code` | 区域编码 | | 行政区划码 |
| `education` | 学历 | | 公开可查时 |
| `education_raw` | 教育背景详情 | | 学校/专业（公开） |
| `occupation` | 职业 | △ | |
| `position` | 职务/职位 | | |
| `personality` / `hobby` / `values_text` / `lifestyle` | 性格/兴趣/价值观/衣食住行 | | 仅公开信息，标推断 |
| `customer_type` | 客户类型 | | `1`个人 `2`企业 |
| `status` / `source` | 状态/来源 | | 多为内部字段，通常留空 |
| `demand_level` / `value_score` / `demand_willingness` / `demand_budget` / `demand_decision` / `demand_priority` / `demand_tags` / `demand_desc` | 需求类 | | 多为推断/内部信息 |
| `appearance` | 外貌 | | |
| `earning_way` | 赚钱方式 | | 多选，逗号分隔 |
| `social_class` | 社会阶层 | | 多选 |
| `social_circle` | 社交圈 | | |
| `basic_life_skill` / `vocational_skill` / `sports_skill` / `art_skill` / `tech_skill` | 技能 | | 公开可查时 |
| `phone` | 手机号 | 🔒 | **不采集** |
| `email` | 邮箱 | 🔒 | **不采集** |
| `marital_status` | 婚姻状况 | 🔒 | **不采集** |
| `family_situation` | 家庭情况 | 🔒 | **不采集** |

`_relations`：`industries[]`、`company`（所属企业名）。

> 普通个人客户的网上公开资料很有限，多数字段会留空——这属正常，不要编造。

---

## 6. `customer_company` — 客户所属企业（表 `biz_customer_company`）

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `name` | 企业名称 | ★ | 工商全称 |
| `industry` | 所属行业分类 | △ | |
| `scale` | 企业规模 | | 初创/小型/中型/大型/集团 |
| `business` | 主要业务 | △ | |
| `main_products` | 主要产品/服务 | △ | |
| `established_date` | 成立时间 | △ | |
| `capital` | 注册资本 | △ | |
| `address` | 地址 | | 公开注册地址 |
| `market_performance` | 市场表现 | | 营收概况/增长态势 |
| `competitive_advantage` | 竞争优势 | | 技术/渠道/品牌 |
| `contact_name` | 联系人姓名 | | 仅公开 |
| `contact_phone` | 公开联系电话 | | **仅企业公开电话** |
| `contact_position` | 联系人职务 | | |

---

## 7. `customer_profile` — 客户深度画像（表 `biz_customer_profile`）

> 分析性字段（非网上直接可查），须基于已采集事实**推断**并标注依据。

| 列名 | 中文字段 | | 采集提示 |
|------|----------|---|----------|
| `dynamic_info` | 动态信息 | | 人性观察/心理特征/制度影响 |
| `value_level` | 需求层次 | | 1生理…5自我实现 |
| `value_expect` | 客户期望 | | 对产品或服务的核心期待 |
| `value_interest` | 利益点 | | 利益诉求/关注维度 |
| `strategy` | 应对策略 | | 沟通定位/切入角度 |
| `talk_script` | 话术设计 | | 开场/痛点/方案/成交话术 |
| `analysis` | 分析 | | 综合判断/下一步动作 |

`_relations`：`customer`（关联客户名）。

# 04 - 数据流程与实例化逻辑（市场与行业调研子域）

> 所有落库表均为 `biz_` 前缀，归属 know-boot-biz 模块。本子域与 customer 子域同模块部署，进程内直接 Service 调用。

## 4.1 核心数据流

### 流程 1：行业调研录入（四维全景建模）

```
调研员                  前端                    后端 IndustryService              数据库
  │  选择行业→填定义      │                       │                              │
  │────────────────────>│                       │                              │
  │  填产业链三段        │  POST /biz/industry   │                              │
  │  填财务指标          │──────────────────────>│  ① INSERT biz_industry         │
  │                     │                       │─────────────────────────────>│
  │  填商业模式九要素    │                       │  ② INSERT biz_industry_market  │
  │                     │                       │─────────────────────────────>│
  │  维护产品清单        │                       │  ③ INSERT biz_industry_product │
  │                     │                       │     ×N                        │
  │────────────────────>│                       │─────────────────────────────>│
  │                     │                       │  ④ INSERT biz_industry_enterprise ×N
  │                     │<──────────────────────│                               │
  │  行业全景详情展示    │                       │                              │
  │<────────────────────│                       │                               │
```

### 流程 2：行业选择拥有的客户（多对多反查/写入）

```
  │ 行业详情-客户分布Tab │                       │                              │
  │  [关联客户] 勾选     │                       │                              │
  │────────────────────>│  GET /{id}/customers  │                              │
  │                     │──────────────────────>│  ① 查 biz_customer_industry   │
  │                     │                       │─────────────────────────────>│
  │                     │<──────────────────────│  ② 经 customerId 查客户摘要    │
  │                     │  POST setCustomerIndustries (customer 子域)           │
  │                     │──────────────────────>│  ③ 全量覆盖写入中间表          │
  │                     │<──────────────────────│                               │
  │  客户列表刷新        │                       │                              │
  │<────────────────────│                       │                               │
```

### 流程 3：客户侧联动（反向视角）

```
customer 子域 客户详情 → 行业标签 [互联网][人工智能]
  └─ 数据来自共享中间表 biz_customer_industry JOIN biz_industry
       └─ 行业名/主营标记展示
```

## 4.2 调研表 → 数据库字段映射（《市场与行业调研.xlsx》）

| 调研表 Sheet | 分组 | 落地表/字段 |
|-------------|------|------------|
| Sheet1 行业（产品与企业） | 定义/技术 | biz_industry.definition / technology |
| Sheet1 | 产品（分类/产品/消费者洞察/细分/潜在/附加） | biz_industry_product（细分类产品） |
| Sheet1 | 上下游产业链（上游/中游/下游渠道+营销） | biz_industry.upstream_chain / midstream_chain / downstream_channel / downstream_marketing |
| Sheet1 | 企业/平台（类型/企业/产品/特征） | biz_industry_enterprise |
| Sheet1 | 动态信息 | biz_industry.dynamic_info |
| Sheet1 | 价值信息 | biz_industry.value_info |
| Sheet1 | 行业资源 | biz_industry.industry_resources |
| Sheet1 | 如何把握（布局/兵法） | biz_industry.strategy |
| Sheet1 | 其他（毛利/毛利率/净利/净利率） | biz_industry.gross_* / net_* |
| Sheet2 行业（产品） | 产品概念/消费者洞察/利益承诺/支撑点 | biz_industry_product.product_concept / consumer_insight / benefit_promise / support_point |
| Sheet2 | 产品细分（核心/基础/附加/潜在） | biz_industry_product.core_product / basic_product / additional_product / potential_product |
| Sheet2 | 产品生命周期 | biz_industry_product.life_cycle |
| Sheet2 | 产业链 | biz_industry_product.upstream_chain / ... |
| Sheet3 行业（企业） | 工商信息（成立/注册资本/实缴/规模/参保/上市） | biz_industry_enterprise.* |
| Sheet3 | 主要业务/核心技术/产品/市场表现 | biz_industry_enterprise.main_business / core_technology / products / market_performance |
| Sheet3 | 竞争（对手/优势/不足） | biz_industry_enterprise.competitors / advantage / disadvantage |
| Sheet4 行业与市场 | 需求/商机 | biz_industry_market.demand / opportunity |
| Sheet4 | 商业模式九要素（价值创造/评价/分配） | biz_industry_market.value_* / customer_* / channel / revenue_source / key_* / cost_structure / value_evaluation / value_distribution |
| Sheet4 | 营销（竞争手段/推广引流） | biz_industry_market.competition_method / promo_channel |

## 4.3 数据一致性保证

| 场景 | 处理方式 |
|------|---------|
| 行业删除后客户关联 | 行业逻辑删除；客户侧展示 JOIN 不到自动隐藏，中间表保留（可恢复） |
| 行业删除后子资源 | Service.delete 递归软删 product/enterprise/market（del_flag=1） |
| 行业市场信息重复 | `uk_market_industry(industry_id)` 唯一索引 + Service 层 upsert（存在则更新） |
| 客户分布反查时客户已删 | JOIN 条件 `c.deleted = 0` 过滤 |
| 同行业多客户/同客户多行业 | 中间表唯一索引 `uk_customer_industry(customer_id, industry_id)` 防重 |
| 商业模式数据完整 | PUT 整包保存（九要素整体提交），避免部分字段为空歧义 |
| 跨子域删除依赖 | 行业删除不物理删 biz_customer_industry，由 customer 侧 del_flag 处理 |

## 4.4 与 customer 子域的联动闭环（同模块内）

```
市场与行业调研子域                        客户信息调用子域
┌──────────────────┐                  ┌──────────────────┐
│ 行业列表(客户数角标)│ ◄── customerIds ─│ 客户列表(行业筛选)  │
│ 行业详情(客户分布) │ ◄── 反查        ─│ 客户详情(行业标签)  │
│ 行业统计          │ ◄── COUNT       ─│ 客户统计(行业分布)  │
└──────────────────┘                  └──────────────────┘
         │             biz_customer_industry               ▲
         └───────────────── 双向读写 ─────────────────────┘
```

> 单例模式 / 微服务模式下均部署在同一个 know-boot-biz 进程内，子域间通过 Spring Bean 直接互调，无网络开销；未来若拆分独立部署，可替换为 Feign（接口签名已对齐）。

## 4.5 统计查询（远程库 know_boot_v1）

```sql
-- 行业客户分布（跨子域反查计数）
SELECT ci.industry_id, i.industry_name, COUNT(DISTINCT ci.customer_id) AS customer_cnt
FROM biz_customer_industry ci
JOIN biz_industry i ON i.id = ci.industry_id AND i.del_flag = 0
JOIN biz_customer c ON c.id = ci.customer_id AND c.deleted = 0
WHERE ci.del_flag = 0
GROUP BY ci.industry_id, i.industry_name;

-- 行业维度统计（产品/企业数）
SELECT i.id, i.industry_name,
       COUNT(DISTINCT p.id) AS product_cnt,
       COUNT(DISTINCT e.id) AS enterprise_cnt
FROM biz_industry i
LEFT JOIN biz_industry_product p ON p.industry_id = i.id AND p.del_flag = 0
LEFT JOIN biz_industry_enterprise e ON e.industry_id = i.id AND e.del_flag = 0
WHERE i.del_flag = 0
GROUP BY i.id, i.industry_name;
```

## 4.6 未来扩展点

| 扩展方向 | V2 方案 |
|---------|---------|
| 行业趋势数据 | 接入行业指数/新闻/政策 API，biz_industry.dynamic_info 自动更新 |
| 竞争情报 | 企业竞对自动监控（工商变更/融资事件） |
| 产业链图谱 | 独立图谱表（node/edge）+ 可视化 |
| 行业标杆对比 | 预置行业财务基准，与录入指标对比打分 |
| 商机对接 | 商机表关联 biz_industry_market.opportunity，推送到客户转化流程 |
# 04 - 数据流程与实例化逻辑（客户信息调用子域）

> 所有落库表均为 `biz_` 前缀，归属 know-boot-biz 模块。本子域与 industry 子域同模块部署，进程内直接 Service 调用。

## 4.1 核心数据流

### 流程 1：客户建档并关联行业（完整闭环）

```
业务员                  前端                    后端 CustomerService            数据库
  │  录入客户资料        │                       │                              │
  │────────────────────>│                       │                              │
  │  勾选行业(多选)      │  POST /biz/customer   │                              │
  │────────────────────>│──────────────────────>│  ① INSERT biz_customer        │
  │                     │                       │     (AES加密 phone/email)     │
  │                     │                       │─────────────────────────────>│
  │                     │                       │  ② INSERT biz_customer_company│
  │                     │                       │     (若 customerType=2)       │
  │                     │                       │─────────────────────────────>│
  │                     │                       │  ③ INSERT biz_customer_profile│
  │                     │                       │─────────────────────────────>│
  │                     │                       │  ④ INSERT biz_customer_industry│
  │                     │                       │     ×N (多行业)               │
  │                     │                       │─────────────────────────────>│
  │                     │<──────────────────────│                               │
  │  详情页看到完整画像  │                       │                              │
  │<────────────────────│                       │                              │
```

### 流程 2：修改客户关联行业（全量覆盖）

```
  │ 编辑行业           │  POST /{id}/industries │                               │
  │───────────────────>│──────────────────────>│  ① 校验 industryIds 存在于    │
  │                    │                       │     biz_industry (同模块)      │
  │                    │                       │  ② UPDATE 旧关联 del_flag=1   │
  │                    │                       │─────────────────────────────>│
  │                    │                       │  ③ INSERT 新关联 ×N           │
  │                    │                       │─────────────────────────────>│
  │                    │                       │  ④ 校验 is_main 唯一          │
  │                    │<──────────────────────│                               │
```

### 流程 3：行业侧反查客户（同模块跨子域数据流）

```
行业子域(市场与行业调研)
  └─ 行业详情页 → GET /api/biz/industry/{id}/customers
       └─ 调用 IndustryService.getCustomersByIndustry(industryId)
            └─ SELECT c.* FROM biz_customer c
               JOIN biz_customer_industry ci ON ci.customer_id = c.id
               WHERE ci.industry_id = ? AND ci.del_flag = 0 AND c.deleted = 0
```

## 4.2 客户画像分层模型

调研表《客户信息调研.xlsx》的纵向分层 → 数据库映射：

| 调研表层次 | 字段 | 落地表 |
|-----------|------|--------|
| 基础信息-个人情况 | 姓名/性别/年龄/手机/邮箱/地址/教育/性格/兴趣/价值观/衣食住行 | biz_customer |
| 基础信息-关系/家庭情况 | 婚姻/家庭构成 | biz_customer.marital_status / family_situation |
| 基础信息-企业情况 | 企业名称/行业/规模/主营/产品/市场表现/竞争优势 | biz_customer_company |
| 基础信息-行业情况 | 行业整体分析 / 行业竞争分析 | biz_industry（industry 子域） |
| 动态信息 | 人性/心理学/读心术；制度影响 | biz_customer_profile.dynamic_info |
| 价值信息 | 马斯洛需求/期望/利益 | biz_customer_profile.value_* |
| 如何把握 | 应对策略/话术设计/分析 | biz_customer_profile.strategy / talk_script / analysis |

> 客户 ⇄ 行业的多对多关联是贯穿两个子域的**主数据链路**：
> 客户凭证 `industry_ids` 筛选客户池；行业凭证 `customer_ids` 指导市场投放。

## 4.3 数据一致性保证

| 场景 | 处理方式 |
|------|---------|
| 客户删除后，行业反查 | 客户逻辑删除（deleted=1），JOIN 条件过滤，反查自动排除 |
| 客户删除后，关联表残留 | 删除时同步软删 `biz_customer_industry`；反查侧过滤 del_flag |
| 行业删除后，客户关联失效 | 行业逻辑删除后，客户侧展示时 JOIN 不到的行业自动隐藏，但关联行保留（便于恢复） |
| is_main 唯一性 | 写入时应用层校验：同一 customer_id 只允许一条 is_main=1 |
| 并发重复关联 | `uk_customer_industry (customer_id, industry_id)` 唯一索引兜底 |
| phone/email 加密 | 统一 AES 工具类；查询脱敏在 Service 层返回 DTO 时处理 |
| 跨子域行业校验 | setIndustries 时校验所有 industry_id 存在于 `biz_industry` 且 del_flag=0 |

## 4.4 与行业子域的联动闭环（同模块内）

```
客户信息调用子域                         市场与行业调研子域
┌──────────────────┐                  ┌──────────────────┐
│ 客户列表(行业筛选) │ ◄──── industryId ─│ 行业(客户分布)     │
│ 客户详情(行业标签) │ ◄──── 行业名称   ─│ 行业详情          │
│ 客户统计(行业分布) │ ◄──── 行业列表   ─│ 行业主数据        │
└──────────────────┘                  └──────────────────┘
         │             biz_customer_industry               ▲
         └───────────────── 多对多双向查询 ────────────────┘
```

> 单例模式 / 微服务模式下均部署在同一个 know-boot-biz 进程内，子域间通过 Spring Bean 直接互调，无网络开销；未来若拆分独立部署，可替换为 Feign（接口签名已对齐）。

## 4.5 定时任务（可选 V2）

| 任务 | 逻辑 |
|------|------|
| 提醒跟进 | 每日扫描 `biz_customer_followup.next_time` 为当天的记录 → 推送待办 |

## 4.6 统计查询（远程库 know_boot_v1）

```sql
-- 行业分布（联动行业表）
SELECT ci.industry_id, i.industry_name, COUNT(*) AS cnt
FROM biz_customer_industry ci
JOIN biz_industry i ON i.id = ci.industry_id AND i.del_flag = 0
WHERE ci.del_flag = 0
GROUP BY ci.industry_id, i.industry_name;

-- 状态分布
SELECT status, COUNT(*) AS cnt
FROM biz_customer WHERE deleted = 0 GROUP BY status;
```

## 4.7 未来扩展点

| 扩展方向 | V2 方案 |
|---------|---------|
| 客户标签体系 | 独立 `biz_customer_tag` / 标签组管理 |
| 客户分组（公海/私海） | biz_customer 增加 `pool_type` + 分配记录表 |
| 商机管道 | 基于 status 扩展为商机金额/阶段/赢率 |
| 行业动态订阅 | 行业子域提供行业新闻/制度变化推送，客户侧订阅 |
| 客户 360 视图集成 | 汇总跟进/订单/工单为统一时间线 |
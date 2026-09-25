# 03 - 前端页面与组件设计（市场与行业调研子域）

> 前端请求路径统一以 `/biz` 为模块前缀：单例模式下由 nginx 反代到聚合服务；微服务模式下由网关 `Path=/biz/**` 路由到 `lb://biz`。

## 3.1 新增 API 文件

### `src/api/biz/industry/index.ts`

```typescript
import request from '@/utils/request'

export function getIndustryList(params) {
  return request.get({ url: '/biz/industry/page', data: params })
}

export function getAllIndustries(params) {
  return request.get({ url: '/biz/industry/list', data: params })
}

export function getIndustryDetail(id) {
  return request.get({ url: `/biz/industry/${id}` })
}

export function createIndustry(data) {
  return request.post({ url: '/biz/industry', data })
}

export function updateIndustry(data) {
  return request.put({ url: '/biz/industry', data })
}

export function deleteIndustry(id) {
  return request.delete({ url: `/biz/industry/${id}` })
}

export function getIndustryCustomers(id, params) {
  return request.get({ url: `/biz/industry/${id}/customers`, data: params })
}

export function getIndustryStatistics() {
  return request.get({ url: '/biz/industry/statistics' })
}
```

### `src/api/biz/industry/product.ts` / `enterprise.ts` / `market.ts`（同构，略）

> 注意：同模块共享数据源 —— 行业多选时 customer 子域复用 `getAllIndustries()` 下拉。

## 3.2 页面路由

```
pages/industry/
├── index.vue            # 行业列表（卡片/表格 + 新建入口）
├── detail.vue           # 行业全景详情（四 Tab：全景 / 产品 / 企业 / 客户分布）
└── components/
    ├── ChainView.vue        # 产业链三段视图（上游/中游/下游：渠道+营销）
    ├── BusinessModelView.vue# 商业模式九要素九宫格
    ├── ProductTable.vue     # 产品管理（细分/生命周期）
    ├── EnterpriseTable.vue  # 企业管理（工商/竞争）
    └── CustomerPanel.vue    # 客户分布面板（跨子域反查）
```

## 3.3 行业列表页 index.vue

### 页面结构

```
┌────────────────────────────────────────────────────────────┐
│ 行业调研              [新建行业]  [统计]                       │
├────────────────────────────────────────────────────────────┤
│ 筛选: [名称/编码关键字] [标签]             [查询][重置]          │
├────────────────────────────────────────────────────────────┤
│ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│ │ 互联网/IT   │ │ 人工智能    │ │ 金融       │ │ 制造业      │ │
│ │ 市场规模    │ │ 市场规模    │ │ 市场规模    │ │ 市场规模    │ │
│ │ 5000亿     │ │ 3000亿     │ │ ...        │ │ ...        │ │
│ │ 产品 12     │ │ 产品 8     │ │ ...        │ │ ...        │ │
│ │ 企业 20     │ │ 企业 15    │ │ ...        │ │ ...        │ │
│ │ 客户 8      │ │ 客户 5     │ │ ...        │ │ ...        │ │
│ └────────────┘ └────────────┘ └────────────┘ └────────────┘ │
└────────────────────────────────────────────────────────────┘
```

> 卡片展示行业摘要 + 统计角标（产品/企业/客户数，客户数来自跨子域反查）。

## 3.4 行业详情页 detail.vue（四 Tab）

```
┌────────────────────────────────────────────────────────────┐
│ 互联网/IT  [制造业]                  [编辑]  [删除]            │
│ 定义: 以信息技术为核心的软件...                               │
├─────────┬──────────┬──────────┬──────────┐                  │
│ [全景]   │ [产品]   │ [企业]   │ [客户分布] │                  │
├─────────┴──────────┴──────────┴──────────┤                  │
│ Tab1 全景                                 │                  │
│  ┌─────────────┐  ┌────────────────────┐  │                  │
│  │ 产业链三段    │  │ 财务指标            │  │                  │
│  │ 上游:芯片     │  │ 毛利率 60%          │  │                  │
│  │ 中游:集成商   │  │ 净利率 20%          │  │                  │
│  │ 下游:直销/云  │  └────────────────────┘  │                  │
│  └─────────────┘  ┌────────────────────┐  │                  │
│  ┌─────────────┐  │ 商业模式九宫格       │  │                  │
│  │ 动态/价值/    │  │ 价值主张/客户细分/... │  │                  │
│  │ 资源/战略    │  └────────────────────┘  │                  │
│  └─────────────┘                          │                  │
└────────────────────────────────────────────┘                  │
```

### 客户分布 Tab（多对多核心交互）

```
┌────────────────────────────────────────────────────────────┐
│ 行业拥有的客户 (8)                [关联客户▾]                  │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ 客户名称    客户类型   状态    关系类型     备注        │   │
│ │ 张三        个人       意向    主营行业     主营       │   │
│ │ 王五        企业       成交    关联行业     -          │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                              │
│ [关联客户] 弹窗 → 调 customer 子域列表 → 勾选多个 → POST 客户侧  │
│   setCustomerIndustries(customerId, { industryIds, ... })    │
│   (写入共享的 biz_customer_industry)                          │
└────────────────────────────────────────────────────────────┘
```

关联交互双入口：
1. 行业详情 → 客户分布 Tab → [关联客户] 勾选
2. 客户详情 → 行业标签 → [编辑行业] 勾选（同一张中间表，双向同步）

## 3.5 BusinessModelView 商业模式九宫格

```
┌─────────────────┬─────────────────┬─────────────────┐
│ 关键伙伴          │ 关键活动          │ 价值主张          │
│ keyPartner      │ keyActivity     │ valueProposition│
├─────────────────┼─────────────────┼─────────────────┤
│ 关键资源          │                  │ 客户关系          │
│ keyResource     │     商业模式     │ customerRelation │
├─────────────────┼─────────────────┼─────────────────┤
│ 渠道通路          │ 客户细分          │ 收入来源          │
│ channel         │ customerSegment │ revenueSource   │
└─────────────────┴─────────────────┴─────────────────┘
 底部: 成本结构 costStructure
```

## 3.6 统计页（可选）

- 行业-客户分布横向柱状图（ECharts）
- 点击柱子 → 跳转对应行业客户分布 Tab
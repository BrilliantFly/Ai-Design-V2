# 03 - 前端页面与组件设计（客户信息调用子域）

> 前端请求路径统一以 `/biz` 为模块前缀：单例模式下由 nginx 反代到聚合服务；微服务模式下由网关 `Path=/biz/**` 路由到 `lb://biz`。

## 3.1 新增 API 文件

### `src/api/biz/customer/index.ts`

```typescript
import request from '@/utils/request'

export function getCustomerList(params) {
  return request.get({ url: '/biz/customer/page', data: params })
}

export function getCustomerDetail(id) {
  return request.get({ url: `/biz/customer/${id}` })
}

export function createCustomer(data) {
  return request.post({ url: '/biz/customer', data })
}

export function updateCustomer(data) {
  return request.put({ url: '/biz/customer', data })
}

export function deleteCustomer(id) {
  return request.delete({ url: `/biz/customer/${id}` })
}

export function updateCustomerStatus(id, status) {
  return request.put({ url: `/biz/customer/${id}/status`, data: { status } })
}

export function setCustomerIndustries(id, data) {
  return request.post({ url: `/biz/customer/${id}/industries`, data })
}

export function getCustomerStatistics() {
  return request.get({ url: '/biz/customer/statistics' })
}
```

### `src/api/biz/customer/company.ts` / `followup.ts`（同构，略）

## 3.2 页面路由

```
pages/customer/
├── index.vue            # 客户列表（筛选 + 表格 + 新建/编辑入口）
├── detail.vue           # 客户详情（基础信息 + 画像 + 行业标签 + 跟进时间线）
└── components/
    ├── IndustrySelect.vue   # 行业多选组件（供客户/行业两个子域复用）
    ├── ProfileForm.vue      # 深度画像编辑（动态/价值/策略三 Tab）
    └── FollowupTimeline.vue # 跟进记录时间线
```

## 3.3 客户列表页 index.vue

### 页面结构

```
┌────────────────────────────────────────────────────────────┐
│ 客户管理                    [新建客户]  [统计报表]             │
├────────────────────────────────────────────────────────────┤
│ 筛选: [姓名] [状态▾] [客户类型▾] [行业▾·多选] [区域▾] [查询][重置]│
├────────────────────────────────────────────────────────────┤
│ ☐ 姓名    手机号    行业标签        状态    来源    操作         │
│ ☐ 张三    138****  互联网/人工智能  意向    线上推广  编辑/详情  │
│ ☐ 李四    139****  金融            潜在    转介绍    编辑/详情  │
├────────────────────────────────────────────────────────────┤
│ 共 22 条                   < 上一页 下一页 >                  │
└────────────────────────────────────────────────────────────┘
```

### 行业标签渲染

- 列表行内显示客户关联的行业 Tag（最多 3 个，超出显示 `+N`）
- 行业选项来自同模块行业子域 `GET /api/biz/industry/list`（module 内共享数据源）

### 数据流

```
index.vue
  ├─ getCustomerList(params) → 表格 records + industries 展平
  ├─ 选择行业筛选 → params.industryId → 后端 JOIN 过滤
  └─ 点击新建 → 跳 detail.vue?mode=create
```

## 3.4 客户详情页 detail.vue

### 页面结构

```
┌────────────────────────────────────────────────────────────┐
│ 张三   [意向] 来源:线上推广        [编辑]  [关联行业▾]         │
│  ┌───────────────┬─────────────────────────────────────┐  │
│  │ 基础信息        │ 行业标签: [互联网][人工智能]+移除        │  │
│  │ 姓名/性别/年龄  │ 主营行业: 互联网                        │  │
│  │ 手机/邮箱/地址  │ ───────────────────────────────────  │  │
│  │ 教育/职业/职务  │ 所属企业: ABC科技 (查看)               │  │
│  │ 需求层级 ★★★★  │ ───────────────────────────────────  │  │
│  │ 价值评分 ★★★★  │ 需求描述: 企业级 SaaS 落地              │  │
│  └───────────────┴─────────────────────────────────────┘  │
│  Tab: [基础] [深度画像] [跟进记录]                            │
│   深度画像: 动态信息 │ 价值信息(马斯洛) │ 应对策略              │
│   跟进记录: 时间线 + [新增跟进]                               │
└────────────────────────────────────────────────────────────┘
```

### 关联行业交互

```
[编辑行业] 弹窗 → IndustrySelect（多选 + 每项选关系类型/是否主营）
  → setCustomerIndustries(id, { industryIds, relations })
  → 刷新行业标签 + 主营标记
```

## 3.5 IndustrySelect 组件（同模块子域复用）

- 数据源：`GET /api/biz/industry/list`（行业子域）
- 能力：多选、搜索过滤、标记"主营行业"（至多一个）、每项可选关系类型
- 输出：`{ industryIds: number[], relations: [{industryId, relationType, isMain, remark}] }`

## 3.6 客户画像编辑 ProfileForm

```
Tab1 动态信息   [人性观察] [心理学特征] [制度影响]      → dynamicInfo
Tab2 价值信息   需求层次(1-5 滑动) / 期望 / 利益点      → valueLevel/valueExpect/valueInterest
Tab3 如何把握   应对策略 / 话术设计(多行) / 综合分析     → strategy/talkScript/analysis
```

## 3.7 统计报表（可选）

- 状态漏斗：潜在→意向→成交→流失（ECharts 漏斗图）
- 行业分布：客户-Pie 图（数据来自 `/biz/customer/statistics`）
- 点击饼图扇区 → 跳转客户列表并带 industryId 筛选（双向联动闭环）
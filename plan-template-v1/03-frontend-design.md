# 03 - 前端页面与组件设计

## 3.1 新增 API 文件

### `src/api/plan/template.ts`

```typescript
import request from '@/utils/request'

export function getTemplateList(params) {
  return request.get({ url: '/plan/template/list', data: params })
}

export function getHotTemplates(params) {
  return request.get({ url: '/plan/template/hot', data: params })
}

export function getTemplateDetail(id) {
  return request.get({ url: `/plan/template/${id}` })
}

export function createTemplate(data) {
  return request.post({ url: '/plan/template', data })
}

export function updateTemplate(data) {
  return request.put({ url: '/plan/template', data })
}

export function deleteTemplate(id) {
  return request.delete({ url: `/plan/template/${id}` })
}

export function useTemplate(id, data) {
  return request.post({ url: `/plan/template/${id}/use`, data })
}

export function generateTemplateFromPlan(planId, data) {
  return request.post({ url: `/plan/template/from-plan/${planId}`, data })
}
```

### `src/api/plan/info.ts`（新增）

```typescript
import request from '@/utils/request'

export function getPlanList(params) {
  return request.get({ url: '/plan/info/list', data: params })
}

export function getPlanDetail(id) {
  return request.get({ url: `/plan/info/${id}` })
}

export function createPlan(data) {
  return request.post({ url: '/plan/info', data })
}

export function updatePlanStatus(id, status) {
  return request.put({ url: `/plan/info/${id}/status`, data: { status } })
}

export function updatePlanProgress(id, progress) {
  return request.put({ url: `/plan/info/${id}/progress`, data: { progress } })
}
```

---

## 3.2 新增/修改页面

### 页面路由表（pages.json 新增）

```json
{
  "path": "pages/plan/template/index",
  "style": { "navigationBarTitleText": "计划模板" }
},
{
  "path": "pages/plan/template/detail",
  "style": { "navigationBarTitleText": "模板详情" }
},
{
  "path": "pages/plan/template/use",
  "style": { "navigationBarTitleText": "使用模板" }
}
```

---

## 3.3 模板列表页 `template/index.vue`

### 页面结构

```
┌─────────────────────────────────────────────┐
│ 📋 计划模板                          [+ 新建]│
├─────────────────────────────────────────────┤
│ 🔍 搜索模板...                               │
├─────────────────────────────────────────────┤
│ [全部] [健身] [读书] [工作] [自定义]          │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ 💪 健身计划              ⭐ 4.8  已用 236│ │
│ │ 30天健身养成，含跑步、力量、拉伸         │ │
│ │ 🏃🏃🏋️🧘          [使用模板] [预览]     │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ 📚 读书计划              ⭐ 4.6  已用 189│ │
│ │ 30天阅读养成，每天30页+阅读笔记         │ │
│ │ 📖📝                  [使用模板] [预览]  │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ 🚀 项目冲刺              ⭐ 4.9  已用 312│ │
│ │ 2周冲刺，含站会+复盘+子任务              │ │
│ │ 🗣️📋                  [使用模板] [预览]  │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ─── 我的模板 ──────────────────────────────  │
│ ┌─────────────────────────────────────────┐ │
│ │ ⚙️ 自定义模板1             [使用] [编辑] │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 数据流

```
onMounted
  → getTemplateList({ visibility: [1,2], planType: filter, parentId: null }) // 顶级模板
  → getTemplateList({ visibility: 0, parentId: null }) // 我的模板
  → 分类展示
  → 点击展开 → getChildren(templateId) 加载子模板
```

---

## 3.4 模板详情页 `template/detail.vue`

### 页面结构

```
┌─────────────────────────────────────────────┐
│ ← 模板详情                                  │
├─────────────────────────────────────────────┤
│  🚀 项目冲刺                                │
│  2 周冲刺计划，含 3 个阶段子计划             │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ 📊 预览统计                          │   │
│  │ 根级习惯: 2 个  |  根级日程: 2 个     │   │
│  │ 子计划层级: 3 层  |  子计划总数: 10  │   │
│  │ 子模板数: 3       |  计划天数: 14 天  │   │
│  │ 优先级: ⭐⭐⭐⭐⭐                      │   │
│  │ 已有 312 人使用   |  评分: ⭐ 4.9     │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ─── 模板层级（WBS）──────────────────────  │
│  ┌──────────────────────────────────────┐   │
│  │ 🚀 项目冲刺（顶级模板）              │   │
│  │ │                                    │   │
│  │ ├─ 📁 阶段一：需求确认模板           │   │
│  │ │   ├─ 📋 功能清单确认子模板         │   │
│  │ │   └─ 📋 技术方案设计子模板         │   │
│  │ │                                    │   │
│  │ ├─ 📁 阶段二：核心开发模板           │   │
│  │ │   ├─ 📋 前端开发子模板             │   │
│  │ │   ├─ 📋 后端开发子模板             │   │
│  │ │   └─ 📋 接口联调子模板             │   │
│  │ │                                    │   │
│  │ └─ 📁 阶段三：测试上线模板           │   │
│  │     ├─ 📋 Bug 修复子模板             │   │
│  │     └─ 📋 部署发布子模板             │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ─── 根级习惯 ────────────────────────────  │
│  ┌──────────────────────────────────────┐   │
│  │ 🗣️ 每日站会   每天 09:00  14天       │   │
│  │ 📋 当日复盘   每天 18:00  14天       │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ─── 根级日程 ────────────────────────────  │
│  ┌──────────────────────────────────────┐   │
│  │ 📋 冲刺启动会  重要紧急  ⭐⭐⭐       │   │
│  │ 📋 交付评审    重要紧急  ⭐⭐⭐       │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │          [ 🚀 使用此模板 ]            │   │
│  │          [ ➕ 添加子模板 ]             │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 3.5 使用模板页 `template/use.vue`

### 页面结构（创建计划确认页）

```
┌─────────────────────────────────────────────┐
│ ← 使用模板                                  │
├─────────────────────────────────────────────┤
│  🚀 项目冲刺                                │
│                                             │
│  ─── 计划配置 ────────────────────────────  │
│  计划名称: [ 我的项目冲刺           ]       │
│  开始日期: [ 2026-08-20           ] 📅     │
│  计划天数: [ 14 ] 天                        │
│                                             │
│  ─── 模板树（3 层 / 8 个子模板）──────────  │
│  ┌──────────────────────────────────────┐   │
│  │ ☑ 🚀 项目冲刺（顶级）               │   │
│  │   ☑ 📁 阶段一：需求确认             │   │
│  │     ☑ 📋 功能清单确认               │   │
│  │     ☑ 📋 技术方案设计               │   │
│  │   ☑ 📁 阶段二：核心开发             │   │
│  │     ☑ 📋 前端开发                   │   │
│  │     ☑ 📋 后端开发                   │   │
│  │     ☐ 📋 接口联调  [跳过]           │   │
│  │   ☑ 📁 阶段三：测试上线             │   │
│  │     ☑ 📋 Bug 修复                   │   │
│  │     ☑ 📋 部署发布                   │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ─── 根级习惯 ────────────────────────────  │
│  ☑ 🗣️ 每日站会    [编辑] [删除]           │
│  ☑ 📋 当日复盘    [编辑] [删除]           │
│  ➕ 添加自定义习惯                           │
│                                             │
│  ─── 根级日程 ────────────────────────────  │
│  ☑ 冲刺启动会                             │
│  ☑ 交付评审                               │
│  ➕ 添加自定义日程                           │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │      [ ✅ 确认创建计划 ]              │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### 交互流程

```
1. 页面加载 → 调用 useTemplate 预览接口，返回默认配置
2. 用户可：
   - 修改计划名称
   - 选择开始日期
   - 勾选/取消习惯和日程
   - 点击"编辑"修改单个习惯/日程的配置
   - 点击"添加"新增额外习惯/日程
3. 点击"确认创建"
   → POST /plan/template/{id}/use
   → 跳转到计划详情页 or 打卡页
```

---

## 3.6 模板管理（我的模板）

### 入口

在 `plan/home/index.vue` 的快捷功能区新增"模板管理"入口：

```html
<view class="quick-item" @tap="go('/pages/plan/template/index')">
  <view class="quick-icon" style="background: linear-gradient(135deg, #f59e0b, #fbbf24)">📋</view>
  <span class="quick-label">计划模板</span>
</view>
```

### 从计划生成模板

在 `plan/schedule/index.vue` 或 `plan/habit/index.vue` 的计划详情弹窗中，新增"存为模板"按钮：

```
[ 📤 存为模板 ] → 弹出表单：
  - 模板名称
  - 描述
  - 可见性（私有/公开）
→ POST /plan/template/from-plan/{planId}
→ 成功后跳转到模板列表
```

---

## 3.7 组件拆分

```
src/pages/plan/template/
  ├── index.vue                    # 模板列表页
  ├── detail.vue                   # 模板详情页
  ├── use.vue                      # 使用模板（创建计划确认）
  └── components/
      ├── TemplateCard.vue         # 模板卡片组件（列表用）
      ├── PlanTreeView.vue         # ★ 多层级计划树组件（递归渲染）
      ├── PlanTreeNode.vue         # ★ 计划树节点（递归子组件）
      ├── TemplateHabitPreview.vue # 习惯预览列表
      ├── TemplateEventPreview.vue # 日程预览列表
      ├── UseHabitEditor.vue       # 使用时习惯编辑器
      └── UseEventEditor.vue       # 使用时日程编辑器
```

---

## 3.8 样式规范

遵循现有 `plan` 模块的设计系统：

- 使用 CSS 变量：`var(--color-primary)`, `var(--color-surface)`, `var(--radius-md)`
- 卡片样式：`.premium-card`, `.premium-fade-in`
- 按钮样式：`.premium-header-btn`
- 分类 Tab：参考 `habit/index.vue` 的 `.checkin-tabs` 结构
- 模板卡片配色：使用模板自身的 `color` 字段作为主题色

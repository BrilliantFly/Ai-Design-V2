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

### `src/api/plan/habit-template.ts`（新增）

```typescript
import request from '@/utils/request'

export function getHabitTemplateList(params) {
  return request.get({ url: '/plan/habit-template/list', data: params })
}

export function getHotHabitTemplates(params) {
  return request.get({ url: '/plan/habit-template/hot', data: params })
}

export function getHabitTemplateDetail(id) {
  return request.get({ url: `/plan/habit-template/${id}` })
}

export function createHabitTemplate(data) {
  return request.post({ url: '/plan/habit-template', data })
}

export function updateHabitTemplate(data) {
  return request.put({ url: '/plan/habit-template', data })
}

export function deleteHabitTemplate(id) {
  return request.delete({ url: `/plan/habit-template/${id}` })
}
```

### `src/api/plan/event-template.ts`（新增）

```typescript
import request from '@/utils/request'

export function getEventTemplateList(params) {
  return request.get({ url: '/plan/event-template/list', data: params })
}

export function getHotEventTemplates(params) {
  return request.get({ url: '/plan/event-template/hot', data: params })
}

export function getEventTemplateDetail(id) {
  return request.get({ url: `/plan/event-template/${id}` })
}

export function createEventTemplate(data) {
  return request.post({ url: '/plan/event-template', data })
}

export function updateEventTemplate(data) {
  return request.put({ url: '/plan/event-template', data })
}

export function deleteEventTemplate(id) {
  return request.delete({ url: `/plan/event-template/${id}` })
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
},
{
  "path": "pages/plan/habit-template/index",
  "style": { "navigationBarTitleText": "习惯模板" }
},
{
  "path": "pages/plan/habit-template/detail",
  "style": { "navigationBarTitleText": "习惯模板详情" }
},
{
  "path": "pages/plan/event-template/index",
  "style": { "navigationBarTitleText": "日程模板" }
},
{
  "path": "pages/plan/event-template/detail",
  "style": { "navigationBarTitleText": "日程模板详情" }
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

## 3.6 习惯模板管理 `habit-template/index.vue`

### 页面结构

```
┌─────────────────────────────────────────────┐
│ 🏃 习惯模板                         [+ 新建]│
├─────────────────────────────────────────────┤
│ 🔍 搜索习惯模板...                            │
├─────────────────────────────────────────────┤
│ [全部] [健身] [读书] [工作] [通用]             │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ 🏃 每日晨跑    30天  5公里/天  [使用 236]│ │
│ │ 📖 每日阅读    30天  30页/天   [使用 189]│ │
│ │ 🗣️ 每日站会    14天  每天      [使用 312]│ │
│ │ 🔍 代码Review  14天  每天      [使用 156]│ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ─── 我的习惯模板 ──────────────────────────  │
│ ┌─────────────────────────────────────────┐ │
│ │ ✨ 自定义习惯1            [编辑] [删除]  │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 习惯模板详情/编辑表单

```
┌─────────────────────────────────────────────┐
│ ← 习惯模板详情                      [保存]  │
├─────────────────────────────────────────────┤
│ 习惯名称: [每日晨跑                        ] │
│ 图标:     [🏃] 颜色: [#22b573]              │
│ 描述:     [30天晨跑养成计划                  ] │
│                                             │
│ ─── 习惯配置 ──────────────────────────────  │
│ 频率类型: [每天 ▼]                           │
│ 提醒时间: [07:00]                            │
│ 休息日:   [周日] [周六]                       │
│ 目标天数: [30] 天                            │
│ 目标数值: [5] 公里                           │
│ 追踪类型: [数值打卡 ▼]                       │
│                                             │
│ ─── 适用场景 ──────────────────────────────  │
│ 适用计划类型: [健身 ▼]  标签: [健身,跑步]     │
│ 可见性: [公开 ▼]                             │
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │          [ 💾 保存模板 ]              │   │
│ └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 3.7 日程模板管理 `event-template/index.vue`

### 页面结构

```
┌─────────────────────────────────────────────┐
│ 📅 日程模板                         [+ 新建]│
├─────────────────────────────────────────────┤
│ 🔍 搜索日程模板...                            │
├─────────────────────────────────────────────┤
│ [全部] [工作] [学习] [通用]                   │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ 📋 制定周计划    每周一  重要不紧急       │ │
│ │ 📋 复盘总结      每周五  重要不紧急       │ │
│ │ 📋 冲刺启动会    一次性  重要紧急         │ │
│ │ 📋 交付评审      一次性  重要紧急         │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ─── 我的日程模板 ──────────────────────────  │
│ ┌─────────────────────────────────────────┐ │
│ │ ✨ 自定义日程1            [编辑] [删除]  │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 日程模板详情/编辑表单

```
┌─────────────────────────────────────────────┐
│ ← 日程模板详情                      [保存]  │
├─────────────────────────────────────────────┤
│ 模板名称: [制定周计划                      ] │
│ 日程标题: [制定周计划                      ] │
│ 描述:     [每周一制定本周计划               ] │
│                                             │
│ ─── 日程配置 ──────────────────────────────  │
│ 日程类型: [普通 ▼]                           │
│ 四象限:   [重要不紧急 ▼]                     │
│ 优先级:   [⭐⭐]                             │
│ 是否重复: [是 ▼]                             │
│ 重复类型: [每周 ▼]                           │
│ 重复规则: [周一]                             │
│ 全天:     [否]                               │
│ 提前提醒: [15] 分钟                          │
│ 地点:     [办公室                          ] │
│                                             │
│ ─── 适用场景 ──────────────────────────────  │
│ 适用计划类型: [全部 ▼]  标签: [周计划]       │
│ 可见性: [公开 ▼]                             │
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │          [ 💾 保存模板 ]              │   │
│ └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 3.8 模板管理（我的模板）

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

## 3.9 执行状态改造（现有日程/打卡）

### know-uniapp（移动端）改动

**1. 创建表单注入 `execStatus=1`（执行中，App 立即可见）**

改 4 处 `buildPayload()`，统一追加：

```ts
// HabitFormSheet.vue / habit/form.vue
buildPayload() {
  return {
    ...this.form,
    execStatus: 1, // ★ 移动端新建 → 执行中
  };
}

// ScheduleFormSheet.vue / schedule 表单
buildPayload() {
  return {
    ...this.form,
    execStatus: 1, // ★ 移动端新建 → 执行中
  };
}
```

**2. 列表/日历/统计接口统一带 `execStatus=1`**

`src/api/plan/habit.ts` 与 `schedule.ts` 的所有查询方法追加参数：

```ts
export const getHabitList = (params = {}) =>
  http.get('/plan/habit/list', { ...params, execStatus: 1 });

export const getEventList = (params = {}) =>
  http.get('/plan/event/list', { ...params, execStatus: 1 });
```

> 备注：为了兼容模板创建链路，后端兜底 execStatus=1；但如果用户从模板批量创建的是草稿，App 端查询必须显式带 `execStatus=1` 才不显示。

**3. 模板使用（`template/use.vue` 与计划内使用）**

使用模板创建事项时透传来源：`execStatus: 1`（移动端使用模板 = 要执行）。

### know-vue（管理端）改动

**1. 创建表单注入 `execStatus=0`（非执行/草稿，App 不显示）**

```ts
// src/views/plan/habit/index.vue 新增表单提交
payload: { ...formData, execStatus: 0 } // ★ 管理端新建 → 草稿

// src/views/plan/schedule/index.vue 新增表单提交
payload: { ...formData, execStatus: 0 } // ★ 管理端新建 → 草稿
```

**2. 列表展示全部，支持按执行状态筛选与切换**

```html
<!-- 列表页顶部筛选 -->
<el-select v-model="queryParams.execStatus" placeholder="执行状态">
  <el-option label="全部" :value="undefined" />
  <el-option label="执行中" :value="1" />
  <el-option label="非执行(草稿)" :value="0" />
</el-select>

<!-- 行内切换按钮 -->
<el-switch
  v-model="row.execStatus"
  :active-value="1"
  :inactive-value="0"
  active-text="执行中"
  inactive-text="草稿"
  @change="toggleExecStatus(row)"
/>
```

```ts
// 切换接口
const toggleExecStatus = async (row) => {
  const url =
    row.type === 'habit'
      ? `/adminapi/plan/habit/${row.id}/exec-status`
      : `/adminapi/plan/event/${row.id}/exec-status`;
  await updateExecStatus(url, { execStatus: row.execStatus });
};
```

**3. 模板使用（`view/plan/template/use`）**

使用模板创建事项透传来源：`execStatus: 0`（管理端使用模板 = 先建草稿，审批后切换执行）。

### 审批/联动说明（非强制）

管理端可将"非执行 → 执行"视为上架/审批动作。切换后 App 可见。可后续扩展：
- 切换为执行时可选发送通知给用户
- 计划详情页展示该计划下的草稿数/执行数统计

### 4. 计划内选择模板（useInPlan）★ 核心入口

在**计划详情页**（know-uniapp 计划详情弹窗 / know-vue `views/plan/info/detail.vue`）新增"从模板添加日程/打卡"：

```html
<!-- know-uniapp 计划详情 -->
<view class="action-bar">
  <button @tap="showTemplatePicker">从模板添加打卡/日程</button>
</view>

<!-- picker 流程 -->
1. 弹出模板列表（可搜索/按类型筛选） → POST /plan/template/list
2. 选择模板 → 加载模板 detail（含 default_habit_ids/default_event_ids 解析）
   → GET /plan/template/{id}
3. 勾选要带过来的习惯/日程（默认全选，可取消）
4. 确认 → POST /plan/template/use-in-plan
   body: { planId, templateId, execStatus: 1,  // 移动端=1；管理端=0
           selectedHabitIds: [...], selectedEventIds: [...] }
5. 成功 → 刷新计划下的打卡/日程列表 → App 可见（execStatus=1）
```

> 管理端流程一致，仅 `execStatus: 0`，创建后为草稿，需在列表页切换为执行才会在 App 显示。

---

## 3.10 组件拆分

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

src/pages/plan/habit-template/
  ├── index.vue                    # 习惯模板列表页
  ├── detail.vue                   # 习惯模板详情/编辑页
  └── components/
      ├── HabitTemplateCard.vue    # 习惯模板卡片
      └── HabitTemplateForm.vue    # 习惯模板表单

src/pages/plan/event-template/
  ├── index.vue                    # 日程模板列表页
  ├── detail.vue                   # 日程模板详情/编辑页
  └── components/
      ├── EventTemplateCard.vue    # 日程模板卡片
      └── EventTemplateForm.vue    # 日程模板表单
```

---

## 3.8 样式规范

遵循现有 `plan` 模块的设计系统：

- 使用 CSS 变量：`var(--color-primary)`, `var(--color-surface)`, `var(--radius-md)`
- 卡片样式：`.premium-card`, `.premium-fade-in`
- 按钮样式：`.premium-header-btn`
- 分类 Tab：参考 `habit/index.vue` 的 `.checkin-tabs` 结构
- 模板卡片配色：使用模板自身的 `color` 字段作为主题色

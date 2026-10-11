# 03 - 前端设计（know-vue 管理端）

## 3.1 目标与范围

在 `know-vue`（Vue3 + TSX/Vue SFC + ant-design-vue + Pinia + axios）中：

1. 全局显示**可拖动悬浮图标**，点击展开/收起对话抽屉；
2. 抽屉内可**切换免费模型**、发送消息、查看流式回复；
3. 「系统管理 → AI 助手设置」页可配置 opencode 访问地址并测试连通性。

---

## 3.2 目录与文件落位

```
know-vue/src/
├── api/ai/
│   └── chat.ts                       # 全部 /api/ai/* 请求封装
├── stores/modules/
│   └── aiChat.ts                     # 面板开关、当前会话、当前模型（持久化）
├── components/AiChat/
│   ├── index.tsx                     # 悬浮球 + 抽屉容器（对外唯二入口）
│   ├── FloatBall.tsx                 # 可拖动悬浮图标（含未读小红点）
│   ├── ChatDrawer.tsx                # 对话抽屉（头部/消息区/输入区）
│   ├── MessageList.tsx               # 消息气泡 + Markdown 渲染
│   ├── ModelSelect.tsx               # 模型下拉（免费标签）
│   ├── SessionList.tsx               # 会话列表（切换/新建/删除）
│   └── ai-chat.module.less
├── views/system/ai/
│   └── index.vue                     # AI 助手设置页
└── router/routes/modules/system.ts   # 增加「AI 助手设置」子路由
```

---

## 3.3 API 封装 `src/api/ai/chat.ts`

```ts
import { service } from '@/utils/axios'

// 配置
export const getAiConfig = () => service({ url: '/api/ai/config', method: 'get' })
export const updateAiConfig = (data) => service({ url: '/api/ai/config', method: 'put', data })
export const testAiConfig = (data) => service({ url: '/api/ai/config/test', method: 'post', data })
export const getAiStatus = () => service({ url: '/api/ai/config/status', method: 'get' })

// 模型
export const listAiModels = (params) => service({ url: '/api/ai/models', method: 'get', params })

// 会话
export const createAiSession = (data) => service({ url: '/api/ai/session', method: 'post', data })
export const listAiSessions = (params) => service({ url: '/api/ai/session/list', method: 'get', params })
export const listAiMessages = (id) => service({ url: `/api/ai/session/${id}/messages`, method: 'get' })
export const switchAiModel = (id, data) => service({ url: `/api/ai/session/${id}/model`, method: 'post', data })
export const deleteAiSession = (id) => service({ url: `/api/ai/session/${id}`, method: 'delete' })

// 对话
export const chatAiOnce = (data) => service({ url: '/api/ai/chat', method: 'post', data })
export const stopAiChat = (id) => service({ url: `/api/ai/chat/${id}/stop`, method: 'post' })
```

> 复刻 `serviceMap.python` 侧写法保持一致；后端统一 `code=0/1/200` 视为成功（已在 `utils/axios` 拦截器处理）。

---

## 3.4 SSE 流式请求（fetch，非 axios）

axios 不便读流，采用 `fetch` + `ReadableStream` 解析 SSE；**必须带 `token` 头**（因不能直接用 `EventSource` 携带自定义头）。

```ts
// utils/aiStream.ts
export async function streamChat(
  payload: { sessionId?: number; content: string; providerId?: string; modelId?: string },
  handlers: { onStart?; onDelta?; onDone?; onError?; signal?: AbortSignal }
) {
  const res = await fetch('/api/ai/chat/stream', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', token: localStorage.getItem('token') || '' },
    body: JSON.stringify(payload),
    signal: handlers.signal
  })
  const reader = res.body!.getReader()
  const decoder = new TextDecoder('utf-8')
  let buf = ''
  while (true) {
    const { value, done } = await reader.read()
    if (done) break
    buf += decoder.decode(value, { stream: true })
    // 按 \n\n 切分事件块，解析 event:/data:
    let idx
    while ((idx = buf.indexOf('\n\n')) >= 0) {
      parseSseBlock(buf.slice(0, idx), handlers)
      buf = buf.slice(idx + 2)
    }
  }
  handlers.onDone?.()
}
```

---

## 3.5 Pinia Store `stores/modules/aiChat.ts`

```ts
export const useAiChatStore = defineStore('aiChat', {
  state: () => ({
    opened: false,          // 抽屉开关
    ballPos: { x: 24, y: 120 },  // 悬浮球位置（右下角为基准）
    sessionId: null as number | null,
    providerId: '',
    modelId: '',
    models: [] as ModelVO[],
    messages: [] as Msg[],
    streaming: false
  }),
  persist: { pick: ['ballPos', 'sessionId', 'providerId', 'modelId'] }  // 已有 pinia-plugin-persistedstate
})
```

---

## 3.6 组件设计

### 3.6.1 FloatBall（悬浮球）

- 固定 `position: fixed; right/bottom`，`z-index: 1000`；
- **可拖动**：`mousedown/mousemove/mouseup`（+ touch 事件）计算位移并边界收敛，写回 `ballPos` 持久化；
- 点击（非拖动）→ `store.opened = !store.opened`；
- 角标：有流式回复时显示脉冲点；
- 未配置 opencode（`getAiStatus().configured=false`）→ 首次点击弹出"去配置"引导。
- **挂载点**：`src/layout/index.tsx` 根 `<Layout>` 内追加 `<AiChatFloat />`（登录后全局可见）。

```tsx
// layout/index.tsx 关键改动
import AiChatFloat from '@/components/AiChat'

return () => (
  <Layout {...unref(lockEvents)}>
    ...
    <LayoutLockPage />
    <AiChatFloat />     {/* 新增 */}
  </Layout>
)
```

### 3.6.2 ChatDrawer（对话抽屉）

- 使用 `a-drawer`（`placement="right"`，宽度 420，移动端全屏）；
- 结构：
  - 头部：标题 + **ModelSelect** + 新建会话 + 历史会话 + 关闭；
  - 消息区：`MessageList`（自动滚底）；
  - 输入区：`a-textarea`（Enter 发送 / Shift+Enter 换行）+ 发送/停止按钮；
- 流式：发送后 `streaming=true`，`onDelta` 追加到末尾助手消息，`onDone` 结束并落库展示；
- 中断：`AbortController` + `stopAiChat`。

### 3.6.3 ModelSelect（模型下拉）

- `listAiModels({})` 拉取；
- 免费模型加 `免费` 绿色标签，分组：`免费模型` / `全部模型`；
- 默认选中：配置的 `defaultModelId` → 否则第一个 `isFree=true`；
- 切换时：已有会话调用 `switchAiModel(sessionId, ...)`；无会话则记入 store，新建会话时带上。

### 3.6.4 MessageList（消息区）

- 助手消息走 `md-editor-v3`（项目已依赖）的只读模式渲染 Markdown；
- 支持复制、重新生成（可选）；
- 空态：引导语 + 示例问题。

### 3.6.5 设置页 `views/system/ai/index.vue`

- 表单：配置名、访问地址、鉴权头、鉴权 token（password，回显 `******`）、默认模型、超时；
- 操作：**测试连接**（`testAiConfig`）→ 展示可达/模型数量；保存；
- 模型预览表格：providerID / modelID / 名称 / 免费 / 状态 / 上下文长度；
- 结构对齐 `views/system/dict.vue`（`a-form` + `a-table` + `a-modal`）。

### 3.6.6 路由与菜单

- `router/routes/modules/system.ts` 增加子路由：

```ts
{
  path: 'ai',
  name: 'SystemAiSetting',
  component: () => import('@/views/system/ai/index.vue'),
  meta: { title: 'AI 助手设置' }
}
```

- DB 菜单：向 `sys_menu` 插入一行（父级=系统管理，path=`/system/ai`，`menu_type=2`），沿用现有迁移/脚本方式；实现时先查库确定空闲 id。

---

## 3.7 交互细节

| 场景 | 表现 |
|------|------|
| 未配置地址 | 悬浮球点击 → 提示"未配置 opencode 访问地址"，按钮跳设置页 |
| opencode 不可达 | 抽屉顶部红色告警条 + 设置页"重新测试" |
| 无免费模型 | 模型下拉只显示付费模型并给出提示（可配置是否允许付费） |
| 流式失败 | 保留已输出内容，末尾显示"生成失败，点击重试" |
| 长文本 | 消息区虚拟滚动/懒渲染（消息 > 200 条时） |
| 移动端窄屏 | 抽屉全宽、悬浮球缩小、拖动吸附边缘 |

---

## 3.8 本轮不做

- 文件/图片上传、语音输入；
- 工具调用过程可视化（opencode tool 事件）；
- 多标签并行会话；
- 前端直连 opencode（一律经后端）。

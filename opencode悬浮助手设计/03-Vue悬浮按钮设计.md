# 03 - Vue 悬浮按钮设计

> 对应前端：`know-vue`（Vue3 + TSX + ant-design-vue + Pinia + axios）
> 入口：`src/layout/index.tsx` 全局挂载悬浮球组件

---

## 1. 组件结构

```
src/components/AiAssistant/
├── index.tsx                  # 悬浮球 + 抽屉容器
├── FloatingBall.tsx           # 悬浮图标（可拖动）
├── ChatDrawer.tsx             # 对话抽屉
├── MessageList.tsx            # 消息列表
├── MessageInput.tsx           # 输入框
├── ModelSelect.vue            # 免费模型下拉
├── SettingModal.vue           # 设置弹窗（管理员）
└── useAiChat.ts              # 对话逻辑（Pinia store + SSE）
```

挂载方式（`src/layout/index.tsx`）：

```tsx
import AiAssistant from '@/components/AiAssistant'

export default defineComponent({
  setup() {
    return () => (
      <Layout>
        {/* 既有 router-view */}
        <AiAssistant />     {/* 全局悬浮球，右下角 */}
      </Layout>
    )
  }
})
```

---

## 2. 悬浮球 FloatingBall

### 2.1 交互

- 默认右下角（`bottom: 24px; right: 24px`），圆 56px，带 AI 图标。
- **可拖动**：`pointerdown` → `pointermove`（更新 `left/top`）→ `pointerup`（吸附到最近边缘）。
- 拖动与点击区分：位移 < 6px 视为点击 → 触发 `open` 抽屉。
- 长按 600ms 可触发「隐藏入口」（记忆到 localStorage）。
- 有新回复时球体跳动 + 红点提示。

### 2.2 样式（核心 CSS）

```css
.ai-float-ball {
  position: fixed;
  z-index: 9999;
  width: 56px; height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, #6a5cff, #8a7fff);
  box-shadow: 0 6px 20px rgba(106,92,255,.4);
  cursor: grab;
  display: flex; align-items: center; justify-content: center;
  color: #fff; font-size: 24px;
  user-select: none;
  transition: transform .2s;
}
.ai-float-ball:active { cursor: grabbing; transform: scale(1.1); }
.ai-float-ball.has-reply { animation: pulse 1s ease 2; }
```

### 2.3 TSX 草案

```tsx
export default defineComponent({
  name: 'FloatingBall',
  emits: ['click'],
  setup(_, { emit }) {
    const pos = reactive({ x: 0, y: 0 })  // 相对右下偏移
    let dragging = false, startX = 0, startY = 0, moved = 0
    const onDown = (e: PointerEvent) => {
      dragging = true; startX = e.clientX; startY = e.clientY; moved = 0
    }
    const onMove = (e: PointerEvent) => {
      if (!dragging) return
      const dx = e.clientX - startX, dy = e.clientY - startY
      moved = Math.max(moved, Math.hypot(dx, dy))
      pos.x += dx; pos.y += dy; startX = e.clientX; startY = e.clientY
    }
    const onUp = () => {
      dragging = false
      if (moved < 6) emit('click')        // 点击：开抽屉
      else snapToEdge(pos)                 // 拖动：吸附边缘
    }
    return () => (
      <div class="ai-float-ball" style={ballStyle(pos)}
        onPointerdown={onDown} onPointermove={onMove} onPointerup={onUp}>
        <IconFont name="robot" />
      </div>
    )
  }
})
```

---

## 3. 对话抽屉 ChatDrawer

用 `a-drawer`，从右侧滑出，宽 420px（桌面），全屏（移动）。

```tsx
<a-drawer v-model:open={open} title="AI 助手" placement="right" width={420}>
  <template #extra>
    <ModelSelect v-model={modelId} />          {/* 免费模型下拉 */}
    <a-button type="text" onClick={openSetting}>设置</a-button>
  </template>
  <MessageList messages={messages} streaming={streaming} />
  <MessageInput onSend={send} disabled={streaming} />
</a-drawer>
```

### 3.1 消息气泡

- user 消息：右对齐，蓝底白字。
- assistant 消息：左对齐，灰底黑字，支持 **打字机效果**（SSE delta 逐字追加）。
- 流式中显示「停止」按钮 → `POST /api/ai/chat/abort`。

### 3.2 模型选择 ModelSelect

```tsx
<a-select v-model:value={modelId} options={freeModels} placeholder="选择免费模型" />
```

数据源：`GET /api/ai/models/free` → `[{ id, name }]`，默认选中配置项 `defaultFreeModel`。
仅管理员可见「设置」入口（`useUserStore().roles.includes('admin')`）。

---

## 4. 对话逻辑 useAiChat

基于 Pinia store：

```ts
export const useAiStore = defineStore('ai', () => {
  const messages = ref<Msg[]>([])
  const sessionId = ref<number | null>(null)
  const streaming = ref(false)
  const controller = ref<AbortController | null>(null)

  async function send(content: string, model: string) {
    if (!sessionId.value) await createSession()
    messages.value.push({ role: 'user', content, status: 'done' })
    messages.value.push({ role: 'assistant', content: '', status: 'streaming' })
    streaming.value = true
    controller.value = new AbortController()

    const resp = await fetch('/api/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: token() },
      body: JSON.stringify({ sessionId: sessionId.value, content, model }),
      signal: controller.value.signal,
    })
    const reader = resp.body!.getReader()
    const decoder = new TextDecoder()
    let buf = ''
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buf += decoder.decode(value, { stream: true })
      // 按 \n\n 切 SSE 帧
      const frames = buf.split('\n\n'); buf = frames.pop()!
      for (const f of frames) {
        const line = f.replace(/^data:\s*/, '')
        const evt = JSON.parse(line)
        if (evt.type === 'delta') {
          messages.value.at(-1)!.content += evt.text   // 逐字追加
        } else if (evt.type === 'done') {
          messages.value.at(-1)!.status = 'done'
        }
      }
    }
    streaming.value = false
  }

  function stop() { controller.value?.abort(); streaming.value = false }

  return { messages, sessionId, streaming, send, stop }
})
```

---

## 5. 设置弹窗 SettingModal（管理员）

表单字段：

| 字段 | 控件 | 校验 |
|------|------|------|
| opencode 地址 | `a-input` | 必填，http/https |
| Basic 用户名 | `a-input` | 可空 |
| Basic 密码 | `a-input-password` | 可空 |
| 默认模型 | `a-select`（free 列表） | 必填 |
| 启用 | `a-switch` | — |

操作：

- **测试连通** → `POST /api/ai/config/test`，结果用 `message.success` 提示。
- **保存** → `POST /api/ai/config`，成功后刷新模型列表。

---

## 6. 权限与显隐

- 悬浮球对所有登录用户可见（含普通用户）。
- 设置入口仅 `admin` 可见。
- 普通用户只能使用默认模型，不能切换模型（可按业务需求放开）。

---

## 7. 边界处理

| 场景 | 处理 |
|------|------|
| AI 服务未配置 | 球体置灰，点击提示「管理员未配置 AI 服务」 |
| 流式超时（120s） | fetch 自动断开，assistant 气泡标红「超时」 |
| 网络断开 | `AbortController` 捕获，保留已生成内容 |
| 切换会话 | 抽屉保留，`sessionId` 切换并重拉历史 `GET /api/ai/session/{id}` |
| 长文本 | assistant 气泡内部滚动，不撑高抽屉 |

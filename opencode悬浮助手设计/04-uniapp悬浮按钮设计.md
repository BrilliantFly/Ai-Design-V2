# 04 - uniapp 悬浮按钮设计

> 对应前端：`know-uniapp`（uni-app + Vue3）
> 请求封装：`src/utils/request`，服务映射 `serviceMap`
> 挂载方式：easycom 组件，按页引入（uni-app 无全局根布局）

---

## 1. 组件结构

```
src/components/ai-assistant/
├── ai-assistant.vue           # 悬浮球 + 弹层容器（easycom 自动注册）
├── ai-float-ball.vue          # 悬浮图标
├── ai-chat-popup.vue          # 对话弹层
├── ai-message-list.vue        # 消息列表
├── ai-message-input.vue       # 输入框
└── ai-store.js                # 对话逻辑（composable）
```

easycom 配置（`pages.json`）：

```json
"easycom": {
  "autoscan": true,
  "custom": {
    "^ai-(.*)": "@/components/ai-assistant/ai-$1.vue"
  }
}
```

在需要悬浮球的页面（如 `pages/index/index.vue`）直接使用：

```vue
<template>
  <view class="page">
    <!-- 页面内容 -->
    <ai-assistant />
  </view>
</template>
```

> 若希望全站可见，可在 `App.vue` 的模板外层套一个根 view，但 uni-app 推荐按页挂载以避免层级问题。

---

## 2. 悬浮球 ai-float-ball

### 2.1 交互

- 默认右下角，使用 `position: fixed`，尺寸 56×56。
- **可拖动**：`@touchstart` → `@touchmove`（更新 `style.left/top`）→ `@touchend`（吸附边缘）。
- 点击（位移 < 6px）→ 触发 `open` 事件，弹出对话层。
- 红点提示未读回复。

### 2.2 跨端注意

- uni-app 的 `fixed` 在 H5 / App / 小程序表现一致。
- `z-index` 用 9999；小程序原生组件（map/video）层级更高时，需用 `cover-view` 包裹悬浮球。

### 2.3 组件代码

```vue
<template>
  <view class="ai-ball" :style="{ left: pos.x + 'px', top: pos.y + 'px' }"
    @touchstart="onTouchStart" @touchmove.stop.prevent="onTouchMove" @touchend="onTouchEnd">
    <text class="iconfont icon-robot"></text>
    <view v-if="hasNew" class="dot"></view>
  </view>
</template>

<script setup>
const emit = defineEmits(['open'])
const props = defineProps({ hasNew: Boolean })
const pos = reactive({ x: 0, y: 0 })  // 初始用 onMounted 算右下角
let dragging = false, sx = 0, sy = 0, moved = 0

function onTouchStart(e) {
  const t = e.touches[0]
  dragging = true; sx = t.clientX; sy = t.clientY; moved = 0
}
function onTouchMove(e) {
  if (!dragging) return
  const t = e.touches[0]
  const dx = t.clientX - sx, dy = t.clientY - sy
  moved = Math.max(moved, Math.hypot(dx, dy))
  pos.x += dx; pos.y += dy; sx = t.clientX; sy = t.clientY
}
function onTouchEnd() {
  dragging = false
  if (moved < 6) emit('open')   // 点击
  else snapToEdge(pos)          // 吸附
}
</script>

<style>
.ai-ball { position: fixed; z-index: 9999; width: 56px; height: 56px;
  border-radius: 50%; background: linear-gradient(135deg,#6a5cff,#8a7fff);
  display: flex; align-items: center; justify-content: center;
  color: #fff; box-shadow: 0 6px 20px rgba(106,92,255,.4); }
.dot { position: absolute; top: 2px; right: 2px; width: 10px; height: 10px;
  border-radius: 50%; background: #ff4d4f; }
</style>
```

---

## 3. 对话弹层 ai-chat-popup

用 `uni-popup`（uni-ui）从底部弹出，高度 70vh。

```vue
<uni-popup ref="popup" type="bottom" :is-mask-click="false">
  <view class="chat-panel">
    <view class="chat-header">
      <text class="title">AI 助手</text>
      <view class="model-pick" @tap="openModelSheet">
        <text>{{ curModelName }}</text>
      </view>
      <text class="close iconfont icon-close" @tap="close"></text>
    </view>
    <ai-message-list :messages="messages" :streaming="streaming" />
    <ai-message-input :disabled="streaming" @send="onSend" @stop="onStop" />
  </view>
</uni-popup>
```

### 3.1 模型选择

用 `uni.showActionSheet` 或自定义底部弹出：

```js
function openModelSheet() {
  uni.showActionSheet({
    itemList: freeModels.value.map(m => m.name + (m.free ? '（免费）' : '')),
    success: (res) => { curModel.value = freeModels.value[res.tapIndex].id }
  })
}
```

数据源：`GET /api/ai/models/free`。

---

## 4. 跨端流式降级

| 端 | 能力 | 方案 |
|----|------|------|
| H5 | `fetch` + `ReadableStream` | 同 Vue 端：流式逐字追加 |
| App | `uni.request` 不支持分块 | **降级为非流式**：`POST /api/ai/chat?stream=0`，一次性返回完整文本 |
| 小程序 | `uni.request` 无通用分块 | 同 App，非流式 |
| App（nvue） | 可用原生模块 | 暂不引入，保持简单 |

### 4.1 统一请求封装

```js
// #ifdef H5
async function streamChat(payload, onDelta) {
  const resp = await fetch('/api/ai/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: token() },
    body: JSON.stringify(payload),
  })
  const reader = resp.body.getReader()
  const decoder = new TextDecoder()
  let buf = ''
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buf += decoder.decode(value, { stream: true })
    const frames = buf.split('\n\n'); buf = frames.pop()
    for (const f of frames) {
      const evt = JSON.parse(f.replace(/^data:\s*/, ''))
      if (evt.type === 'delta') onDelta(evt.text)
    }
  }
}
// #endif

// #ifndef H5
function streamChat(payload, onDelta) {
  // App / 小程序：非流式，一次性返回
  return new Promise((resolve, reject) => {
    uni.request({
      url: '/api/ai/chat',
      method: 'POST',
      header: { 'Content-Type': 'application/json', Authorization: token() },
      data: { ...payload, stream: false },
      success: (res) => {
        // 后端在非流式下返回 { code, data: { content } }
        onDelta(res.data.data.content)
        resolve()
      },
      fail: reject,
    })
  })
}
// #endif
```

### 4.2 后端配合

`POST /api/ai/chat` 增加参数 `stream`（默认 `true`）：

- `stream=true`：走 `prompt_async` + SSE（见 [02-后端网关设计](./02-后端网关设计.md)）。
- `stream=false`：走 `POST /session/:id/message`（阻塞），一次性返回 `{ content }`。

---

## 5. 对话逻辑 ai-store.js

```js
import { reactive } from 'vue'

const state = reactive({
  sessionId: null,
  messages: [],
  streaming: false,
  curModel: 'opencode/space-bunny-free',
})

export function useAiStore() {
  async function send(content) {
    if (!state.sessionId) state.sessionId = await createSession()
    state.messages.push({ role: 'user', content, status: 'done' })
    state.messages.push({ role: 'assistant', content: '', status: 'streaming' })
    state.streaming = true

    await streamChat(
      { sessionId: state.sessionId, content, model: state.curModel },
      (delta) => { state.messages.at(-1).content += delta }   // 逐字追加
    )
    state.messages.at(-1).status = 'done'
    state.streaming = false
  }

  function stop() { /* H5: AbortController；App: 请求无法中断，等返回 */ }

  return { state, send, stop }
}
```

---

## 6. pages 配置与权限

无需新增页面，悬浮球以组件形式挂载到现有页面。建议挂载位置：

- 首页 `pages/index/index.vue`
- 个人中心 `pages/mine/index.vue`
- 其他高频页面

显隐控制：在 `App.vue` 的 `onLaunch` 拉取 `GET /api/ai/config`，若 `enabled=false` 则设置全局 flag 隐藏球。

---

## 7. 边界处理

| 场景 | 处理 |
|------|------|
| AI 服务未配置 | 球体隐藏或置灰，点击提示 |
| H5 流式中断 | `AbortController.abort()` |
| App 非流式超时 | `uni.request` timeout 设 60s，超时提示重试 |
| 小程序层级遮挡 | 悬浮球用 `cover-view` 包裹 |
| 键盘弹起 | 弹层随 `keyboardheightchange` 上移 |
| 长文本滚动 | `ai-message-list` 用 `scroll-view` 纵向滚动 |

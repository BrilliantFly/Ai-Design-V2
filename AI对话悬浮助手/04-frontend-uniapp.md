# 04 - 前端设计（know-uniapp 移动端）

## 4.1 目标与范围

在 `know-uniapp`（uni-app + Vue3，支持 H5 / App / 小程序）中：

1. 各页面右下角显示**可拖动悬浮球**，点击展开对话弹层；
2. 弹层内选择免费模型、发送消息、查看回复；
3. 跨端处理流式：H5 流式 / App 分块 / 小程序降级。

---

## 4.2 目录与文件落位

```
know-uniapp/src/
├── api/
│   └── ai.ts                         # /api/ai/* 请求封装（复用 utils/request）
├── components/
│   └── ai-chat-float/
│       ├── ai-chat-float.vue         # 悬浮球 + 弹层（easycom 组件）
│       └── ai-chat-float.scss
├── pages/
│   └── ai_chat/
│       └── ai_chat.vue               # 全屏对话页（可选，从弹层"全屏"进入）
├── stores/
│   └── aiChat.ts                     # 面板开关 / 当前会话 / 模型
├── utils/
│   └── request/aiStream.ts           # 跨端流式：H5 fetch / App enableChunked / 降级
└── pages.json                        # 注册 ai_chat 页 + easycom 规则
```

---

## 4.3 API 封装 `src/api/ai.ts`

复用 `src/utils/request`（`createRequest`），与 `api/customer.ts` 风格一致：

```ts
import request from '@/utils/request'

export function getAiModels(params?: any) {
  return request.get('ai/models', { params })
}
export function createAiSession(data: any) {
  return request.post('ai/session', data)
}
export function listAiSessions(params: any) {
  return request.get('ai/session/list', { params })
}
export function listAiMessages(id: number) {
  return request.get(`ai/session/${id}/messages`)
}
export function switchAiModel(id: number, data: any) {
  return request.post(`ai/session/${id}/model`, data)
}
export function deleteAiSession(id: number) {
  return request.delete(`ai/session/${id}`)
}
export function chatAiOnce(data: any) {
  return request.post('ai/chat', data)
}
export function getAiStatus() {
  return request.get('ai/config/status')
}
```

> 请求前缀：既有 `config.urlPrefix='api'`，`serviceMap.java='/plan'` 为历史映射；AI 请求直接走 `api/ai/*`。**需确认**在 App 原生端 `config.baseUrl`（`101.37.83.88:9191`）已反代 `/api`。

---

## 4.4 悬浮球挂载方案（跨端）

uni-app **没有** Vue 那样的全局 Layout 插槽，采用二选一：

| 方案 | 做法 | 适用 |
|------|------|------|
| A. easycom 组件逐页引入（推荐） | `pages.json` 配 `easycom` 规则；在关键页面（首页、计划、客户、知识库等）模板根节点追加 `<ai-chat-float />` | 全端可控，避免全局副作用 |
| B. H5 全局挂载 | `App.vue` 内 `#ifdef H5` 时创建全局节点挂载 | 仅 H5 |

推荐 A：命中易用性，且可在特定页面关闭（如登录页）。

```jsonc
// pages.json
{
  "easycom": {
    "autoscan": true,
    "custom": {
      "^ai-chat-float$": "@/components/ai-chat-float/ai-chat-float.vue"
    }
  },
  "pages": [
    { "path": "pages/ai_chat/ai_chat", "style": { "navigationBarTitleText": "AI 助手" } }
  ]
}
```

页面使用：

```vue
<template>
  <view class="page">
    <!-- 页面内容 -->
    <ai-chat-float />
  </view>
</template>
```

---

## 4.5 组件 `ai-chat-float.vue`

### 结构

```
<movable-area>                         ← 占满屏幕，设置 pointer 区域
  <movable-view x/y direction="all">   ← 可拖动悬浮球
    <view class="ball" @click="toggle">
      <image src="/static/ai/ball.png" />
      <view v-if="loading" class="pulse" />
    </view>
  </movable-view>
</movable-area>

<view v-if="opened" class="mask" @click="close">
  <view class="panel" @click.stop>
    <view class="panel-header">
      <text>AI 助手</text>
      <picker :range="modelNames" @change="onModelChange">模型</picker>
      <text @click="toFullScreen">全屏</text>
      <text @click="close">✕</text>
    </view>
    <scroll-view scroll-y class="msg-list"> ... </scroll-view>
    <view class="input-bar">
      <textarea v-model="input" />
      <button @click="send">发送</button>
    </view>
  </view>
</view>
```

### 关键点

- 拖动用 `movable-area/movable-view`（原生支持，App/H5/小程序一致）；
- 位置持久化：`uni.setStorageSync('ai-ball-pos', {x,y})`；
- 弹层：半屏底部弹出（`animation` 过渡），点击遮罩关闭；
- 未登录：`requireLogin()` 拦截（复用 `utils/util.ts`）；
- 未配置：弹层内提示"未配置 opencode 地址，请在管理端配置"。

---

## 4.6 跨端流式方案

| 端 | 方案 | 说明 |
|----|------|------|
| H5 | `fetch('/api/ai/chat/stream')` + `ReadableStream` | 同 Vue 端 |
| App（Android/iOS） | `uni.request({ enableChunked: true })` + `onChunkReceived` | 手动解析 SSE 分块 |
| 小程序 | **降级** 调 `POST /api/ai/chat`（非流式） | 分块能力不通用；可加"生成中…"占位 |

```ts
// utils/request/aiStream.ts
export function streamChat(payload, handlers) {
  // #ifdef H5
  return h5FetchStream(payload, handlers)
  // #endif
  // #ifdef APP-PLUS
  return appChunkedStream(payload, handlers)
  // #endif
  // #ifdef MP
  return chatAiOnce(payload).then((r) => handlers.onDone(r.data))
  // #endif
}
```

`appChunkedStream` 要点：

```ts
const task = uni.request({
  url: `${config.baseUrl}${config.urlPrefix}/ai/chat/stream`,
  method: 'POST',
  header: { 'Content-Type': 'application/json', token: getToken() },
  data: payload,
  enableChunked: true,
  success: () => {}
})
task.onChunkReceived?.((res) => {
  const text = decodeUtf8(res.data)   // ArrayBuffer → 字符串
  parseSse(text, handlers)
})
```

---

## 4.7 Store `stores/aiChat.ts`

与 Vue 端一致（Pinia 已在依赖中）：`opened / sessionId / providerId / modelId / models / messages / loading`，用 `uni.setStorageSync` 持久化（uni-app 的 pinia 持久化需手动或在 store 内处理）。

---

## 4.8 交互细节

| 场景 | 表现 |
|------|------|
| 未登录 | 点击悬浮球 → 登录页，回跳当前页 |
| 键盘弹出 | `scroll-view` 自动滚底（`scroll-into-view` 到最后一条） |
| 超长回复 | 消息虚拟列表（`z-paging` 项目已依赖，可选） |
| 网络异常 | Toast + 保留已输出内容 + 重试按钮 |
| 深色主题 | 复用 `styles/themes.scss` CSS 变量，适配 `data-theme` |
| 安全区 | 底部 `env(safe-area-inset-bottom)` 适配 |

---

## 4.9 与 know-vue 的差异

| 项 | know-vue | know-uniapp |
|----|----------|-------------|
| 挂载 | `layout/index.tsx` 全局 | easycom 组件逐页引入 |
| 抽屉 | `a-drawer` | 自定义底部弹层 |
| 流式 | fetch 流 | H5 fetch / App 分块 / 小程序降级 |
| 设置页 | 有（系统管理 → AI 助手设置） | 无（只读展示状态） |
| 拖动 | 鼠标/触摸事件 | `movable-area/movable-view` |

---

## 4.10 本轮不做

- 小程序端流式；
- 语音输入、图片上传；
- 独立会话管理页（弹层内切换即可）。

# 01 - opencode 免费模型接口设计

> 对应模块：`know-boot-ai` 的 `OpenCodeClient` 适配层
> 依赖：opencode `serve` 常驻 HTTP（默认 `http://127.0.0.1:4096`）

---

## 1. opencode 服务启动

```bash
# 启动 HTTP 服务，默认端口 4096，默认绑定 127.0.0.1
opencode serve

# 自定义端口与主机，并允许跨域（前端联调时可加 --cors）
opencode serve --port 4096 --hostname 0.0.0.0 --cors "*"

# 启用 HTTP Basic 鉴权（环境变量）
export OPENCODE_SERVER_USERNAME=opencode
export OPENCODE_SERVER_PASSWORD=your-secret
opencode serve
```

OpenAPI 3.1 规范可通过 `GET /doc` 获取（`http://localhost:4096/doc`）。

---

## 2. 模型清单接口

### 2.1 获取可用模型（v2 分页路由）

```
GET {baseUrl}/api/model
```

响应（分页信封）：

```jsonc
{
  "location": "...",
  "data": [
    {
      "id": "opencode/space-bunny-free",
      "providerID": "opencode",
      "info": {
        "name": "Space Bunny (Free)",
        "cost": {
          "input": 0,
          "output": 0,
          "reasoning": 0,
          "cache_read": 0,
          "cache_write": 0
        },
        "limit": { "context": 128000, "output": 8192 }
      }
    }
  ]
}
```

### 2.2 获取已连接 provider 与默认模型（v1 路由）

```
GET {baseUrl}/provider          # { all: Provider[], default, connected: string[] }
GET {baseUrl}/config/providers  # { providers: Provider[], default: { [key]: string } }
```

### 2.3 免费模型判定规则

opencode 的 `Model.Info.cost` 为 **对象**（USD / 百万 token），不是数组：

| 字段 | 类型 | 说明 |
|------|------|------|
| `cost.input` | Number | 输入单价 |
| `cost.output` | Number | 输出单价 |
| `cost.reasoning` | Number | 推理单价（可选） |
| `cost.cache_read` | Number | 缓存读单价（可选） |
| `cost.cache_write` | Number | 缓存写单价（可选） |

**免费模型判定**：`cost.input === 0 && cost.output === 0`（且若存在 `reasoning`/`cache_*` 字段亦为 `0`）。

`OpenCodeClient` 中实现：

```java
public boolean isFreeModel(Model m) {
    ModelInfo c = m.getInfo();
    if (c == null || c.getCost() == null) return false;
    Cost cost = c.getCost();
    return notPos(cost.getInput())
        && notPos(cost.getOutput())
        && notPos(cost.getReasoning())
        && notPos(cost.getCacheRead())
        && notPos(cost.getCacheWrite());
}
private boolean notPos(Double v) { return v == null || v == 0d; }
```

---

## 3. OpenCode Zen 内置免费模型（默认首选）

opencode 内置 `opencode` provider（OpenCode Zen），其端点 `https://opencode.ai/zen/v1/models` 暴露多个**显式免费**模型，无需额外申请 API Key：

| 模型 ref（`opencode/<id>`） | 说明 |
|------------------------------|------|
| `opencode/space-bunny-free` | 通用对话，免费 |
| `opencode/big-pickle` | 大上下文，免费 |
| `opencode/longcat-2.5-preview-free` | LongCat 2.5 预览，免费 |
| `opencode/exo-free` | Exo，免费 |
| `opencode/fledge-alpha-free` | Fledge Alpha，免费 |
| `opencode/mimo-v2.6-flash-free` | MiMo v2.6 Flash，免费 |
| `opencode/mimo-v2.5-free` | MiMo v2.5，免费 |
| `opencode/ling-3.1-flash-free` | Ling 3.1 Flash，免费 |
| `opencode/ling-3.0-flash-fin-free` | Ling 3.0 Flash 金融，免费 |
| `opencode/nemotron-3-ultra-free` | Nemotron 3 Ultra，免费 |
| `opencode/nemotron-3.5-lightning-free` | Nemotron 3.5 Lightning，免费 |
| `opencode/muse-spark-1.3-contributor-free` | Muse Spark 1.3，免费 |
| `opencode/jev-1.13-free` | JEV 1.13，免费 |
| `opencode/step-5-preview-free` | Step 5 预览，免费 |

> 默认模型：`opencode/space-bunny-free`（对应配置 `know.opencode.default-free-model`）。

### 3.1 备选免费模型来源

| Provider | 接入方式 | 免费模型示例 |
|----------|---------|-------------|
| OpenRouter | 自定义 provider（`@ai-sdk/openai-compatible`），配 `apiKey` | 模型 ID 带 `:free` 后缀的变体 |
| Google Gemini | `@ai-sdk/google`，配 API Key | Gemini Flash 免费档 |
| GitHub Models | GitHub Copilot 订阅 | 免费档模型 |
| Ollama / LM Studio / vLLM | 本地 OpenAI 兼容协议，无需 Key | 本地任意开源模型 |

> 内网/离线环境：改用 Ollama 本地模型作为唯一免费来源。

---

## 4. 会话接口

### 4.1 创建会话

```
POST {baseUrl}/session
Content-Type: application/json

{ "parentID": null, "title": "know-ai 聊天" }
```

响应 `Session`：

```jsonc
{
  "id": "sess_01J...",
  "title": "know-ai 聊天",
  "parentID": null,
  "createdAt": 1760000000,
  "updatedAt": 1760000000
}
```

### 4.2 会话管理

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/session` | 列出全部会话 |
| `GET` | `/session/:id` | 获取单个会话 |
| `PATCH` | `/session/:id` | 更新会话标题 |
| `DELETE` | `/session/:id` | 删除会话 |
| `GET` | `/session/status` | 会话状态 `{ [id]: { type: "busy"\|"idle" } }` |

### 4.3 发送消息（阻塞）

```
POST {baseUrl}/session/:id/message
Content-Type: application/json

{
  "model": "opencode/space-bunny-free",
  "parts": [{ "type": "text", "text": "你好" }]
}
```

响应（**阻塞**，等模型完整返回）：

```jsonc
{ "info": { /* Message */ }, "parts": [ { "type": "text", "text": "你好！有什么可以帮你？" } ] }
```

### 4.4 发送消息（非阻塞，配合 SSE 流式）

```
POST {baseUrl}/session/:id/prompt_async
Content-Type: application/json

{ "model": "opencode/space-bunny-free", "parts": [{ "type": "text", "text": "你好" }] }
```

响应：HTTP `204`（无内容）。模型输出通过 `/event` 事件流推送。

### 4.5 获取历史消息

```
GET {baseUrl}/session/:id/message?limit=100
```

响应：

```jsonc
{ "info": {/* Message */}, "parts": [/* Part[] */] }
```

### 4.6 中断生成

```
POST {baseUrl}/session/:id/abort
```

---

## 5. 事件流（SSE）

### 5.1 订阅事件

```
GET {baseUrl}/event
Accept: text/event-stream
```

帧格式（`data:` 后为紧凑 JSON，无 `event:`/`id:` 行）：

```
data: {"directory":"/app","payload":{"id":"evt_xxx","type":"server.connected","properties":{}}}

```

首帧 `server.connected`，之后每 10 秒心跳。

### 5.2 一次对话的事件序列

`POST /session/:id/prompt_async` 后，`/event` 依次推送：

| # | event.type | 说明 |
|---|------------|------|
| 1 | `message.updated` | 用户消息创建 |
| 2 | `message.part.updated` | 用户文本 part |
| 3 | `message.updated` | 助手消息（cost=0 占位） |
| 4 | `session.status` | `{ type: "busy" }` |
| 5 | `message.part.updated` | `type: "step-start"` |
| 6 | `message.part.updated` | （可选）`type: "reasoning"` |
| 7 | **`message.part.delta`** | **`{ messageID, partID, field: "text", delta: "..." }` × N** ← 文本增量 |
| 8 | `message.part.updated` | 最终合并的 text part |
| 9 | `message.part.updated` | `type: "tool"` / `step-finish`（若有工具调用） |
| 10 | `message.updated` | 助手消息最终 cost/tokens |
| 11 | `session.status` | `{ type: "idle" }` ← 对话结束 |

### 5.3 后端关心的过滤逻辑

`OpenCodeClient` 消费 `/event` 时只关心：

- `message.part.delta` 且 `field == "text"` → 取 `delta` 转发到前端 SSE
- `session.status` 且 `type == "idle"` → 标记本轮结束，触发 `ai_chat_message` 落库
- 其他事件（reasoning、tool、permission 等）本轮忽略

---

## 6. 鉴权

### 6.1 服务级 HTTP Basic（可选）

```http
GET /api/model
Authorization: Basic base64(opencode:your-secret)
```

`OpenCodeClient` 在所有请求头注入 `Authorization: Basic <base64(username:password)>`（仅当配置了 `basic-username`/`basic-password` 时）。

### 6.2 Provider 级凭证（opencode 自身管理）

opencode 的 provider API Key（如 OpenRouter、Gemini）由 opencode 侧通过 `PUT /auth/:id` 或 `~/.config/opencode/opencode.json` 配置，**后端不接触**。本方案默认使用 OpenCode Zen 内置免费模型，无需额外凭证。

---

## 7. OpenCodeClient 适配层（关键方法签名）

```java
public class OpenCodeClient {
    private final String baseUrl;
    private final String basicHeader;   // 可空

    // 模型
    public List<Model> listModels();                 // GET /api/model（自动翻页）
    public List<Model> listFreeModels();            // 过滤 isFreeModel
    public Model getDefaultFreeModel();             // 配置项兜底

    // 会话
    public Session createSession(String title);     // POST /session
    public List<Session> listSessions();            // GET /session
    public void deleteSession(String id);           // DELETE /session/:id
    public MessageResponse getMessage(String id);  // POST /session/:id/message（阻塞）
    public void promptAsync(String id, ChatRequest req); // POST /session/:id/prompt_async
    public List<MessageResponse> listMessages(String sessionId);

    // 事件流
    public Flux<String> subscribeTextDelta(String sessionId); // GET /event，过滤 message.part.delta
}
```

---

## 8. 连通性测试接口（给设置页用）

后端对外暴露：

```
POST /api/ai/config/test
{ "baseUrl": "http://127.0.0.1:4096", "basicUsername": "...", "basicPassword": "..." }
```

后端逻辑：

1. 用临时参数构造 `OpenCodeClient`。
2. 调 `GET /provider`，若返回 `{ connected: [...] }` 即连通。
3. 返回 `AjaxResult.ok({ connected: true, providers: [...], freeModelCount: N })`。

> 注意：测试用参数不落库，仅返回结果；保存需单独走 `POST /api/ai/config`。

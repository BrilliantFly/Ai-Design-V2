# 02 - 后端 API 接口设计（know-boot-ai）

## 2.0 模块与启动

- 模块：`know-boot-ai`（新增，根 pom `<modules>` 注册）
- 包：`com.know.knowboot.{controller|service|mapper|entity|dto|client|config}.ai`
- 路径前缀：`/api/ai`
- 端口：默认 **8084**（微服务独立启动）；standalone 聚合时随主服务 **8082** 暴露
- 数据库：`ai_` 前缀（见 [01-database-schema.md](./01-database-schema.md)）
- 依赖：`know-boot-common` + `spring-boot-starter-web` + `mybatis-plus` + `mysql` + `swagger`（对齐 `know-boot-biz/pom.xml`），新增 **hutool**（HTTP/SSE 客户端，父 pom 已有版本管理）

---

## 2.1 Controller 结构

```
com.know.knowboot.controller.ai/
  ├── AiConfigController.java   (配置读写 + 连通性测试)
  └── AiChatController.java     (模型 / 会话 / 对话 / 流式)
```

---

## 2.2 AiConfigController

### 路径前缀：`/api/ai/config`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `` | 获取当前配置（`auth_token` 脱敏为 `******`） | — |
| PUT | `` | 保存配置（地址/鉴权/默认模型/超时） | OpenCodeConfigDTO |
| POST | `/test` | 连通性测试：调用 opencode `GET /api/info` | OpenCodeConfigDTO（可为空则用已存配置） |
| GET | `/status` | 返回 `{configured, baseUrl, reachable, modelCount}` | — |

**PUT 请求体：**

```json
{
  "id": 1,
  "name": "本地 opencode",
  "baseUrl": "http://127.0.0.1:4096",
  "authToken": "",
  "authHeader": "Authorization",
  "defaultProviderId": "opencode",
  "defaultModelId": "gpt-5-codex",
  "connectTimeoutMs": 5000,
  "readTimeoutMs": 120000,
  "status": 1,
  "remark": "本机开发"
}
```

**POST `/test` 响应：**

```json
{ "code": 1, "msg": "success", "data": { "reachable": true, "info": { "version": "..." } } }
```

**校验规则：**

- `baseUrl` 必填、可解析、协议在白名单（`http`/`https`）内；
- 保存前可选做一次连通性探测，失败仅告警不阻断（允许先存后通）；
- `authToken` 为空表示不带鉴权头；非空则 AES 加密入库，回显恒为 `******`。

---

## 2.3 AiChatController

### 路径前缀：`/api/ai`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/models` | 模型清单（代理 opencode `GET /api/model`，标注 `isFree`） | `onlyFree`(可选) |
| GET | `/models/default` | 默认模型（配置优先，其次 opencode `GET /api/model/default`） | — |
| POST | `/session` | 新建会话（代理 opencode `POST /api/session`，落库映射） | CreateSessionDTO |
| GET | `/session/list` | 本地会话列表（当前用户） | `pageNum,pageSize` |
| GET | `/session/{id}/messages` | 会话消息（本地库） | `id` |
| POST | `/session/{id}/model` | 切换会话模型（代理 opencode `POST /api/session/{key}/model`） | ModelRefDTO |
| DELETE | `/session/{id}` | 删除会话（本地逻辑删 + 尽力删 opencode 会话） | `id` |
| POST | `/chat` | **非流式**对话：发消息→等待完成→返回助手文本 | ChatRequest |
| POST | `/chat/stream` | **流式**对话：返回 `text/event-stream`（SseEmitter） | ChatRequest |
| POST | `/chat/{id}/stop` | 中断生成（代理 opencode `POST /api/session/{key}/interrupt`） | `id` |

---

## 2.4 核心接口详细设计

### 2.4.1 GET `/api/ai/models` — 模型清单（含免费标记）

**后端处理：**

```
1. 读取生效配置 → baseUrl / authHeader / authToken
2. GET {baseUrl}/api/model
   响应: { location, data: [ Model.Info ] }
3. 过滤 enabled=false；对每个模型计算 isFree
   isFree = (cost == null || cost.length == 0)
            || cost.every(c => (c.input == 0) && (c.output == 0))
4. 映射为 ModelVO，按 isFree 优先、time.released 倒序返回
```

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": [
    {
      "providerId": "opencode",
      "modelId": "big-pickle",
      "name": "Big Pickle",
      "family": "pickle",
      "isFree": true,
      "status": "active",
      "contextLimit": 200000,
      "outputLimit": 32000,
      "costInput": 0,
      "costOutput": 0,
      "released": 1757520000000
    }
  ]
}
```

### 2.4.2 POST `/api/ai/session` — 新建会话

**请求体：**

```json
{ "providerId": "opencode", "modelId": "big-pickle", "title": "新对话" }
```

**后端处理：**

```
1. GET {baseUrl}/api/model/default （若未传模型）
2. POST {baseUrl}/api/session
   body: { "title": title, "model": { "providerID": providerId, "id": modelId } }
   响应: { data: Session.Info }   → sessionKey = data.id
3. INSERT ai_chat_session(session_key, provider_id, model_id, model_name, user_id, last_time)
4. 返回 { id: 本地id, sessionKey, providerId, modelId }
```

### 2.4.3 POST `/api/ai/chat` — 非流式对话（兜底）

```
1. 校验会话归属；INSERT ai_chat_message(role=user, status=1)
2. POST {baseUrl}/api/session/{sessionKey}/prompt  body: { "text": content }
3. 轮询 GET {baseUrl}/api/session/{sessionKey}/message?order=asc
   → 取最后一条 type=assistant 且 time.completed 已置位的消息
   → 提取 content[].type=="text" 拼接为文本
   （轮询上限 = readTimeoutMs，间隔 500ms）
4. INSERT ai_chat_message(role=assistant, content, tokens, cost, finish, status=1)
5. 返回 { content, providerId, modelId }
```

### 2.4.4 POST `/api/ai/chat/stream` — 流式对话（SSE）

**响应头：** `Content-Type: text/event-stream;charset=UTF-8`

**SSE 事件协议（自定义）：**

```
event: start
data: {"sessionId":12,"sessionKey":"ses_xxx"}

event: delta
data: {"text":"你"}

event: delta
data: {"text":"好"}

event: done
data: {"content":"你好","finish":"stop","tokensOut":12}

event: error
data: {"message":"opencode 不可达"}
```

**后端实现（方案 A：事件流）：**

```
1. SseEmitter emitter = new SseEmitter(readTimeoutMs + 5000L)
2. 开启子线程：
   a. POST {baseUrl}/api/session/{sessionKey}/prompt  (发送用户消息)
   b. 连接 GET {baseUrl}/api/event （复用一条事件流，或按会话临时订阅）
   c. 按 sessionKey 过滤 assistant 文本增量事件 → emitter.send(delta)
   d. 收到完成/空闲事件 → 聚合文本写入 ai_chat_message → emitter.send(done) → complete()
3. 超时/异常 → emitter.send(error) → completeWithError()
```

> **事件名需实现时核对**：用 `opencode api get /api/event` 确认 assistant 增量的 `event` 名称与 `data` 结构；本设计不写死字段。

**后端实现（方案 B：轮询兜底，推荐先做）：**

```
1. 发送 prompt 后，每 300~500ms GET /api/session/{key}/message?order=asc
2. 记录已推送长度 lastLen；assistant 文本变化部分作为 delta 推送
3. 检测到 time.completed → 推送 done
```

先落地方案 B（稳定、无需依赖事件 schema），后续再切方案 A 降低延迟。

---

## 2.5 DTO / VO

```java
// ChatRequest
class ChatRequest {
    Long sessionId;        // 本地会话id（为空则后端自动新建）
    String content;        // 用户输入
    String providerId;     // 可选：覆盖模型
    String modelId;
}

// ModelVO
class ModelVO {
    String providerId; String modelId; String name; String family;
    Boolean isFree; String status;
    Integer contextLimit; Integer outputLimit;
    BigDecimal costInput; BigDecimal costOutput;
    Long released;
}

// OpenCodeConfigDTO（见 2.2）
```

---

## 2.6 OpenCodeClient（适配层）

放 `com.know.knowboot.client.ai.OpenCodeClient`，基于 hutool `HttpRequest` 封装：

```java
@Component
public class OpenCodeClient {
    /** GET {base}/api/info */
    public JSONObject info(OpenCodeConfig cfg)

    /** GET {base}/api/model → List<ModelVO> */
    public List<ModelVO> listModels(OpenCodeConfig cfg)

    /** GET {base}/api/model/default */
    public ModelVO defaultModel(OpenCodeConfig cfg)

    /** POST {base}/api/session  body:{title,model} → sessionKey */
    public String createSession(OpenCodeConfig cfg, String title, String providerId, String modelId)

    /** POST {base}/api/session/{key}/prompt  body:{text} */
    public void prompt(OpenCodeConfig cfg, String sessionKey, String text)

    /** GET {base}/api/session/{key}/message?order=asc → 消息数组 */
    public JSONArray listMessages(OpenCodeConfig cfg, String sessionKey)

    /** POST {base}/api/session/{key}/model  body:{providerID,id} */
    public void switchModel(OpenCodeConfig cfg, String sessionKey, String providerId, String modelId)

    /** POST {base}/api/session/{key}/interrupt */
    public void interrupt(OpenCodeConfig cfg, String sessionKey)

    /** DELETE {base}/api/session/{key} */
    public void deleteSession(OpenCodeConfig cfg, String sessionKey)

    /** POST {base}/api/experimental/generate  body:{prompt,model}（无会话一次性生成，可选） */
    public String generate(OpenCodeConfig cfg, String prompt, String providerId, String modelId)
}
```

统一约定：

- 所有请求注入 `authHeader: <authToken>`（若 token 非空）；
- 统一超时：连接 `connectTimeoutMs`，读取 `readTimeoutMs`；
- opencode 错误体（`*ErrorEncoded`）→ 转换为业务异常并携带原始 msg；
- 记录调用日志（脱敏，不含 token 与完整 prompt）。

---

## 2.7 Service 层

```java
public interface IAiConfigService {
    OpenCodeConfig getEffective();          // 有效配置（DB优先，yml兜底）
    OpenCodeConfigDTO get();
    boolean save(OpenCodeConfigDTO dto);
    Map<String,Object> test(OpenCodeConfigDTO dto);
}

public interface IAiChatService {
    List<ModelVO> listModels(boolean onlyFree);
    ModelVO defaultModel();
    AiChatSession createSession(CreateSessionDTO dto, Long userId);
    IPage<AiChatSession> pageSessions(Long userId, int pageNum, int pageSize);
    List<AiChatMessage> listMessages(Long sessionId, Long userId);
    boolean switchModel(Long sessionId, String providerId, String modelId, Long userId);
    boolean deleteSession(Long sessionId, Long userId);
    ChatResult chat(ChatRequest req, Long userId);                 // 非流式
    SseEmitter chatStream(ChatRequest req, Long userId);            // 流式
    boolean stop(Long sessionId, Long userId);
}
```

`AiChatServiceImpl` 关键点：

- `@Transactional(rollbackFor = Exception.class)` 包裹"用户消息入库 + 助手消息入库"；
- 助手消息先以 `status=0(生成中)` 占位，完成后更新为 `1`，失败置 `2`；
- 会话 `last_time`、`message_count` 在每条消息后更新；
- 调用 opencode 失败时抛出业务异常，前端统一提示。

---

## 2.8 鉴权与安全

| 项 | 处理 |
|----|------|
| 前端鉴权 | 复用系统 `token`（请求头 `token`），单例模式下由 `KnowBootSystemApplication` 的登录拦截统一处理 |
| 微服务 | 网关 `/ai/** → lb://ai`；`NotLogin` 按需标注公开端点（本轮全部需登录） |
| 配置接口 | `PUT /api/ai/config` 与 `/test` 仅管理员可访问（复用现有权限体系） |
| SSRF | `baseUrl` 协议白名单 + 禁止私网段（可配置开关，开发期放开） |
| 密钥 | `authToken` AES 加密存储、回显脱敏、日志脱敏 |
| 限流 | 复用 `know.rateLimiter`（父 pom 已有）；对 `/chat*` 增加单用户并发限制 |

---

## 2.9 与 Python AI 桩接口的关系

`know-python/app/routers/ai.py` 的 `/ai/chat`、`/ai/models` 为占位实现，本轮**不复用**。前端 `src/api/python/ai.ts` 与 `/python` 服务映射保留，后续如需 Python 侧推理能力再打通，避免重复建设。

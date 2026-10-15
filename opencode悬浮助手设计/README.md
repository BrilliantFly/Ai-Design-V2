# opencode 悬浮助手设计方案 V1

> 创建日期：2026-10-13
> 版本：V1.0（首版设计）
> 状态：设计稿（待评审）
> 范围：后端 `know-boot` 新增 `know-boot-ai` 模块 + `know-vue`（后台管理端）+ `know-uniapp`（移动端）
> 交付形态：先设计（本目录），评审通过后进入实现计划

---

## 1. 背景

项目需要在前端（Vue 管理端、uni-app 移动端）提供一个**随时可唤起的 AI 对话入口**：

- 页面右下角显示一个**悬浮图标**，点击展开对话框，直接与 AI 沟通；
- AI 能力统一由 **opencode** 提供（opencode 自身以 HTTP API 暴露模型、会话、消息、事件流）；
- 优先使用 **opencode 内置的免费模型**（OpenCode Zen provider，`cost.input=0 && cost.output=0`）；
- 管理员可配置 opencode 访问地址 + 选择免费模型；
- 前端不直连、不持有密钥，全部经后端统一代理。

### 与既有「AI对话悬浮助手」方案的区别

本项目下已存在 [AI对话悬浮助手](../AI对话悬浮助手/README.md) 方案（2026-10-11）。本方案与之差异：

| 维度 | 既有方案 | 本方案 |
|------|---------|--------|
| opencode API 路径 | 使用近似路径 `/api/session/{id}/prompt`、`/api/event` | 使用**经核实的真实路径** `/session/:id/message`、`/event`，与 opencode `serve` 实际暴露一致 |
| 免费模型来源 | 笼统「cost=0」，未点名 provider | 明确以 **OpenCode Zen** 内置免费模型为主，附 OpenRouter/Gemini/Ollama 备选 |
| cost 字段结构 | 视为数组 | 修正为**对象**（`cost.input` / `cost.output` / `cost.reasoning` …，USD/百万 token） |
| 流式事件 | 笼统「事件名待核对」 | 明确订阅 `message.part.delta`（`{field:"text", delta}`）拿增量 |
| 会话发送 | 单一 prompt 接口 | 区分 **阻塞** `POST /session/:id/message` 与 **非阻塞** `POST /session/:id/prompt_async` |

---

## 2. 设计目标

1. **opencode 作为唯一 AI 执行层**：后端封装 opencode HTTP API（`/session`、`/session/:id/message`、`/session/:id/prompt_async`、`/event`、`/api/model`）。
2. **可配置多 provider 模型库**：除 OpenCode Zen 内置免费模型外，管理员可接入 OpenAI、OpenRouter、Google Gemini、Anthropic、Mistral、Groq、Ollama（本地）及自定义 OpenAI 兼容服务，凭证经后端托管并同步到 opencode（见 [06-模型库配置设计](./06-模型库配置设计.md)）。
3. **免费模型优先**：默认使用 OpenCode Zen 内置免费模型（`space-bunny-free` 等），按 `cost.input===0 && cost.output===0` 识别并打「免费」标签；管理员可在模型库中启用/禁用任意模型。
4. **可配置访问地址**：在「AI 助手设置」页填写 opencode 服务地址（+ 可选 HTTP Basic 鉴权），保存入库，支持**连通性测试**。
5. **悬浮入口**：`know-vue` 与 `know-uniapp` 均显示**可拖动悬浮图标**，点击展开/收起对话框。
6. **流式对话**：Web / H5 走 SSE 增量输出（订阅 `/event` 的 `message.part.delta`）；App / 小程序按能力降级为一次性返回。
7. **会话与历史**：会话、消息本地落库（`ai_` 前缀），支持列表、续聊、清空。
8. **安全**：密钥/地址经后端保管，前端只持有业务 token；地址做协议/白名单校验，防 SSRF。

---

## 3. 整体架构

```
┌──────────────────────────┐        ┌──────────────────────────┐
│ know-vue (管理端)         │        │ know-uniapp (移动端)      │
│  悬浮球 + 对话抽屉        │        │  悬浮球 + 对话弹层        │
└────────────┬─────────────┘        └────────────┬─────────────┘
             │  /api/ai/*  (header: token)        │
             └──────────────────┬─────────────────┘
                                ▼
                ┌───────────────────────────────┐
                │ know-boot-ai (Java 新模块)      │
                │  AiConfigController  (配置)     │
                │  AiChatController    (模型/会话)│
                │  OpenCodeClient      (适配层)   │
                │  SseEmitter          (流式转发) │
                └───────┬─────────────────────────┘
                        │ HTTP(+SSE)
                        ▼
             ┌───────────────────────────────┐
             │ opencode serve (baseUrl 可配) │
             │  默认 http://127.0.0.1:4096    │
             │  /session  /event  /api/model │
             └───────┬───────────────────────┘
                     ▼
        OpenCode Zen 免费模型（默认）
        OpenRouter / Gemini / Ollama（备选）
```

关键点：

- **前端 → 后端**：走既有 `/api` 代理（Vue 端 `VITE_PROXY`，uni-app 端 `config.baseUrl`），无需新增代理规则；新增的只是 `/api/ai/**` 路径。
- **后端 → opencode**：`OpenCodeClient` 统一拼装 `baseUrl + 路径`，注入可选 HTTP Basic 鉴权头；`baseUrl` 来自配置（DB 优先，`application.yml` 兜底）。
- **流式**：后端用 Spring MVC 的 `SseEmitter` 对外推流；对内消费 opencode `GET /event` 事件流，过滤 `message.part.delta` 转发文本增量。

---

## 4. 关键设计取舍

| # | 议题 | 决策 | 理由 |
|---|------|------|------|
| 1 | AI 网关落点 | Java `know-boot-ai` 新模块 | 与业务系统共用 token/鉴权、DB、AjaxResult 规范；前端已有 `/api` 代理 |
| 2 | 访问地址语义 | opencode **服务地址**，后端统一代理 | 密钥不下发前端；可做白名单/超时/限流 |
| 3 | 免费模型判定 | `cost.input===0 && cost.output===0` | opencode `Model.Info.cost` 为 USD/百万 token 的对象 |
| 4 | 免费模型来源 | 默认 OpenCode Zen 内置免费模型 | 开箱即用，无需额外申请 API Key |
| 5 | 会话发送方式 | 默认 `POST /session/:id/prompt_async`（非阻塞）+ 订阅 `/event` | 非阻塞立即返回 204，文本增量由事件流推送，适合 SSE 转发 |
| 6 | 流式方案 | `SseEmitter` 对外 + opencode `/event` 的 `message.part.delta` 对内 | 增量事件名已核实，无需兜底轮询 |
| 7 | 会话归属 | 本地 `ai_chat_session` 映射 opencode `sessionID` | 便于分用户、分模型、历史检索与审计 |
| 8 | 消息落库 | 后端在助手消息完成后写入 `ai_chat_message` | 历史不依赖 opencode 是否留存；降低耦合 |
| 9 | 悬浮入口挂载 | Vue 挂 `layout`；uni-app 用 easycom 组件在各页引入 | 匹配两端既有渲染模型 |
| 10 | 移动端流式 | H5 `fetch` 流 / App `uni.request enableChunked` / 小程序降级 | 跨端能力不一致 |

---

## 5. 模块落位

```
know-boot/
├── pom.xml                         # <modules> 增加 know-boot-ai
└── know-boot-ai/                   # 新增模块（端口默认 8084）
    ├── pom.xml
    └── src/main/java/com/know/knowboot/
        ├── KnowBootAiApplication.java      # 微服务独立启动类
        ├── config/
        │   ├── AiSchemaMigration.java      # 建表 + 种子（ai_ 前缀）
        │   ├── OpenCodeProperties.java     # know.opencode.* 配置
        │   ├── AiWebConfig.java            # CORS / Sse 线程池
        │   └── JacksonConfig.java
        ├── client/
        │   └── OpenCodeClient.java         # opencode HTTP 适配（含 SSE）
        ├── controller/ai/
        │   ├── AiConfigController.java     # /api/ai/config*
        │   └── AiChatController.java       # /api/ai/models|session|chat
        ├── dto/ai/                          # ChatRequest / ModelVO / SessionVO / OpenCodeConfigDTO
        ├── entity/ai/                       # AiOpenCodeConfig / AiChatSession / AiChatMessage
        ├── mapper/ai/                       # *Mapper (IBaseMapper)
        └── service/ai/                      # IAiConfigService / IAiChatService (+impl)
    └── src/main/resources/application.yml
```

规则对齐：

- 建表：`@PostConstruct + JdbcTemplate`，`tableExists` / `ensureColumnExists` 模式（同 `BizSchemaMigration`）。
- 统一返回：`AjaxResult<T>`（`com.know.knowboot.core`），`code=0/1` 均视为成功（与前端拦截器一致）。
- 实体：`@TableName`、`@TableLogic`、`create_by/create_time/update_by/update_time/del_flag`。
- Mapper：`extends IBaseMapper<T>`，放 `mapper.ai.*`；单体聚合 `@MapperScan("com.know.*.mapper")` 可扫到。

---

## 6. 双模式启动（对齐 know-boot）

| 模式 | 启动方式 | 说明 |
|------|---------|------|
| 单例 standalone | `KnowBootSystemApplication` 聚合启动（扫 `com.know` 全包） | AI 控制器随主服务一起在 **8082** 暴露，前端零改动 |
| 微服务 microservice | `know-boot-ai` 独立 `java -jar`，端口 8084 | Nacos 注册；网关新增 `Path=/ai/** → lb://ai`（需在网关配置补路由） |

> 开发期默认 standalone：`/api/ai/**` 由 8082 承载，Vue 端 `VITE_PROXY=[["/api","http://localhost:8082"]]` 即可。

---

## 7. 配置项（`know.opencode`）

```yaml
know:
  opencode:
    # 兜底地址（DB 中 ai_opencode_config 优先）
    base-url: http://127.0.0.1:4096
    # 可选：opencode serve 的 HTTP Basic 鉴权
    basic-username: ''
    basic-password: ''
    connect-timeout-ms: 5000
    read-timeout-ms: 120000
    # 允许配置的地址协议白名单（防 SSRF）
    allowed-schemes: [http, https]
    # 默认免费模型（OpenCode Zen 内置）
    default-free-model: opencode/space-bunny-free
```

---

## 8. 文件索引

| 文件 | 内容 |
|------|------|
| [01-opencode免费模型接口.md](./01-opencode免费模型接口.md) | opencode HTTP API 真实路径、免费模型识别、OpenCode Zen 内置免费模型清单 |
| [02-后端网关设计.md](./02-后端网关设计.md) | `OpenCodeClient` 适配、`/api/ai/**` 接口、SSE 流式转发、建表 SQL |
| [03-Vue悬浮按钮设计.md](./03-Vue悬浮按钮设计.md) | know-vue 悬浮图标、对话抽屉、模型选择、设置页 |
| [04-uniapp悬浮按钮设计.md](./04-uniapp悬浮按钮设计.md) | know-uniapp 悬浮球、对话弹层、跨端流式降级 |
| [05-数据流程与交互.md](./05-数据流程与交互.md) | 端到端流程（配置 → 选模型 → 会话 → 流式对话 → 落库） |
| [06-模型库配置设计.md](./06-模型库配置设计.md) | 多 provider 接入（OpenAI/OpenRouter/Gemini/Anthropic/Ollama/自定义）、模型库管理、凭证同步到 opencode |
| [app/index.html](./app/index.html) | 悬浮图标 + 对话框静态原型（含模型库配置原型） |

---

## 9. 边界与风险（待确认项）

1. **opencode 运行形态**：需以 `opencode serve` 常驻并暴露 HTTP；默认端口 `4096`，是否启用 HTTP Basic 鉴权由目标环境决定。
2. **OpenCode Zen 可用性**：Zen 内置免费模型依赖 `opencode.ai/zen` 端点，需确认目标环境可访问外网；内网部署需改用 Ollama / 本地模型。
3. **事件流字段**：`/event` 的 `message.part.delta` 事件结构已在官方文档核实（`{messageID, partID, field:"text", delta}`），实现时仍建议用 `curl /event` 实测一次。
4. **小程序流式**：`uni.request` 无通用分块能力 → 小程序端固定走非流式（`POST /session/:id/message` 阻塞返回）。
5. **安全**：`baseUrl` 需协议白名单 + 内网限制；HTTP Basic 密码用 AES 存储、返回前端时脱敏。
6. **限流/并发**：单实例 opencode 会话有限，需限制并发会话数与消息频率。
7. **自定义 provider config 写入**：自定义 OpenAI 兼容 / 本地 provider 的 `baseURL` 需写入 opencode 的 `~/.config/opencode/opencode.json`；仅后端与 opencode 同机时可自动写，分离部署需导出配置片段人工粘贴（见 [06-模型库配置设计](./06-模型库配置设计.md) §5）。
8. **付费模型成本**：启用 OpenAI/Anthropic 等付费 provider 后会产生费用，建议模型库默认禁用付费模型、需管理员显式启用，并在对话页标注费用。
9. **本轮不做**：多模态（图片/文件上传）、工具调用展示、多轮记忆压缩、成本统计看板。

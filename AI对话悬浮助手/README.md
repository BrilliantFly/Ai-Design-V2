# AI 对话悬浮助手设计方案 V1

> 创建日期：2026-10-11
> 版本：V1.0（首版设计）
> 状态：设计稿（待评审）
> 范围：后端 `know-boot` 新增 AI 模块 + `know-vue`（后台管理端）+ `know-uniapp`（移动端）
> 交付形态：先设计（本目录），评审通过后进入实现计划

---

## 1. 背景

项目需要在前端（Vue 管理端、uni-app 移动端）提供一个**随时可唤起的 AI 对话入口**：

- 页面右下角显示一个**悬浮图标**，点击展开对话框，直接与 AI 沟通；
- AI 能力统一由 **opencode** 提供（opencode 自身以 HTTP API 暴露模型、会话、消息、事件流）；
- 管理员**配置 opencode 访问地址**后，即可**选择免费模型**进行对话（opencode 模型清单中含 `cost=0` 的免费模型）；
- 前端不直连、不持有密钥，全部经后端统一代理。

现状（已核对代码）：

| 层 | 现状 |
|----|------|
| 后端 | `know-boot` 多模块（`system` 8082 / `plan` 8083 / `biz` / `knowledge` / `camera` …），统一 `AjaxResult`、MyBatis-Plus、`@PostConstruct + JdbcTemplate` 建表模式 |
| Python | `know-python`（FastAPI）有 `/ai/chat`、`/ai/models` 桩接口，但 AI 能力将改由 Java 模块承接（本轮决策） |
| 前端 Vue | `know-vue`（Vue3 + TSX + ant-design-vue + Pinia + axios），布局入口 `src/layout/index.tsx` |
| 前端移动 | `know-uniapp`（uni-app + Vue3），请求封装 `src/utils/request`，服务映射 `serviceMap.python=/python` |

> 本轮决策：**AI 网关落在 Java `know-boot` 新模块**（`know-boot-ai`），Python 侧 AI 桩接口暂不复用。

---

## 2. 设计目标

1. **opencode 作为唯一 AI 提供方**：后端封装 opencode HTTP API（`/api/info`、`/api/model`、`/api/model/default`、`/api/session`、`/api/session/{id}/prompt`、`/api/session/{id}/message`、`/api/event`）。
2. **可配置访问地址**：在「AI 助手设置」页填写 opencode 服务地址（+ 可选鉴权），保存入库，支持**连通性测试**。
3. **免费模型选择**：拉取 opencode 模型清单，按 `cost` 识别免费模型并打标，下拉选择；默认选中免费模型。
4. **悬浮入口**：`know-vue` 与 `know-uniapp` 均显示**可拖动悬浮图标**，点击展开/收起对话框。
5. **流式对话**：Web / H5 走 SSE 增量输出；App / 小程序按能力降级为一次性返回。
6. **会话与历史**：会话、消息本地落库（`ai_` 前缀），支持列表、续聊、清空。
7. **安全**：密钥/地址经后端保管，前端只持有业务 token；地址做协议/白名单校验，防 SSRF。

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
             │ opencode server (baseUrl 可配) │
             │  /api/model  /api/session ...  │
             └───────┬─────────────────────────┘
                     ▼
        免费模型 / 付费模型 providers（opencode 已配置）
```

关键点：

- **前端 → 后端**：走既有 `/api` 代理（Vue 端 `VITE_PROXY`，uni-app 端 `config.baseUrl`），无需新增代理规则；新增的只是 `/api/ai/**` 路径。
- **后端 → opencode**：`OpenCodeClient` 统一拼装 `baseUrl + 路径`，注入可选鉴权头；`baseUrl` 来自配置（DB/缓存优先，`application.yml` 兜底）。
- **流式**：后端用 Spring MVC 的 `SseEmitter` 对外推流；对内消费 opencode `/api/event` 事件流（或退化为轮询 `message`）。

---

## 4. 关键设计取舍

| # | 议题 | 决策 | 理由 |
|---|------|------|------|
| 1 | AI 网关落点 | Java `know-boot-ai` 新模块 | 与业务系统共用 token/鉴权、DB、AjaxResult 规范；前端已有 `/api` 代理 |
| 2 | 访问地址语义 | opencode **服务地址**，后端统一代理 | 密钥不下发前端；可做白名单/超时/限流 |
| 3 | 免费模型判定 | `cost` 数组为空或所有档位 `input=0 && output=0` | opencode `Model.Info.cost` 为 USD/百万 token 数组 |
| 4 | 流式方案 | `SseEmitter` 对外 + opencode `/api/event` 对内；**轮询为兜底** | 事件名依赖 opencode 版本，先用轮询可稳定跑通，再切事件流 |
| 5 | 会话归属 | 本地 `ai_chat_session` 映射 opencode `sessionID` | 便于分用户、分模型、历史检索与审计 |
| 6 | 消息落库 | 后端在助手完成后写入 `ai_chat_message` | 历史不依赖 opencode 是否留存；降低耦合 |
| 7 | 悬浮入口挂载 | Vue 挂 `layout`；uni-app 用 easycom 组件在各页引入 | 匹配两端既有渲染模型 |
| 8 | 移动端流式 | H5 `fetch` 流 / App `uni.request enableChunked` / 小程序降级 | 跨端能力不一致 |

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
    # 可选：opencode 配对鉴权 token（为空则不带鉴权头）
    auth-token: ''
    # 可选：自定义鉴权头名（默认 Authorization: Bearer <token>）
    auth-header: Authorization
    connect-timeout-ms: 5000
    read-timeout-ms: 120000
    # 允许配置的地址协议白名单（防 SSRF）
    allowed-schemes: [http, https]
```

---

## 8. 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据表设计（配置表 + 会话表 + 消息表）与建表 SQL |
| [02-backend-api.md](./02-backend-api.md) | 后端接口、`OpenCodeClient` 适配、SSE 流式实现 |
| [03-frontend-vue.md](./03-frontend-vue.md) | know-vue 悬浮图标、对话抽屉、模型选择、设置页 |
| [04-frontend-uniapp.md](./04-frontend-uniapp.md) | know-uniapp 悬浮球、对话弹层、跨端流式降级 |
| [05-data-flow.md](./05-data-flow.md) | 端到端流程（配置 → 选模型 → 会话 → 流式对话 → 落库） |
| [app/index.html](./app/index.html) | 悬浮图标 + 对话框静态原型 |

---

## 9. 边界与风险（待确认项）

1. **opencode 运行形态**：需以 `opencode serve` 常驻并暴露 HTTP；默认端口/是否需配对鉴权需在目标环境确认。
2. **事件流字段**：`/api/event` 返回编码后的事件（`V2EventEncoded`），assistant 文本增量的确切事件名需实现时用 `opencode api get /api/event` 核对；**兜底采用轮询 `/{id}/message`**。
3. **免费模型界定**：`cost=0` 会随 provider 调整；建议同时保留"手动标记常用模型"。
4. **小程序流式**：`uni.request` 无通用分块能力 → 小程序端固定走非流式。
5. **安全**：`baseUrl` 需协议白名单 + 内网限制；鉴权 token 用 AES 存储、返回前端时脱敏。
6. **限流/并发**：单实例 opencode 会话有限，需限制并发会话数与消息频率。
7. **本轮不做**：多模态（图片/文件上传）、工具调用展示、多轮记忆压缩、成本统计看板。

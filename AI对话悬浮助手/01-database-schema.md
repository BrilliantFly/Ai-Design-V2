# 01 - 数据库表结构设计（AI 对话悬浮助手）

## 1.0 库与命名

- 库：远程开发库 `101.37.83.88:3306/know_boot_v1`（与 biz 一致）
- 前缀：`ai_`
- 主键：`bigint`（自增或雪花，视现有实体风格）
- 时间：`bigint` 毫秒时间戳（对齐 `biz_*` 表）
- 逻辑删除：`del_flag tinyint default 0`

---

## 1.1 `ai_opencode_config`（opencode 接入配置）

> 单行配置为主（`id=1`），预留多行以支持多环境/多地址切换。同一时刻取 `status=1` 的最新一行。

| 列 | 类型 | 说明 |
|----|------|------|
| id | bigint PK | 主键 |
| name | varchar(64) | 配置名（如「本地 opencode」「内网 opencode」） |
| base_url | varchar(255) | opencode 服务地址，如 `http://127.0.0.1:4096` |
| auth_token | varchar(512) | 可选鉴权 token（**AES 加密存储**） |
| auth_header | varchar(64) | 鉴权头名，默认 `Authorization` |
| default_provider_id | varchar(64) | 默认模型 providerID |
| default_model_id | varchar(128) | 默认模型 modelID |
| connect_timeout_ms | int | 连接超时，默认 5000 |
| read_timeout_ms | int | 读取超时，默认 120000 |
| status | tinyint | 状态(0停用/1启用) |
| remark | varchar(255) | 备注 |
| create_by / create_time | bigint / bigint | 创建信息 |
| update_by / update_time | bigint / bigint | 更新信息 |
| del_flag | tinyint | 逻辑删除 |

---

## 1.2 `ai_chat_session`（对话会话）

| 列 | 类型 | 说明 |
|----|------|------|
| id | bigint PK | 本地会话ID |
| user_id | bigint | 所属用户 |
| session_key | varchar(64) | opencode `sessionID` 映射（唯一） |
| title | varchar(128) | 会话标题（默认取首条提问摘要） |
| provider_id | varchar(64) | 当前模型 providerID |
| model_id | varchar(128) | 当前模型 modelID |
| model_name | varchar(128) | 模型展示名快照 |
| message_count | int | 消息数（冗余统计） |
| last_time | bigint | 最后活跃时间 |
| status | tinyint | 状态(0关闭/1进行中) |
| create_by / create_time | bigint / bigint | 创建信息 |
| update_by / update_time | bigint / bigint | 更新信息 |
| del_flag | tinyint | 逻辑删除 |

约束：`UNIQUE KEY uk_ai_session_key (session_key)`；`KEY idx_ai_session_user (user_id, last_time)`。

---

## 1.3 `ai_chat_message`（对话消息）

| 列 | 类型 | 说明 |
|----|------|------|
| id | bigint PK | 主键 |
| session_id | bigint | 归属会话 `ai_chat_session.id` |
| session_key | varchar(64) | opencode sessionID（冗余，便于对账） |
| msg_id | varchar(64) | opencode messageID（去重/对账，可空） |
| role | varchar(16) | 角色：`user` / `assistant` / `system` |
| content | mediumtext | 文本内容 |
| reasoning | mediumtext | 思维链（可选，若模型返回） |
| provider_id | varchar(64) | 该条消息所用的模型 providerID |
| model_id | varchar(128) | 该条消息所用的 modelID |
| tokens_in | int | 输入 token（可选） |
| tokens_out | int | 输出 token（可选） |
| cost | decimal(12,6) | 花费 USD（可选，免费模型为 0） |
| finish | varchar(16) | 结束原因：`stop/length/error/...` |
| status | tinyint | 状态(0生成中/1完成/2失败) |
| error | varchar(512) | 失败信息 |
| create_time | bigint | 创建时间 |
| del_flag | tinyint | 逻辑删除 |

约束：`KEY idx_ai_msg_session (session_id, create_time)`；`KEY idx_ai_msg_open (session_key, msg_id)`。

---

## 1.4 建表 SQL（`AiSchemaMigration` 落库内容）

> 在 `AiSchemaMigration#migrateSchema`（`@PostConstruct`）中按 `tableExists` 判断后执行，风格对齐 `BizSchemaMigration`。

```sql
CREATE TABLE `ai_opencode_config` (
  `id` bigint NOT NULL COMMENT '主键',
  `name` varchar(64) DEFAULT NULL COMMENT '配置名',
  `base_url` varchar(255) NOT NULL COMMENT 'opencode服务地址',
  `auth_token` varchar(512) DEFAULT NULL COMMENT '鉴权token(AES加密)',
  `auth_header` varchar(64) DEFAULT 'Authorization' COMMENT '鉴权头名',
  `default_provider_id` varchar(64) DEFAULT NULL COMMENT '默认providerID',
  `default_model_id` varchar(128) DEFAULT NULL COMMENT '默认modelID',
  `connect_timeout_ms` int DEFAULT 5000 COMMENT '连接超时ms',
  `read_timeout_ms` int DEFAULT 120000 COMMENT '读取超时ms',
  `status` tinyint DEFAULT 1 COMMENT '状态(0停用/1启用)',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_by` bigint DEFAULT NULL COMMENT '创建人',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '更新人',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `del_flag` tinyint DEFAULT 0 COMMENT '删除标记(0正常/1删除)',
  PRIMARY KEY (`id`),
  KEY `idx_ai_cfg_status` (`status`, `del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='opencode接入配置';

CREATE TABLE `ai_chat_session` (
  `id` bigint NOT NULL COMMENT '主键',
  `user_id` bigint DEFAULT NULL COMMENT '所属用户',
  `session_key` varchar(64) NOT NULL COMMENT 'opencode sessionID',
  `title` varchar(128) DEFAULT NULL COMMENT '会话标题',
  `provider_id` varchar(64) DEFAULT NULL COMMENT '模型providerID',
  `model_id` varchar(128) DEFAULT NULL COMMENT '模型modelID',
  `model_name` varchar(128) DEFAULT NULL COMMENT '模型名快照',
  `message_count` int DEFAULT 0 COMMENT '消息数',
  `last_time` bigint DEFAULT NULL COMMENT '最后活跃时间',
  `status` tinyint DEFAULT 1 COMMENT '状态(0关闭/1进行中)',
  `create_by` bigint DEFAULT NULL COMMENT '创建人',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '更新人',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `del_flag` tinyint DEFAULT 0 COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ai_session_key` (`session_key`),
  KEY `idx_ai_session_user` (`user_id`, `last_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话会话';

CREATE TABLE `ai_chat_message` (
  `id` bigint NOT NULL COMMENT '主键',
  `session_id` bigint NOT NULL COMMENT '会话ID',
  `session_key` varchar(64) DEFAULT NULL COMMENT 'opencode sessionID',
  `msg_id` varchar(64) DEFAULT NULL COMMENT 'opencode messageID',
  `role` varchar(16) NOT NULL COMMENT '角色(user/assistant/system)',
  `content` mediumtext COMMENT '文本内容',
  `reasoning` mediumtext COMMENT '思维链(可选)',
  `provider_id` varchar(64) DEFAULT NULL COMMENT '模型providerID',
  `model_id` varchar(128) DEFAULT NULL COMMENT '模型modelID',
  `tokens_in` int DEFAULT NULL COMMENT '输入token',
  `tokens_out` int DEFAULT NULL COMMENT '输出token',
  `cost` decimal(12,6) DEFAULT NULL COMMENT '花费USD',
  `finish` varchar(16) DEFAULT NULL COMMENT '结束原因',
  `status` tinyint DEFAULT 0 COMMENT '状态(0生成中/1完成/2失败)',
  `error` varchar(512) DEFAULT NULL COMMENT '失败信息',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `del_flag` tinyint DEFAULT 0 COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_ai_msg_session` (`session_id`, `create_time`),
  KEY `idx_ai_msg_open` (`session_key`, `msg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话消息';
```

---

## 1.5 种子数据

```sql
-- 默认配置（地址留空，由管理员在「AI 助手设置」页填写）
INSERT INTO ai_opencode_config (id, name, base_url, auth_header, connect_timeout_ms, read_timeout_ms, status, remark, create_time)
VALUES (1, '默认', '', 'Authorization', 5000, 120000, 1, 'opencode 接入配置，请在设置页填写访问地址', UNIX_TIMESTAMP()*1000);
```

> 说明：`base_url` 留空时，后端读取 `application.yml` 的 `know.opencode.base-url` 兜底。

---

## 1.6 与 opencode 数据的关系

- **不复制** opencode 的模型/事件表；模型每次实时拉取（可加 30s 缓存）。
- `ai_chat_session.session_key` = opencode `Session.Info.id`；`ai_chat_message.msg_id` = opencode `Session.Message.ID`（用于去重，不强制）。
- 删除本地会话时可同步删除 opencode 会话（`DELETE /api/session/{id}`），失败不影响本地删除。

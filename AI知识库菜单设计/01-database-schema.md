# 01 —— 数据库 Schema 设计

## 一、表设计原则

- 沿用已有 `kb_` 前缀，与 `kb_knowledge_base`、`kb_document`、`kb_directory` 等保持一致
- 时间字段统一使用 `BIGINT` 毫秒时间戳（参考现有实体）
- 逻辑删除用 `delete_time BIGINT DEFAULT 0`（参考 `@TableLogic` 注解写法）
- 新表只存上传元信息 + 原始文件内容，**复用 `kb_document` 作为正式展示入口**

## 二、新表：kb_uploaded_file

```sql
CREATE TABLE IF NOT EXISTS `kb_uploaded_file` (
  `id`                 BIGINT        NOT NULL AUTO_INCREMENT  COMMENT '主键',
  `original_name`      VARCHAR(255)  NOT NULL                 COMMENT '原始文件名',
  `file_name`          VARCHAR(255)  NOT NULL                 COMMENT '存储文件名(UUID+ext)',
  `file_path`          VARCHAR(500)  NOT NULL                 COMMENT '文件存储路径(相对磁盘或OSS)',
  `file_ext`           VARCHAR(20)   NOT NULL                 COMMENT '扩展名: html / htm / md / markdown',
  `file_content`       LONGTEXT                               COMMENT '文件原始文本内容(上传时解析存入)',
  `file_size`          BIGINT        DEFAULT 0                COMMENT '文件大小(字节)',
  `mime_type`          VARCHAR(100)  DEFAULT NULL             COMMENT 'MIME 类型',
  `knowledge_base_id`  BIGINT        DEFAULT NULL             COMMENT '关联知识库ID(可选,归属到哪个知识库)',
  `document_id`        BIGINT        DEFAULT NULL             COMMENT '解析后生成的 kb_document.id',
  `parse_status`       TINYINT       DEFAULT 0                COMMENT '解析状态: 0待解析 1成功 2失败',
  `parse_error`        VARCHAR(1000) DEFAULT NULL             COMMENT '解析失败原因',
  `source_type`        VARCHAR(20)   DEFAULT 'upload'         COMMENT '来源: upload / import / system',
  `upload_platform`    VARCHAR(20)   DEFAULT NULL             COMMENT '上传端: vue / uniapp-h5 / uniapp-app / uniapp-mp',
  `sort`               INT           DEFAULT 0                COMMENT '排序',
  `status`             TINYINT       DEFAULT 1                COMMENT '状态: 0禁用 1正常',
  `create_by`          BIGINT        DEFAULT NULL             COMMENT '上传人ID',
  `create_time`        BIGINT        DEFAULT NULL             COMMENT '上传时间(毫秒)',
  `update_time`        BIGINT        DEFAULT NULL             COMMENT '更新时间(毫秒)',
  `delete_time`        BIGINT        DEFAULT 0                COMMENT '删除时间(毫秒,0=未删除)',
  PRIMARY KEY (`id`),
  KEY `idx_kb_id`      (`knowledge_base_id`),
  KEY `idx_doc_id`     (`document_id`),
  KEY `idx_create_by`  (`create_by`),
  KEY `idx_parse`      (`parse_status`),
  KEY `idx_create_time`(`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库上传文件表';
```

### 字段说明

| 字段 | 用途 |
|------|------|
| `original_name` | 用户上传时的原始文件名，UI 展示用 |
| `file_name` | 服务端重命名后存储的文件名（如 `a1b2c3d4.html`），防止中文名 / 重名问题 |
| `file_content` | 上传时直接读取文本存入，**HTML 直接是 HTML 源码，MD 是 Markdown 源码** |
| `knowledge_base_id` | 用户上传时选择归属哪个知识库（可选，也可上传后再归类） |
| `document_id` | 解析成功后生成的 `kb_document.id`，文件详情页可直接跳到文档预览 |
| `parse_status` | 0=刚上传等待解析；1=已成功创建 kb_document；2=解析失败（内容为空、扩展名错误等） |
| `upload_platform` | 记录是 Vue 管理端还是 UniApp 哪个平台上传的，便于统计和差异化处理 |

### 文件大小限制建议

| 场景 | 限制 |
|------|------|
| 单个文件 | ≤ 5MB（文本文件通常不会更大） |
| 单次批量上传 | ≤ 20 个文件 |
| Spring Boot 配置 | `spring.servlet.multipart.max-file-size=10MB` / `max-request-size=100MB` |

## 三、不修改现有表

本次设计**不改动**以下表的任何字段，保持向后兼容：

- `kb_knowledge_base`
- `kb_directory`
- `kb_document` （新入库的上传文件会写成 `content_type='richtext'` / `'markdown'`，已被现有 `KbDocument.contentType` 字段支持）
- `kb_quick_note`
- `kb_tag`
- `kb_comment`
- `kb_document_version`
- `kb_document_like`
- `kb_document_favorite`
- `kb_document_share`
- `kb_search_history`
- `kb_image`
- `kb_knowledge_base_member`

## 四、菜单设计

### 4.1 Vue 管理端菜单（sys_menu）

参考现有 `knowledge_menu.sql` 的 ID 分配策略（根菜单 `id=20`，子菜单 `2001~2004`），新增文件管理子菜单放在 `2005`：

| menu_id | parent_id | menu_name | path | component | perms | icon | menu_type | sort |
|---------|-----------|-----------|------|-----------|-------|------|-----------|------|
| 2005 | 20 | 文件管理 | /knowledge/file | knowledge/file | knowledge:file:view | upload | 2 | 5 |
| 20051 | 2005 | 文件上传 | - | - | knowledge:file:upload | - | 3 | 1 |
| 20052 | 2005 | 文件删除 | - | - | knowledge:file:delete | - | 3 | 2 |
| 20053 | 2005 | 文件解析 | - | - | knowledge:file:parse | - | 3 | 3 |

> menu_type：1=目录 2=菜单 3=按钮（参考已有 `knowledge_menu.sql` 中 2001~2004 的写法，20051/20052/20053 是按钮权限）

### 4.2 UniApp 首页快捷入口菜单（sys_menu_config）

参考 `V1_9__sys_menu_config_knowledge.sql`，新增一条「文件导入」配置：

| menu_code | path | sort | sections |
|-----------|------|------|----------|
| file-upload | /pages/knowledge/file-upload/index | 13 | quick |

## 五、完整 SQL 文件

见同目录 [kb_file_upload.sql](./kb_file_upload.sql)（可直接在 MySQL 执行）。

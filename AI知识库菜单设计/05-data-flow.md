# 05 —— 数据流与完整 SQL

## 一、文件上传 → 入库 → 预览 完整数据流

### 1.1 总体时序

```
┌────────┐        ┌────────────────┐        ┌─────────────┐        ┌──────────────┐        ┌────────────┐
│ 用户   │        │ Vue/UniApp     │        │ Spring Boot │        │ MySQL        │        │ 磁盘/OSS   │
└───┬────┘        └──────┬─────────┘        └──────┬──────┘        └──────┬───────┘        └─────┬──────┘
    │ 选择 .html/.md     │                         │                      │                        │
    ├────────────────────▶│                         │                      │                        │
    │                    │                         │                      │                        │
    │                    │ beforeUpload 校验       │                      │                        │
    │                    │ (扩展名 + ≤ 5MB)         │                      │                        │
    │                    │                         │                      │                        │
    │                    │ POST /api/knowledge/file/upload                │                        │
    │                    │ multipart/form-data     │                      │                        │
    │                    ├─────────────────────────▶│                      │                        │
    │                    │                         │ ① 遍历 files         │                        │
    │                    │                         │    UUID 命名          │                        │
    │                    │                         ├───────────────────────▶│                        │
    │                    │                         │                      │ CREATE kb_uploaded_file │
    │                    │                         │                      │ (parse_status=0)       │
    │                    │                         │                      │                        │
    │                    │                         │ ② 存盘               │                        │
    │                    │                         ├────────────────────────────────────────────▶│
    │                    │                         │    Files.write        │                        │
    │                    │                         │    ./upload/...       │                        │
    │                    │                         │                      │                        │
    │                    │                         │ ③ 读文件内容为文本    │                        │
    │                    │                         │    (处理 UTF-8 BOM)   │                        │
    │                    │                         │                      │                        │
    │                    │                         │ ④ 解析入库           │                        │
    │                    │                         │    html → contentType='richtext'               │
    │                    │                         │    md  → contentType='markdown'               │
    │                    │                         ├───────────────────────▶│                        │
    │                    │                         │                      │ INSERT kb_document     │
    │                    │                         │                      │ + UPDATE kb_uploaded_file│
    │                    │                         │                      │   parse_status=1       │
    │                    │                         │                      │   document_id=xxx      │
    │                    │                         │                      │ + kb_knowledge_base    │
    │                    │                         │                      │   doc_count +1        │
    │                    │                         │                      │                        │
    │                    │ ◀───────────────────────┤                      │                        │
    │                    │ { successCount, items } │                      │                        │
    │                    │                         │                      │                        │
    │ ◀──────────────────│ "成功 X 个, 失败 Y 个" │                      │                        │
    │                    │                         │                      │                        │
    │ 点击预览           │                         │                      │                        │
    ├────────────────────▶│                         │                      │                        │
    │                    │ GET /api/knowledge/document/{id}                │                        │
    │                    ├─────────────────────────▶│                      │                        │
    │                    │                         ├───────────────────────▶│                        │
    │                    │ ◀───────────────────────┤                      │                        │
    │                    │ { content, contentType } │                      │                        │
    │                    │                         │                      │                        │
    │                    │ 渲染:                    │                      │                        │
    │                    │ richtext → <iframe> / <rich-text>               │                        │
    │                    │ markdown → marked.parse → v-html / rich-text    │                        │
    │ ◀──────────────────│ 展示预览                │                      │                        │
```

### 1.2 核心业务规则

| 规则 | 说明 |
|------|------|
| 上传 → 解析同事务 | `kb_uploaded_file` 写入后解析，解析失败时 `parse_status=2` 记录原因，**不回滚上传记录**（方便用户重新解析） |
| 文件内容直接存 LONGTEXT | 文本文件 ≤ 5MB，MySQL LONGTEXT 支持 4GB，不会有压力；不依赖文件存盘才能预览 |
| 重上传幂等 | 同文件重新上传 → 生成新记录，旧记录保留（用户可在文件管理页删除） |
| 已解析文件删除 | 同时软删 `kb_uploaded_file` + `kb_document` + `kb_knowledge_base.doc_count - 1` |
| 未解析文件删除 | 仅软删 `kb_uploaded_file` |
| UTF-8 BOM 处理 | `fileContent.replace(/^\uFEFF/, '')` 避免前端预览出现空白字符 |

### 1.3 解析规则（file_ext → contentType 映射）

| file_ext | 转小写后 | 写入 kb_document.contentType | 写入 kb_document.content |
|----------|----------|-------------------------------|--------------------------|
| `.html` / `.htm` | html | `richtext` | HTML 源码（**原样**） |
| `.md` / `.markdown` | md | `markdown` | Markdown 源码（**原样**） |

> **关键决策**：后端只存**原始文本**，不做 MD→HTML 转换。原因：
> 1. 减少后端 Java 依赖（commonmark-java 可不引入）
> 2. 管理端/移动端两端各用自己熟悉的 marked.js 解析，可控性强
> 3. 将来支持其他预览端（小程序、App）统一只需要前端有 marked.js

## 二、完整 SQL 文件

SQL 见同目录 **[kb_file_upload.sql](./kb_file_upload.sql)**，包含：

| 部分 | 说明 |
|------|------|
| ① 建表 | `kb_uploaded_file`（kb_ 前缀，与现有表一致） |
| ② Vue 管理端菜单 | `sys_menu` 根知识管理下新增「文件管理」菜单 + 3 个按钮权限 |
| ③ 角色授权 | `sys_role_menu` 给超级管理员 (role_id=1) 授权 |
| ④ UniApp 首页菜单配置 | `sys_menu_config` 新增「文件导入」快捷入口 |
| ⑤ 测试数据（可选） | 一条示例上传记录 |

### 2.1 SQL 中 ID 分配说明

| 对象 | 分配 ID | 依据 |
|------|---------|------|
| 根菜单父 ID | `parent_id=20` | 现有知识管理根菜单 id=20 |
| 新增菜单 | `id=2005` | 现有子菜单是 2001~2004，顺延 2005 |
| 按钮权限 | `20051` / `20052` / `20053` | 父菜单 id + 两位序号，与现有 knowledge_menu.sql 风格一致 |

### 2.2 执行顺序

```sql
-- 建议按以下顺序执行，避免外键冲突 / 重复插入报错：

-- 1. 建表（独立执行）
source kb_file_upload.sql;  -- 只执行 -- ① 部分

-- 2. 菜单 + 授权（可单独执行，支持 ON DUPLICATE KEY UPDATE 幂等）
--    也可以让后端 Flyway 自动执行（V1_11 之后新增 V1_12__sys_menu_config_fileupload.sql）

-- 3. 角色授权同理，已用 INSERT ... SELECT + ON DUPLICATE KEY UPDATE 保证幂等
```

## 三、后端代码落点速查

| 类型 | 路径 | 类/方法 |
|------|------|---------|
| Entity | `know-boot-knowledge/.../entity/knowledge/` | `KbUploadedFile.java` |
| Mapper | `know-boot-knowledge/.../mapper/knowledge/` | `KbUploadedFileMapper.java` + `.xml` |
| Service | `know-boot-knowledge/.../service/knowledge/` | `IKbFileUploadService` + `KbFileUploadServiceImpl` |
| Controller | `know-boot-knowledge/.../controller/knowledge/` | `KbFileUploadController` |

## 四、前端代码落点速查

| 端 | 路径 | 说明 |
|----|------|------|
| Vue 管理端 | `know-vue/src/api/knowledge/index.ts` | 追加 5 个 API 方法 |
| Vue 管理端 | `know-vue/src/views/knowledge/file/index.vue` | 新增文件管理页 |
| UniApp | `know-uniapp/src/api/knowledge.ts` | 追加 5 个 API 方法 |
| UniApp | `know-uniapp/src/pages/knowledge/file-upload/index.vue` | 上传 + 我的文件列表 |
| UniApp | `know-uniapp/src/pages/knowledge/file-preview/index.vue` | 预览（跨平台条件编译） |
| UniApp | `know-uniapp/src/pages.json` | 注册 2 条新页面路径 |

## 五、变更清单（总览）

| 模块 | 新增 | 修改 | 影响范围 |
|------|------|------|---------|
| MySQL | 1 张表 `kb_uploaded_file` | 0 张表 | 完全向后兼容 |
| Java 后端 | 4 个类 + 1 个 XML | 0 个类 | 仅 know-boot-knowledge |
| Vue 管理端 | 1 个页面 + API 追加 | 0 个页面 | 侧边栏自动多一个菜单 |
| UniApp | 2 个页面 + API 追加 | pages.json | 首页多一个快捷入口 |
| Nginx 配置 | 可选：静态目录映射 | 0 | 若 App 端需 web-view 中转则要配 |

## 六、风险与降级

| 风险 | 影响 | 降级方案 |
|------|------|---------|
| 小程序无法选择本地 HTML/MD | 小程序端上传体验受限 | 引导用户从 H5 / App 上传，或用聊天转发的文件 |
| App 端 web-view 数据 URL 不兼容 | Android 老版本预览白屏 | 后端新增 `/{id}/render` 中转 URL（见 04 五.3） |
| 磁盘满 / 无写权限 | 上传即失败 | parse_status=2 + parse_error，前端提示 |
| KB 不存在 / 被删除 | 上传关联 KB 失败 | knowledgeBaseId 清空，归属到未分类；管理端可重新绑定 |
| 前端 marked 未引入 | MD 预览空白 | build 前加 npm i marked；若无则 fallback 成纯文本显示 |

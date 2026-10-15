# AI 知识库菜单设计方案

> 创建日期：2026-10-13
> 版本：V1.0
> 状态：设计稿
> 关联项目：Ai-Front（know-vue / know-uniapp）、Ai-Service（know-boot-knowledge）

---

## 一、背景

当前系统已具备完整的知识管理基础模块（知识库、目录、文档、小记、标签、版本历史、评论、点赞、收藏、分享、搜索等），`know-boot-knowledge` 后端模块和 Vue/UniApp 前端均已落地。

但现有功能侧重**在线富文本编辑**，缺少**外部文件快速导入**入口。用户需要一种更轻量的方式：直接上传本地 `.html` / `.md` 文件，系统自动解析入库，在 Vue 管理端和 UniApp 移动端均可一键预览。

## 二、设计目标

| 目标 | 说明 |
|------|------|
| 文件上传 | 支持 `.html` / `.htm` / `.md` / `.markdown` 四种扩展名批量上传 |
| 自动入库 | 上传后自动创建对应的 `kb_document` 记录，标题取文件名（去扩展名） |
| 双端预览 | Vue 管理端内嵌预览；UniApp 移动端 HTML 用 `web-view`，MD 用 marked.js 解析 |
| 菜单入口 | Vue 侧边栏新增「文件管理」子菜单；UniApp 首页快捷网格新增入口 + 我的知识库内入口 |
| 一致性 | 新表沿用 `kb_` 前缀，后端代码放在 `know-boot-knowledge` 模块下 |

## 三、非目标

- 不修改现有 `kb_document`、`kb_directory` 等表结构
- 不改造现有在线编辑器
- 暂不支持 `.docx`、`.pdf` 等二进制格式（V2 再考虑）

## 四、文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表设计 + 完整 SQL（建表 + 菜单） |
| [02-backend-api.md](./02-backend-api.md) | 后端 API 接口 + Controller/Service 代码落点 |
| [03-frontend-vue.md](./03-frontend-vue.md) | Vue 管理端：菜单新增 + 文件管理页 + 预览 |
| [04-frontend-uniapp.md](./04-frontend-uniapp.md) | UniApp 移动端：菜单新增 + 上传页 + 预览适配 |
| [05-data-flow.md](./05-data-flow.md) | 文件上传 → 解析 → 入库 → 预览完整数据流 |
| [kb_file_upload.sql](./kb_file_upload.sql) | **可直接执行**的完整 SQL（建表 + 菜单 + 角色授权 + 菜单配置） |
| [app/](./app/) | UI 原型 HTML |

## 五、目录规范对齐

```
know-boot-knowledge/src/main/java/com/know/knowboot/
├── controller/knowledge/    ← 新增 KbFileUploadController.java
├── service/knowledge/       ← 新增 IKbFileUploadService.java
├── service/knowledge/impl/  ← 新增 KbFileUploadServiceImpl.java
├── mapper/knowledge/        ← 新增 KbUploadedFileMapper.java
└── entity/knowledge/        ← 新增 KbUploadedFile.java

kb_* 表前缀保持与现有表一致
```

## 六、UniApp 适配要点

| 场景 | 方案 |
|------|------|
| H5 | HTML 直接 `iframe` / `rich-text`；MD 用 marked.js 转 HTML 后 `rich-text` |
| App | HTML 用 `web-view` 打开；MD 用 marked.js + `rich-text` |
| 小程序 | HTML 受限改用 `rich-text` 渲染（需后端返回纯 body）；MD 同 App 方案 |

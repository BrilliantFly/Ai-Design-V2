# 开发规范汇总

本文件夹汇总了 know 系列项目的实际开发规范，全部内容基于现有代码库真实情况整理（不臆造规则）。

## 三端规范

| 文件 | 说明 |
|---|---|
| [01-移动端(uniapp)开发规范.md](01-移动端(uniapp)开发规范.md) | uni-app 3.0.0 + Vue 3.2.45 + TypeScript。涵盖 pages.json、自定义 tabBar（PremiumBottomNav）、section-config 驱动表单、主题系统（styles/themes.scss）、网络请求、状态管理、构建运行等 |
| [02-管理端(know-vue)开发规范.md](02-管理端(know-vue)开发规范.md) | Vue 3 + TypeScript + Vite + ant-design-vue + Pinia。涵盖路由模块、后端动态菜单（sysMenuHelper）、懒加载 chunk 404 自愈（vite:preloadError + router.onError）、字段配置驱动（FieldItem.vue）、级联字典、API 层、CRUD 骨架、缓存/部署问题与规避 |
| [03-后端(knowboot)开发规范.md](03-后端(knowboot)开发规范.md) | Spring Boot 多模块（common/api/base/system/biz/plan/camera/knowledge/accumulate/start/standalone/microservice）。涵盖包结构、MyBatis-Plus、统一响应（AjaxResult/Result）、认证/租户（Sa-Token）、缓存、级联字典、SchemaMigration、配置端口 Redis、部署等 |

## 核心共识

- **前端端口/基址**：know-vue 生产静态资源部署于 `/opt/ai-agent/apps/know-vue`，nginx 映射 `/`；uniapp H5 部署于 `/mobile/`。
- **后端**：服务端口 `8082`，API 基础前缀 `/api`，多租户 `tenant_id`。
- **数据**：MySQL 库 `know_boot_v1`（默认）；Redis 生产 `16379`（配置文件 `redis.conf`），dev/prod 配置略有差异。
- **命名**：uniapp 页面路由以 `pages/` 路径为准；Vue 后台路由按模块化 `.ts` 定义 + DB 动态菜单协同；后端表前缀 `sys_`/`biz_` 等。
- **缓存/部署**：`know-boot/standalone/deploy.js` 每次前端部署执行 `rm -rf ${remoteDir}` 后再解压，旧 hash chunk 会被清除；know-vue 新增了懒加载失败自动刷新防护。

## 建议执行顺序

1. 新功能先读相应规范文档对应章节。
2. 参考各文档末尾的「推荐模板」/「代码骨架」直接照抄结构，再按实际情况微调。
3. 涉及级联/字典、字段配置化等公共能力优先遵循后台规范 6、后端 9 的写法。

*整理完成时间：2026-10-14*
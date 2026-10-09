# APP 快速升级更新设计方案（wgt 热更新）

> 创建日期：2026-09-27
> 版本：V1.0
> 状态：设计稿

## 背景

「喵百科」App（AppID `__UNI__32EDE25`，安卓包名 `com.know.uniapp`，当前 `1.0.0` / versionCode `100`）目前只能通过应用商店/APK 整包升级，迭代成本高、审核周期长。需要引入 **wgt 热更新机制**，实现安卓、苹果两端「前端资源快速静默更新」：

1. **wgt 包**：uni-app 打包产物（App 资源包，不含原生代码），覆盖前端 JS/CSS/页面资源，安装后**不重新上架商店**即可生效
2. **数据库表**：新增 App 版本发布表（版本号 + 下载链接 + 平台 + 更新说明等），后端提供检测更新接口
3. **Nginx 代理**：wgt 包文件存放服务器目录，由 Nginx 静态代理提供下载，不穿透后端业务服务

> 说明：wgt 仅能热更前端资源；涉及原生模块/插件/SDK 变更时必须走 APK 整包（商店审核）。电商类 App 前端迭代用 wgt 足够覆盖 90% 场景。

## 设计目标

1. **一条表支撑双端**：`platform`（android/ios）区分，版本号/下载链接/更新说明/强制更新一目了然
2. **秒级下发**：wgt 包约几百 KB ~ 几 MB，Nginx 静态出站，用户无感下载安装
3. **分级更新策略**：支持「可选更新」「强制更新」两种模式，强制更新时拦截旧版本继续使用
4. **不侵入业务**：检测更新接口走公共 API（免登录），客户端启动时检测，失败静默跳过
5. **复用现有部署链路**：Nginx 配置并入 `deploy.js` 的 `NGINX_CONFIG`，wgt 文件目录独立于前端部署目录，互不影响

## 核心流程

```
[开发机 HBuilderX]                 [服务器 101.37.83.88]               [用户手机]
        │                                │                              │
        │ 1.制作 wgt 包                    │                              │
        │ ──── 上传 ❯  /opt/ai-agent/upgrade/                           │
        │ 2.后台录入版本记录               │                              │
        │ ──── ❯  app_version 表          │                              │
        │                                │  3. App 启动检测版本           │
        │                                │ ◀──── GET /api/system/        │
        │                                │        app/version/latest ──  │
        │                                │ ──── 返回最新版本+下载地址 ──▶ │
        │                                │  4. 下载 wgt（Nginx 代理）      │
        │                                │ ◀──── GET /upgrade/xxx.wgt ──  │
        │                                │ ──── 200 文件流 ────────────▶  │
        │                                │  5. plus.runtime.install 安装  │
        │                                │ ◀────────── restart ────────  │
```

## 关键设计决策

| 决策点 | 方案 | 理由 |
|--------|------|------|
| 表归属 | `know_boot_v1.sys_app_version`（system 模块，走 V1_11 migration） | 属于平台级配置，与 sys_menu_config 同模块 |
| 版本比较 | `version_code`（int，如 100/101）比较，`version_name`（1.0.1）展示 | 对齐 App 原生 versionCode 体系 |
| 下载链接存储 | 存**相对路径** `/upgrade/xxx.wgt`，接口返回时拼全域名 | 域名/IP 变更无需改库，部署灵活 |
| wgt 文件位置 | `/opt/ai-agent/upgrade/wgt/` | 独立于前端 `know-mobile/`，避免被部署脚本覆盖 |
| Nginx 出站 | `location /upgrade/ { alias ...; }` 静态文件 | 不经过 Java 服务，吞吐高、内存零占用（契合服务器内存紧张现状） |
| 检测接口鉴权 | 免登录公共接口（同 site config 风格） | App 冷启动时未登录也需要检测 |
| iOS 策略 | wgt 方案两端通用，但**强制更新仅建议安卓**；iOS 走商店审核 | Apple 审核政策对热更新敏感，wgt 资源包在审核窗口内可更新，被拒有风险 |

## 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表结构（sys_app_version 建表 SQL + 索引 + 示例数据） |
| [02-backend-api.md](./02-backend-api.md) | 后端检测更新接口（免登录 GET + 返回结构） |
| [03-nginx-and-deploy.md](./03-nginx-and-deploy.md) | Nginx 代理下载 + wgt 包存放目录 + 部署接入点 |
| [04-client-update-flow.md](./04-client-update-flow.md) | App 端（uni-app / App.vue）检测→下载→安装完整流程 |
| [05-my-page-version-display.md](./05-my-page-version-display.md) | 「我的」页面显示当前版本 + 新版本红点/提示 + 点击更新入口 |
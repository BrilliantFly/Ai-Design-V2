# 03 - Nginx 代理下载 + wgt 包存放 + 部署接入

> 目标：wgt 文件存放服务器本地目录，Nginx 静态代理直接出站下载，**不经过 Java 服务**（省内存、高吞吐，契合当前服务器内存紧张现状）。

## 3.1 目录规划

```
/opt/ai-agent/
├── apps/
│   ├── backend/          # 后端 jar + uploads
│   ├── know-vue/         # 管理端（已有）
│   └── know-mobile/      # 手机 H5（已有）
└── upgrade/
    └── wgt/              # ★ 新增：wgt 包存放目录
        └── know-android-1.0.1.wgt
```

> 独立于 `apps/` 之外，部署脚本 `deploy.js` 更新前端时**不会覆盖** wgt 文件。

## 3.2 Nginx 配置（并入 deploy.js 的 NGINX_CONFIG）

在现有 `server { listen 9191; ... }` 块内新增 `location /upgrade/`：

```nginx
    # ===== wgt 热更新包下载（静态文件，不走 Java）=====
    location /upgrade/ {
        alias /opt/ai-agent/upgrade/wgt/;
        default_type application/octet-stream;
        add_header Content-Disposition 'attachment; filename="$1"';
        add_header Cache-Control 'no-cache';
        expires -1;
        autoindex off;
    }
```

**要点**：

| 配置项 | 说明 |
|--------|------|
| `alias` | 将 `/upgrade/xxx.wgt` 映射到 `/opt/ai-agent/upgrade/wgt/xxx.wgt` |
| `default_type application/octet-stream` | 强制下载，避免 .wgt 被浏览器当文本打开 |
| `Content-Disposition attachment` | 提示浏览器/客户端保存文件，filename 取 `$1` |
| `no-cache` | 保证每次下载到最新包（文件名带版本号，天然防缓存） |
| `client_max_body_size` | 已全局 100M（deploy.js 现有配置），wgt 通常几 MB，足够 |

> 也可更简单：`alias /opt/ai-agent/upgrade/wgt/;` + `default_type` 即可，`Content-Disposition` 由 `plus.downloader`/`uni.downloadFile` 侧无关（App 内部直接写文件，不依赖响应头）。管理后台手动下载时可借助响应头友好命名。

## 3.3 下载地址拼接

```
表内 download_url = /upgrade/wgt/know-android-1.0.1.wgt
访问地址         = http://101.37.83.88:9191/upgrade/wgt/know-android-1.0.1.wgt
```

- `9191` 是现有 Nginx 监听端口（deploy.js 中已配置）
- 域名/IP 变化时只改后端「静态前缀」配置，库内相对路径不动

## 3.4 部署接入点（实现阶段）

1. **deploy.js**：`NGINX_CONFIG` 模板中新增上述 `location /upgrade/` 块；新增一个 `upgrade` 组件开关（如 `node deploy.js upgrade`）或并入 `vue` 步骤，用 `sshExec mkdir -p /opt/ai-agent/upgrade/wgt` + `sftpUpload` 上传 wgt 包
2. **目录创建**：`sshExec('mkdir -p /opt/ai-agent/upgrade/wgt')`
3. **wgt 上传**：本地 `dist/build/app/`（构建产物）→ 压缩成 wgt → 上传 `/opt/ai-agent/upgrade/wgt/`；或直接从 `know-uniapp/dist/release` 取已生成包
4. 配置修改后 `nginx -t && nginx -s reload`（deploy.js 已有此逻辑）

## 3.5 验证命令

```bash
# 服务器上
ls -la /opt/ai-agent/upgrade/wgt/
nginx -t

# 本地
curl -I http://101.37.83.88:9191/upgrade/wgt/know-android-1.0.1.wgt
# 期望：HTTP/1.1 200 OK, Content-Type: application/octet-stream, Content-Length: <size>
```
# 02 - 后端接口设计（检测更新）

> 模块：system（对齐 sys_menu_config / site config 风格）
> 鉴权：**免登录公共接口**（冷启动时用户可能未登录，必须可匿名访问）
> 返回：JSON

## 2.1 GET /api/system/app/version/latest

**用途**：App 冷启动 / 进入前台时检测是否有新版本。

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platform | string | ✅ | `android` / `ios` |
| versionCode | int | ✅ | 客户端自身 versionCode（manifest 中配置，如 100） |

**响应**：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "hasUpdate": true,
    "forceUpdate": false,
    "latest": {
      "versionCode": 101,
      "versionName": "1.0.1",
      "downloadUrl": "http://101.37.83.88:9191/upgrade/wgt/know-android-1.0.1.wgt",
      "fileSize": 2097152,
      "md5": "d41d8cd98f00b204e9800998ecf8427ece",
      "updateDesc": "1. 优化首页加载速度\n2. 修复部分机型闪退\n3. 新增行业市场筛选"
    }
  ]
}
```

**无更新时**：

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "hasUpdate": false,
    "forceUpdate": false,
    "latest": null
  }
}
```

**业务规则**：

1. 按 `platform = {platform} AND status = 1 AND deleted = 0` 过滤
2. 取其中 `version_code` **大于** 客户端 `versionCode` 的最大一条
3. `downloadUrl` = 配置的静态前缀（`http://101.37.83.88:9191`）+ 表内 `download_url`
4. 找不到 → `hasUpdate:false`
5. 异常（库连不上等）→ 返回 200 + `hasUpdate:false`（客户端静默跳过，不阻塞启动）

## 2.2 后端代码落位（实现阶段参考）

```
know-boot-system/src/main/java/com/know/knowboot/
├── controller/system/
│   └── SysAppVersionController.java        # GET /system/app/version/latest（免登录）
├── entity/
│   └── SysAppVersion.java                  # @TableName("sys_app_version")
├── mapper/
│   └── SysAppVersionMapper.java            # extends IBaseMapper<SysAppVersion>
└── service/
    ├── ISysAppVersionService.java
    └── impl/SystemAppVersionServiceImpl.java
```

> 免登录配置：沿用现有 IgnoreAuth / security 白名单机制（与 site config、public menu 一致），路径加入放行列表。

## 2.3 管理端（可选，管理后台用）

后端管理维护可复用通用 CRUD（增删改查 + 发布/下架），接入现有后台菜单体系（如 `sys_admin` 登录后的管理界面）；若暂不做管理 UI，亦可直接 SQL 维护（脚本已幂等）。
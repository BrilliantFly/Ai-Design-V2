# 01 - 数据库表结构设计（APP 版本发布表)

> 归属：`know_boot_v1` 库，system 模块，迁移脚本编号 **V1_11**（续 V1_10__sys_menu_config_industry.sql）。
> 命名对齐现有 sys_ 前缀表（sys_menu_config / sys_tenant_user 等）。

## 1.1 表：sys_app_version（App 版本发布表）

**用途**：记录安卓 / 苹果 wgt 热更新包的版本号与下载地址。一条记录 = 一个平台的一个版本。

```sql
CREATE TABLE IF NOT EXISTS sys_app_version (
  -- ===== 主键与版本 =====
  id              BIGINT       NOT NULL COMMENT '主键',
  platform        VARCHAR(16)  NOT NULL COMMENT '平台(android/ios)',
  version_code    INT          NOT NULL COMMENT '版本号(内部比较用，如 100/101，对应 manifest versionCode)',
  version_name    VARCHAR(32)  NOT NULL COMMENT '版本名称(展示用，如 1.0.1，对应 manifest versionName)',

  -- ===== 下载与包信息 =====
  download_url    VARCHAR(255) NOT NULL COMMENT 'wgt下载相对路径(/upgrade/xxx.wgt，Nginx 代理出站)',
  file_name       VARCHAR(128) DEFAULT NULL COMMENT 'wgt文件名(如 know-1.0.1.wgt)',
  file_size       BIGINT       DEFAULT NULL COMMENT '文件大小(字节，用于下载进度)',
  md5             VARCHAR(64)  DEFAULT NULL COMMENT '文件MD5(完整性校验，可选)',

  -- ===== 更新策略 =====
  force_update    TINYINT      DEFAULT 0 COMMENT '是否强制更新(0:可选 1:强制，强制时拦截旧版本)',
  update_desc     VARCHAR(1000) DEFAULT NULL COMMENT '更新说明(换行分隔，客户端展示)',
  status          TINYINT      DEFAULT 1 COMMENT '状态(0:下架 1:发布中，只返回发布中的最新版本)',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间(毫秒时间戳)',
  deleted         TINYINT      DEFAULT 0 COMMENT '删除标记(0:正常 1:删除)',

  PRIMARY KEY (id),
  UNIQUE KEY uk_version_platform (platform, version_code, deleted),
  KEY idx_version_status (platform, status, version_code, deleted)
) COMMENT = 'App版本发布表(wgt热更新)';
```

> **版本比较约定**：客户端携带自身 `versionCode`（manifest 中 `versionCode`，如 100），后端返回「同 platform 下 status=1 且 version_code 大于客户端 code」的最大版本；若无则无需更新。

## 1.2 平台差异说明

| 平台 | wgt 支持 | 强制更新 | 备注 |
|------|----------|----------|------|
| android | ✅ 支持 | 建议开启 | wgt 安装后 `plus.runtime.restart()` 立即生效，无商店审核 |
| ios | ⚠️ 支持但慎用 | 不建议强制 | Apple 审核政策对热更新敏感；wgt 是资源包非代码，审核窗口内可用；**若被拒降级走商店整包** |

> 设计上**同一张表**记录两端版本，`platform` 字段区分：安卓发布 100→101 不影响 iOS 独立并行版本号。

## 1.3 示例数据

```sql
-- 安卓 1.0.1（可选更新）
INSERT INTO sys_app_version
  (id, platform, version_code, version_name, download_url, file_name, file_size, force_update, update_desc, status, create_time)
VALUES
  (1, 'android', 101, '1.0.1', '/upgrade/wgt/know-android-1.0.1.wgt', 'know-android-1.0.1.wgt', 2097152, 0,
   '1. 优化首页加载速度\n2. 修复部分机型闪退\n3. 新增行业市场筛选', 1, 1757596800000);

-- 苹果 1.0.0（首版，无更新）—— 演示存在但客户端同 code 不返回
INSERT INTO sys_app_version
  (id, platform, version_code, version_name, download_url, file_name, file_size, force_update, update_desc, status, create_time)
VALUES
  (2, 'ios', 100, '1.0.0', '/upgrade/wgt/know-ios-1.0.0.wgt', 'know-ios-1.0.0.wgt', 1987160, 0,
   '首版发布', 1, 1757596800000);
```

## 1.4 迁移脚本落位

```
know-boot-system/src/main/resources/db/migration/V1_11__sys_app_version.sql
```

> 当前远程库 **Flyway 未启用**（无 flyway_schema_history 表），需沿用既有 db-sync 通道（`standalone` 目录脚本）手动执行该脚本；或用 `CREATE TABLE IF NOT EXISTS` 幂等执行，与 V1_1/V1_8/V1_10 同样的处理方式。
-- ============================================================
-- AI 知识库菜单设计 —— 文件上传模块 SQL
-- 项目: know-boot (know-boot-knowledge 模块)
-- 版本: V1.0 / 2026-10-13
-- 前缀: kb_ (与现有表一致)
-- 执行方式: Navicat / DBeaver 直接整份执行；或 Flyway 放入 db/migration/
--           若用 Flyway，拆成:
--             V1_12__kb_uploaded_file.sql
--             V1_13__sys_menu_config_fileupload.sql
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- ① 建表: kb_uploaded_file
-- ============================================================
DROP TABLE IF EXISTS `kb_uploaded_file`;
CREATE TABLE `kb_uploaded_file` (
  `id`                 BIGINT        NOT NULL AUTO_INCREMENT  COMMENT '主键',
  `original_name`      VARCHAR(255)  NOT NULL                 COMMENT '原始文件名(用户上传时的名字)',
  `file_name`          VARCHAR(255)  NOT NULL                 COMMENT '存储文件名(UUID+ext,防重名)',
  `file_path`          VARCHAR(500)  NOT NULL                 COMMENT '文件存储相对路径(./upload/knowledge/...)',
  `file_ext`           VARCHAR(20)   NOT NULL                 COMMENT '扩展名: html / htm / md / markdown',
  `file_content`       LONGTEXT                               COMMENT '文件原始文本内容(UTF-8,上传时直接读取存库)',
  `file_size`          BIGINT        DEFAULT 0                COMMENT '文件大小(字节)',
  `mime_type`          VARCHAR(100)  DEFAULT NULL             COMMENT 'MIME 类型',
  `knowledge_base_id`  BIGINT        DEFAULT NULL             COMMENT '归属知识库ID(可空,表示未分类)',
  `document_id`        BIGINT        DEFAULT NULL             COMMENT '解析成功后对应的 kb_document.id',
  `parse_status`       TINYINT       DEFAULT 0                COMMENT '解析状态: 0待解析 1成功 2失败',
  `parse_error`        VARCHAR(1000) DEFAULT NULL             COMMENT '解析失败原因',
  `source_type`        VARCHAR(20)   DEFAULT 'upload'         COMMENT '来源类型: upload / import / system',
  `upload_platform`    VARCHAR(20)   DEFAULT NULL             COMMENT '上传端: vue / uniapp-h5 / uniapp-app / uniapp-mp',
  `sort`               INT           DEFAULT 0                COMMENT '排序',
  `status`             TINYINT       DEFAULT 1                COMMENT '状态: 0禁用 1正常',
  `create_by`          BIGINT        DEFAULT NULL             COMMENT '上传人ID',
  `create_time`        BIGINT        DEFAULT NULL             COMMENT '上传时间(毫秒时间戳)',
  `update_time`        BIGINT        DEFAULT NULL             COMMENT '更新时间(毫秒时间戳)',
  `delete_time`        BIGINT        DEFAULT 0                COMMENT '删除时间(毫秒,0=未删除)',
  PRIMARY KEY (`id`),
  KEY `idx_kb_id`       (`knowledge_base_id`),
  KEY `idx_doc_id`      (`document_id`),
  KEY `idx_create_by`   (`create_by`),
  KEY `idx_parse`       (`parse_status`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_source_type` (`source_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库上传文件表(HTML/MD)';


-- ============================================================
-- ② Vue 管理端菜单 (sys_menu)
-- 现有知识管理根菜单 id=20, 子菜单 2001~2004, 新增 2005 文件管理
-- menu_type: 1=目录 2=菜单 3=按钮权限
-- 幂等: ON DUPLICATE KEY UPDATE
-- ============================================================

-- 2.1 目录: 知识管理 (已有, 这里 UPDATE 兜底, 防止被误删)
INSERT INTO `sys_menu` (`id`, `parent_id`, `menu_name`, `path`, `component`, `perms`, `icon`, `menu_type`, `sort`, `status`, `create_by`, `create_time`)
VALUES (20, 0, '知识管理', '/knowledge', NULL, 'knowledge:view', 'book', 1, 15, 1, 'admin', NOW())
ON DUPLICATE KEY UPDATE `menu_name` = VALUES(`menu_name`);

-- 2.2 菜单: 文件管理 (新增, id=2005 顺延现有 2001~2004)
INSERT INTO `sys_menu` (`id`, `parent_id`, `menu_name`, `path`, `component`, `perms`, `icon`, `menu_type`, `sort`, `status`, `create_by`, `create_time`)
VALUES (2005, 20, '文件管理', '/knowledge/file', 'knowledge/file', 'knowledge:file:view', 'upload', 2, 5, 1, 'admin', NOW())
ON DUPLICATE KEY UPDATE `menu_name` = VALUES(`menu_name`);

-- 2.3 按钮权限 (3 个, 20051 / 20052 / 20053)
INSERT INTO `sys_menu` (`id`, `parent_id`, `menu_name`, `path`, `component`, `perms`, `icon`, `menu_type`, `sort`, `status`, `create_by`, `create_time`)
VALUES
(20051, 2005, '文件上传', NULL, NULL, 'knowledge:file:upload', NULL, 3, 1, 1, 'admin', NOW()),
(20052, 2005, '文件删除', NULL, NULL, 'knowledge:file:delete', NULL, 3, 2, 1, 'admin', NOW()),
(20053, 2005, '文件解析', NULL, NULL, 'knowledge:file:parse', NULL, 3, 3, 1, 'admin', NOW())
ON DUPLICATE KEY UPDATE `menu_name` = VALUES(`menu_name`);


-- ============================================================
-- ③ 角色授权 (sys_role_menu)
-- 给超级管理员 role_id=1 授权所有新增菜单/按钮
-- 幂等: ON DUPLICATE KEY UPDATE create_by
-- ============================================================
INSERT INTO `sys_role_menu` (`role_id`, `menu_id`, `create_by`, `create_time`)
SELECT 1, id, 'admin', NOW() FROM `sys_menu`
WHERE `id` IN (2005, 20051, 20052, 20053)
  AND `del_flag` = 0
ON DUPLICATE KEY UPDATE `create_by` = 'admin';

-- 如需授权给普通编辑角色 (示例 role_id=2), 复制上面 SELECT 改 role_id 即可
-- INSERT INTO `sys_role_menu` (`role_id`, `menu_id`, `create_by`, `create_time`)
-- SELECT 2, id, 'admin', UNIX_TIMESTAMP() * 1000 FROM `sys_menu`
-- WHERE `id` IN (2005, 20051) AND `del_flag` = 0
-- ON DUPLICATE KEY UPDATE `create_by` = 'admin';


-- ============================================================
-- ④ UniApp 首页快捷入口菜单 (sys_menu_config)
-- 首页"快捷功能"网格, sections=["quick"] 会出现在第一屏
-- 参考已有 knowledge / memo / doc-edit 三条
-- ============================================================
INSERT IGNORE INTO `sys_menu_config`
(`menu_name`, `menu_code`, `menu_type`, `icon`, `path`, `is_show`, `sort`, `render_type`, `render_config`, `create_time`)
VALUES
('文件导入', 'file-upload', 2, '📤', '/pages/knowledge/file-upload/index', 1, 13, 1,
 '{"iconClass":"premium-icon-g9","title":"文件导入","desc":"上传 HTML/MD 快速入库并预览","tag":"导入","thumbBg":"linear-gradient(135deg,#ecfdf5,#d1fae5)","sections":["quick"]}',
 NOW());


-- ============================================================
-- ⑤ 测试数据 (可选, 生产环境可跳过此段)
-- 先确认存在一条 kb_knowledge_base 可关联
-- ============================================================

-- 若没有知识库, 创建一个测试的
INSERT INTO `kb_knowledge_base` (`name`, `icon`, `description`, `visibility`, `sort`, `status`, `create_by`, `create_time`, `update_time`, `delete_time`)
SELECT '技术文档', '📚', '知识库文件上传功能测试', 1, 0, 1, 1, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `kb_knowledge_base` WHERE `name` = '技术文档');

-- 取刚才那条知识库的 id
SET @test_kb_id = (SELECT `id` FROM `kb_knowledge_base` WHERE `name` = '技术文档' LIMIT 1);

-- 示例上传记录 (HTML)
INSERT INTO `kb_uploaded_file`
(`original_name`, `file_name`, `file_path`, `file_ext`, `file_content`, `file_size`, `mime_type`,
 `knowledge_base_id`, `document_id`, `parse_status`, `parse_error`, `source_type`, `upload_platform`,
 `sort`, `status`, `create_by`, `create_time`, `update_time`, `delete_time`)
VALUES
('quick-start.html', '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08.html',
 './upload/knowledge/20261013/9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08.html',
 'html',
 '<!DOCTYPE html><html><head><meta charset="utf-8"><title>快速入门</title></head><body><h1>快速入门</h1><p>这是一个示例上传的 HTML 文件内容。</p><h2>特性</h2><ul><li>支持 .html / .htm</li><li>支持 .md / .markdown</li></ul></body></html>',
 380, 'text/html',
 @test_kb_id, NULL, 0, NULL, 'upload', 'vue',
 0, 1, 1, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0),

('readme.md', '1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8.md',
 './upload/knowledge/20261013/1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8.md',
 'markdown',
 '# 知识库文件导入\n\n## 支持的格式\n\n- `.html` / `.htm`  —— 富文本类型\n- `.md` / `.markdown` —— Markdown 类型\n\n## 用法\n\n1. Vue 管理端: 侧边栏 → 知识管理 → 文件管理\n2. UniApp: 首页快捷入口「📤 文件导入」\n\n> 单个文件 ≤ 5MB, 批量上传一次最多 20 个',
 420, 'text/markdown',
 @test_kb_id, NULL, 0, NULL, 'upload', 'uniapp-h5',
 0, 1, 1, UNIX_TIMESTAMP() * 1000, UNIX_TIMESTAMP() * 1000, 0);


-- ============================================================
-- 验证 SQL (执行后可跑, 确认正确后可注释掉)
-- ============================================================
-- SELECT 'kb_uploaded_file 表' AS item, COUNT(*) AS cnt FROM kb_uploaded_file
-- UNION ALL
-- SELECT 'sys_menu 新增菜单(2005/20051~3)', COUNT(*) FROM sys_menu WHERE id IN (2005,20051,20052,20053) AND del_flag=0
-- UNION ALL
-- SELECT 'sys_role_menu 授权', COUNT(*) FROM sys_role_menu WHERE menu_id IN (2005,20051,20052,20053)
-- UNION ALL
-- SELECT 'sys_menu_config 快捷入口', COUNT(*) FROM sys_menu_config WHERE menu_code = 'file-upload';

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- END
-- ============================================================

-- ============================================
-- 知识管理数据库初始化脚本
-- 版本: 1.0.0
-- 数据库: know_boot_v1
-- 前缀: kb_ (knowledge base)
-- 说明: 新增知识库相关表，不影响现有表结构
-- ============================================

-- ============================================
-- 0. 设置
-- ============================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. 知识库表
-- ============================================
DROP TABLE IF EXISTS `kb_knowledge_base`;
CREATE TABLE `kb_knowledge_base` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '知识库ID',
  `name` varchar(100) NOT NULL COMMENT '知识库名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `cover` varchar(500) DEFAULT NULL COMMENT '封面图URL',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `visibility` tinyint DEFAULT 1 COMMENT '可见性 0=私密 1=公开',
  `doc_count` int DEFAULT 0 COMMENT '文档数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间(毫秒时间戳)',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  KEY `idx_create_by` (`create_by`),
  KEY `idx_status` (`status`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库表';

-- ============================================
-- 2. 知识库成员表 (多对多)
-- ============================================
DROP TABLE IF EXISTS `kb_knowledge_base_member`;
CREATE TABLE `kb_knowledge_base_member` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '知识库ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role_type` tinyint DEFAULT 1 COMMENT '角色类型 1=查看者 2=编辑者 3=管理者',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_kb_user` (`knowledge_base_id`, `user_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库成员表';

-- ============================================
-- 3. 目录表
-- ============================================
DROP TABLE IF EXISTS `kb_directory`;
CREATE TABLE `kb_directory` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `parent_id` bigint DEFAULT 0 COMMENT '父目录ID(0为根目录)',
  `name` varchar(100) NOT NULL COMMENT '目录名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间(毫秒时间戳)',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目录表';

-- ============================================
-- 4. 文档表
-- ============================================
DROP TABLE IF EXISTS `kb_document`;
CREATE TABLE `kb_document` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文档ID',
  `directory_id` bigint DEFAULT NULL COMMENT '所属目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `content` longtext COMMENT '内容(HTML/JSON)',
  `content_type` tinyint DEFAULT 1 COMMENT '内容类型 1=富文本 2=Markdown',
  `view_count` int DEFAULT 0 COMMENT '浏览次数',
  `like_count` int DEFAULT 0 COMMENT '点赞数',
  `comment_count` int DEFAULT 0 COMMENT '评论数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=草稿 1=已发布',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间(毫秒时间戳)',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  KEY `idx_directory_id` (`directory_id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  KEY `idx_create_by` (`create_by`),
  KEY `idx_status` (`status`),
  FULLTEXT KEY `ft_title_content` (`title`, `content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档表';

-- ============================================
-- 5. 小记表
-- ============================================
DROP TABLE IF EXISTS `kb_memo`;
CREATE TABLE `kb_memo` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '小记ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `content` text NOT NULL COMMENT '内容',
  `tags` varchar(500) DEFAULT NULL COMMENT '标签(逗号分隔)',
  `images` text DEFAULT NULL COMMENT '图片URL(JSON数组)',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=删除 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间(毫秒时间戳)',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小记表';

-- ============================================
-- 6. 文档评论表
-- ============================================
DROP TABLE IF EXISTS `kb_document_comment`;
CREATE TABLE `kb_document_comment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `document_id` bigint NOT NULL COMMENT '文档ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `user_name` varchar(100) DEFAULT NULL COMMENT '用户名',
  `user_avatar` varchar(300) DEFAULT NULL COMMENT '用户头像',
  `content` text NOT NULL COMMENT '评论内容',
  `parent_id` bigint DEFAULT 0 COMMENT '父评论ID(0为一级评论)',
  `reply_id` bigint DEFAULT NULL COMMENT '被回复评论ID',
  `reply_name` varchar(100) DEFAULT NULL COMMENT '被回复人名称',
  `like_count` int DEFAULT 0 COMMENT '点赞数',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=删除 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间(毫秒时间戳)',
  PRIMARY KEY (`id`),
  KEY `idx_document_id` (`document_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档评论表';

-- ============================================
-- 7. 知识库管理菜单 (管理后台)
-- ============================================
-- 注意: 需要根据实际菜单ID调整parent_id
-- 假设系统管理菜单ID为1，需要在系统管理下添加知识库管理子菜单

-- 插入知识库管理菜单 (一级菜单)
INSERT INTO `sys_menu` (`name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
('知识库管理', 'knowledge:base:list', 1, 10, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 获取刚插入的菜单ID
SET @kb_menu_id = LAST_INSERT_ID();

-- 插入知识库管理子菜单
INSERT INTO `sys_menu` (`pid`, `name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@kb_menu_id, '知识库新增', 'knowledge:base:add', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@kb_menu_id, '知识库编辑', 'knowledge:base:edit', 2, 2, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@kb_menu_id, '知识库删除', 'knowledge:base:delete', 2, 3, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@kb_menu_id, '知识库查询', 'knowledge:base:query', 2, 4, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入文档管理菜单 (一级菜单)
INSERT INTO `sys_menu` (`name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
('文档管理', 'knowledge:document:list', 1, 11, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

SET @doc_menu_id = LAST_INSERT_ID();

INSERT INTO `sys_menu` (`pid`, `name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@doc_menu_id, '文档新增', 'knowledge:document:add', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@doc_menu_id, '文档编辑', 'knowledge:document:edit', 2, 2, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@doc_menu_id, '文档删除', 'knowledge:document:delete', 2, 3, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@doc_menu_id, '文档查询', 'knowledge:document:query', 2, 4, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入小记管理菜单 (一级菜单)
INSERT INTO `sys_menu` (`name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
('小记管理', 'knowledge:memo:list', 1, 12, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

SET @memo_menu_id = LAST_INSERT_ID();

INSERT INTO `sys_menu` (`pid`, `name`, `permission`, `type`, `sort`, `status`, `create_time`, `update_time`) VALUES
(@memo_menu_id, '小记新增', 'knowledge:memo:add', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@memo_menu_id, '小记删除', 'knowledge:memo:delete', 2, 2, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(@memo_menu_id, '小记查询', 'knowledge:memo:query', 2, 3, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- ============================================
-- 8. 测试数据 (可选)
-- ============================================

-- 插入测试知识库
INSERT INTO `kb_knowledge_base` (`name`, `icon`, `description`, `visibility`, `doc_count`, `sort`, `status`, `create_by`, `create_time`, `update_time`) VALUES
('技术文档', '📚', '记录技术学习和工作中的文档', 1, 3, 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
('产品手册', '📖', '产品相关文档和说明', 1, 2, 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
('个人笔记', '📝', '个人学习和成长记录', 1, 5, 3, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入测试目录
INSERT INTO `kb_directory` (`knowledge_base_id`, `parent_id`, `name`, `icon`, `sort`, `status`, `create_by`, `create_time`, `update_time`) VALUES
(1, 0, '前端开发', '📁', 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 0, '后端开发', '📁', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 1, 'Vue3', '📁', 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 1, 'TypeScript', '📁', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 2, 'SpringBoot', '📁', 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 2, 'MySQL', '📁', 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入测试文档
INSERT INTO `kb_document` (`directory_id`, `knowledge_base_id`, `title`, `content`, `content_type`, `view_count`, `like_count`, `comment_count`, `sort`, `status`, `create_by`, `create_time`, `update_time`) VALUES
(3, 1, 'Vue3组件封装指南', '<h1>Vue3组件封装指南</h1><p>本文介绍如何封装Vue3组件...</p>', 1, 128, 15, 3, 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(4, 1, 'TypeScript最佳实践', '<h1>TypeScript最佳实践</h1><p>TypeScript使用建议...</p>', 1, 96, 12, 2, 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(5, 1, 'SpringBoot入门到精通', '<h1>SpringBoot入门到精通</h1><p>SpringBoot快速入门...</p>', 1, 256, 32, 5, 1, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(6, 1, 'MySQL优化技巧', '<h1>MySQL优化技巧</h1><p>数据库性能优化...</p>', 1, 189, 24, 4, 2, 1, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入测试小记
INSERT INTO `kb_memo` (`user_id`, `content`, `tags`, `images`, `status`, `create_time`, `update_time`) VALUES
(1, '今天学习了Vue3的Composition API，感觉比Options API更灵活了！', 'Vue3,学习', NULL, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, '产品需求评审要点：1. 用户登录流程优化 2. 搜索功能增强', '产品,需求', NULL, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000),
(1, 'SpringBoot整合MyBatis-Plus的配置笔记', 'SpringBoot,MyBatis', NULL, 1, UNIX_TIMESTAMP()*1000, UNIX_TIMESTAMP()*1000);

-- 插入测试评论
INSERT INTO `kb_document_comment` (`document_id`, `user_id`, `user_name`, `content`, `parent_id`, `status`, `create_time`) VALUES
(1, 1, '管理员', '写得很详细，感谢分享！', 0, 1, UNIX_TIMESTAMP()*1000),
(1, 1, '管理员', '请问Vue3.3有什么新特性？', 0, 1, UNIX_TIMESTAMP()*1000),
(1, 1, '管理员', 'Vue3.3主要增强了TypeScript支持...', 2, 1, UNIX_TIMESTAMP()*1000);

-- ============================================
-- 完成
-- ============================================
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- 验证脚本 (执行后可删除)
-- ============================================
-- SELECT 'kb_knowledge_base' AS table_name, COUNT(*) AS count FROM kb_knowledge_base
-- UNION ALL
-- SELECT 'kb_knowledge_base_member', COUNT(*) FROM kb_knowledge_base_member
-- UNION ALL
-- SELECT 'kb_directory', COUNT(*) FROM kb_directory
-- UNION ALL
-- SELECT 'kb_document', COUNT(*) FROM kb_document
-- UNION ALL
-- SELECT 'kb_memo', COUNT(*) FROM kb_memo
-- UNION ALL
-- SELECT 'kb_document_comment', COUNT(*) FROM kb_document_comment;

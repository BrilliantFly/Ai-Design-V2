-- ============================================
-- 知识管理APP数据库设计
-- 版本: 2.0.0
-- 核心功能: 个人知识库、文档、小记
-- ============================================

-- ============================================
-- 一、知识库表 (个人)
-- ============================================

CREATE TABLE IF NOT EXISTS `knowledge_base` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '知识库ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `name` varchar(100) NOT NULL COMMENT '知识库名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `cover` varchar(500) DEFAULT NULL COMMENT '封面图URL',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `doc_count` int DEFAULT 0 COMMENT '文档数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库表(个人)';

-- ============================================
-- 二、目录表
-- ============================================

CREATE TABLE IF NOT EXISTS `directory` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `parent_id` bigint DEFAULT 0 COMMENT '父目录ID(0为根目录)',
  `name` varchar(100) NOT NULL COMMENT '目录名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目录表';

-- ============================================
-- 三、文档表
-- ============================================

CREATE TABLE IF NOT EXISTS `document` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文档ID',
  `directory_id` bigint DEFAULT NULL COMMENT '所属目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `content` longtext COMMENT '内容(HTML)',
  `content_type` tinyint DEFAULT 1 COMMENT '内容类型 1=富文本 2=Markdown',
  `view_count` int DEFAULT 0 COMMENT '浏览次数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=草稿 1=已发布',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_directory_id` (`directory_id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  FULLTEXT KEY `ft_title_content` (`title`, `content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档表';

-- ============================================
-- 四、小记表 (个人)
-- ============================================

CREATE TABLE IF NOT EXISTS `memo` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '小记ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `content` text NOT NULL COMMENT '内容',
  `tags` varchar(500) DEFAULT NULL COMMENT '标签(逗号分隔)',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=删除 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小记表(个人)';

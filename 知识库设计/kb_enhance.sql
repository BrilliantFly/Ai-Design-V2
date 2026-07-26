-- ============================================================
-- 知识库功能增强 - P0/P1/P2 数据库Schema
-- 生成时间：2026-07-25
-- ============================================================

-- 1. 文档评论表
CREATE TABLE IF NOT EXISTS `kb_comment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `document_id` BIGINT NOT NULL COMMENT '文档ID',
  `parent_id` BIGINT DEFAULT NULL COMMENT '父评论ID(回复)',
  `content` TEXT NOT NULL COMMENT '评论内容',
  `create_by` BIGINT DEFAULT NULL COMMENT '创建人',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  `update_time` BIGINT DEFAULT NULL COMMENT '更新时间',
  `delete_time` BIGINT DEFAULT 0 COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_document_id` (`document_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档评论';

-- 2. 文档版本历史表
CREATE TABLE IF NOT EXISTS `kb_document_version` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `document_id` BIGINT NOT NULL COMMENT '文档ID',
  `version` INT NOT NULL COMMENT '版本号',
  `title` VARCHAR(200) DEFAULT NULL COMMENT '标题',
  `content` LONGTEXT COMMENT '内容',
  `content_type` VARCHAR(20) DEFAULT 'richtext' COMMENT '内容类型',
  `change_summary` VARCHAR(500) DEFAULT NULL COMMENT '变更说明',
  `create_by` BIGINT DEFAULT NULL COMMENT '创建人',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_document_id` (`document_id`),
  UNIQUE KEY `uk_doc_version` (`document_id`, `version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档版本历史';

-- 3. 文档点赞表
CREATE TABLE IF NOT EXISTS `kb_document_like` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `document_id` BIGINT NOT NULL COMMENT '文档ID',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_doc_user` (`document_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档点赞';

-- 4. 文档收藏表
CREATE TABLE IF NOT EXISTS `kb_document_favorite` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `document_id` BIGINT NOT NULL COMMENT '文档ID',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_doc_user` (`document_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档收藏';

-- 5. 文档分享表
CREATE TABLE IF NOT EXISTS `kb_document_share` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `document_id` BIGINT NOT NULL COMMENT '文档ID',
  `share_token` VARCHAR(64) NOT NULL COMMENT '分享令牌',
  `expire_time` BIGINT DEFAULT NULL COMMENT '过期时间(null=永久)',
  `password` VARCHAR(20) DEFAULT NULL COMMENT '访问密码',
  `create_by` BIGINT DEFAULT NULL COMMENT '创建人',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_share_token` (`share_token`),
  KEY `idx_document_id` (`document_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档分享';

-- 6. 搜索历史表
CREATE TABLE IF NOT EXISTS `kb_search_history` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `keyword` VARCHAR(100) NOT NULL COMMENT '搜索关键词',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='搜索历史';

-- 7. 图片上传表
CREATE TABLE IF NOT EXISTS `kb_image` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `original_name` VARCHAR(200) DEFAULT NULL COMMENT '原始文件名',
  `file_path` VARCHAR(500) NOT NULL COMMENT '文件路径',
  `file_size` BIGINT DEFAULT NULL COMMENT '文件大小(字节)',
  `mime_type` VARCHAR(50) DEFAULT NULL COMMENT 'MIME类型',
  `create_by` BIGINT DEFAULT NULL COMMENT '上传人',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图片上传';

-- ============================================================
-- 修改现有表
-- ============================================================

-- kb_document: 新增点赞数、收藏数、评论数字段
ALTER TABLE `kb_document`
  ADD COLUMN `like_count` INT DEFAULT 0 COMMENT '点赞数' AFTER `view_count`,
  ADD COLUMN `favorite_count` INT DEFAULT 0 COMMENT '收藏数' AFTER `like_count`,
  ADD COLUMN `comment_count` INT DEFAULT 0 COMMENT '评论数' AFTER `favorite_count`,
  ADD COLUMN `version` INT DEFAULT 1 COMMENT '当前版本号' AFTER `comment_count`;

-- kb_quick_note: 新增归档状态字段
ALTER TABLE `kb_quick_note`
  ADD COLUMN `is_archived` TINYINT DEFAULT 0 COMMENT '是否归档(0否/1是)' AFTER `tags`;

-- kb_knowledge_base: 新增封面图字段
ALTER TABLE `kb_knowledge_base`
  ADD COLUMN `cover_image` VARCHAR(500) DEFAULT NULL COMMENT '封面图路径' AFTER `icon`;

-- ============================================================
-- 新增表
-- ============================================================

-- 知识库标签表
CREATE TABLE IF NOT EXISTS `kb_tag` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` VARCHAR(100) NOT NULL COMMENT '标签名称',
  `color` VARCHAR(20) DEFAULT NULL COMMENT '颜色',
  `sort` INT DEFAULT 0 COMMENT '排序',
  `create_time` BIGINT DEFAULT NULL COMMENT '创建时间',
  `update_time` BIGINT DEFAULT NULL COMMENT '更新时间',
  `delete_time` BIGINT DEFAULT 0 COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库标签';

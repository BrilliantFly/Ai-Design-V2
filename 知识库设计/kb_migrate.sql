-- ============================================
-- 文章数据迁移到知识库脚本
-- 版本: 1.0.0
-- 数据库: know_boot_v1
-- 说明: 将 la_article/la_article_cate/la_comment 迁移到 kb_ 表
-- 注意: 执行前请先备份数据库！
-- ============================================

-- ============================================
-- 0. 备份提示
-- ============================================
-- 执行前请先执行:
-- mysqldump -u root -p know_boot_v1 la_article la_article_cate la_article_collect la_comment > backup_before_migrate.sql

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. 创建临时ID映射表
-- ============================================

-- 分类ID映射: la_article_cate.id → kb_knowledge_base.id
DROP TABLE IF EXISTS `tmp_cate_mapping`;
CREATE TEMPORARY TABLE `tmp_cate_mapping` (
  `old_id` int NOT NULL,
  `new_id` bigint NOT NULL,
  PRIMARY KEY (`old_id`)
);

-- 文章ID映射: la_article.id → kb_document.id
DROP TABLE IF EXISTS `tmp_article_mapping`;
CREATE TEMPORARY TABLE `tmp_article_mapping` (
  `old_id` int NOT NULL,
  `new_id` bigint NOT NULL,
  PRIMARY KEY (`old_id`)
);

-- ============================================
-- 2. 迁移分类 → 知识库
-- ============================================
-- la_article_cate → kb_knowledge_base
-- 映射关系: 分类变成知识库

INSERT INTO `kb_knowledge_base` (
  `name`, `icon`, `description`, `visibility`, `doc_count`, `sort`, `status`,
  `create_by`, `create_time`, `update_time`
)
SELECT
  c.name,
  '📚',
  CONCAT(c.name, '分类下的文章'),
  1,
  (SELECT COUNT(*) FROM la_article a WHERE a.cid = c.id AND a.delete_time IS NULL),
  c.sort,
  CASE WHEN c.is_show = 1 THEN 1 ELSE 0 END,
  1,
  -- 时间戳转换: int(秒) → bigint(毫秒)
  CASE WHEN c.create_time IS NOT NULL THEN c.create_time * 1000 ELSE NULL END,
  CASE WHEN c.update_time IS NOT NULL THEN c.update_time * 1000 ELSE NULL END
FROM la_article_cate c
WHERE c.delete_time IS NULL;

-- 记录ID映射
INSERT INTO `tmp_cate_mapping` (`old_id`, `new_id`)
SELECT c.id, kb.id
FROM la_article_cate c
INNER JOIN kb_knowledge_base kb ON kb.name = c.name
WHERE c.delete_time IS NULL;

-- ============================================
-- 3. 为每个知识库创建默认目录
-- ============================================
-- 在知识库下创建一个"未分类"目录，用于存放没有明确目录的文章

INSERT INTO `kb_directory` (
  `knowledge_base_id`, `parent_id`, `name`, `icon`, `sort`, `status`,
  `create_by`, `create_time`
)
SELECT
  kb.id,
  0,
  '未分类',
  '📁',
  0,
  1,
  1,
  UNIX_TIMESTAMP() * 1000
FROM kb_knowledge_base kb;

-- ============================================
-- 4. 迁移文章 → 文档
-- ============================================
-- la_article → kb_document
-- 映射关系: 文章变成文档

INSERT INTO `kb_document` (
  `directory_id`, `knowledge_base_id`, `title`, `content`, `content_type`,
  `view_count`, `like_count`, `comment_count`, `sort`, `status`,
  `create_by`, `create_time`, `update_time`
)
SELECT
  -- directory_id: 获取对应知识库下的"未分类"目录ID
  (SELECT d.id FROM kb_directory d 
   WHERE d.knowledge_base_id = m.new_id AND d.name = '未分类' 
   LIMIT 1),
  -- knowledge_base_id: 通过分类映射获取
  m.new_id,
  a.title,
  a.content,
  1,  -- content_type: 默认富文本
  -- view_count: 虚拟浏览量 + 实际浏览量
  COALESCE(a.click_virtual, 0) + COALESCE(a.click_actual, 0),
  0,  -- like_count: 默认0
  0,  -- comment_count: 默认0
  a.sort,
  -- status: is_show=1 → 1(已发布), is_show=0 → 0(草稿)
  CASE WHEN a.is_show = 1 THEN 1 ELSE 0 END,
  1,  -- create_by: 默认管理员
  -- 时间戳转换: int(秒) → bigint(毫秒)
  CASE WHEN a.create_time IS NOT NULL THEN a.create_time * 1000 ELSE NULL END,
  CASE WHEN a.update_time IS NOT NULL THEN a.update_time * 1000 ELSE NULL END
FROM la_article a
INNER JOIN tmp_cate_mapping m ON a.cid = m.old_id
WHERE a.delete_time IS NULL;

-- 记录ID映射
INSERT INTO `tmp_article_mapping` (`old_id`, `new_id`)
SELECT a.id, doc.id
FROM la_article a
INNER JOIN kb_document doc ON doc.title = a.title
WHERE a.delete_time IS NULL;

-- ============================================
-- 5. 更新知识库的文档统计数
-- ============================================
UPDATE `kb_knowledge_base` kb
SET `doc_count` = (
  SELECT COUNT(*) 
  FROM kb_document d 
  WHERE d.knowledge_base_id = kb.id AND d.delete_time IS NULL
);

-- ============================================
-- 6. 迁移评论
-- ============================================
-- la_comment → kb_document_comment
-- 映射关系: article_id → document_id (通过tmp_article_mapping)

INSERT INTO `kb_document_comment` (
  `document_id`, `user_id`, `user_name`, `user_avatar`, `content`,
  `parent_id`, `reply_id`, `reply_name`, `like_count`, `status`, `create_time`
)
SELECT
  -- document_id: 通过文章映射获取
  m.new_id,
  c.user_id,
  c.user_name,
  c.user_avatar,
  c.user_content,
  -- parent_id: 需要重新映射评论的父级
  -- 如果原评论有parent_id，需要找到对应的原评论ID，再映射到新评论ID
  -- 这里简化处理：如果parent_id=0则保持0，否则尝试映射
  CASE 
    WHEN c.parent_id = 0 OR c.parent_id IS NULL THEN 0
    ELSE 0  -- 复杂的嵌套评论映射需要额外处理
  END,
  -- reply_id: 简化处理
  NULL,
  c.reply_name,
  COALESCE(c.like_count, 0),
  1,  -- status: 默认正常
  -- 时间戳转换: datetime → bigint(毫秒)
  CASE 
    WHEN c.create_time IS NOT NULL THEN 
      UNIX_TIMESTAMP(c.create_time) * 1000
    ELSE NULL 
  END
FROM la_comment c
INNER JOIN tmp_article_mapping m ON c.article_id = m.old_id;

-- ============================================
-- 7. 迁移收藏记录 (可选)
-- ============================================
-- la_article_collect 的处理方式有两种:
-- 方案A: 忽略（收藏是用户行为，不迁移）
-- 方案B: 记录到kb_document的like_count中
-- 这里选择方案B：更新文档的点赞数

UPDATE `kb_document` doc
SET `like_count` = (
  SELECT COUNT(DISTINCT ac.user_id)
  FROM la_article_collect ac
  INNER JOIN tmp_article_mapping m ON ac.article_id = m.old_id
  WHERE m.new_id = doc.id
    AND ac.status = 1
    AND ac.delete_time IS NULL
)
WHERE EXISTS (
  SELECT 1 
  FROM la_article_collect ac
  INNER JOIN tmp_article_mapping m ON ac.article_id = m.old_id
  WHERE m.new_id = doc.id
);

-- ============================================
-- 8. 更新文档的评论数统计
-- ============================================
UPDATE `kb_document` doc
SET `comment_count` = (
  SELECT COUNT(*)
  FROM kb_document_comment c
  WHERE c.document_id = doc.id AND c.status = 1
);

-- ============================================
-- 9. 清理临时表
-- ============================================
DROP TEMPORARY TABLE IF EXISTS `tmp_cate_mapping`;
DROP TEMPORARY TABLE IF EXISTS `tmp_article_mapping`;

-- ============================================
-- 10. 验证迁移结果
-- ============================================
SELECT '=== 迁移统计 ===' AS info;

SELECT 
  'la_article_cate → kb_knowledge_base' AS migration,
  (SELECT COUNT(*) FROM la_article_cate WHERE delete_time IS NULL) AS source_count,
  (SELECT COUNT(*) FROM kb_knowledge_base) AS target_count;

SELECT 
  'la_article → kb_document' AS migration,
  (SELECT COUNT(*) FROM la_article WHERE delete_time IS NULL) AS source_count,
  (SELECT COUNT(*) FROM kb_document) AS target_count;

SELECT 
  'la_comment → kb_document_comment' AS migration,
  (SELECT COUNT(*) FROM la_comment) AS source_count,
  (SELECT COUNT(*) FROM kb_document_comment) AS target_count;

SELECT 
  'la_article_collect → kb_document.like_count' AS migration,
  (SELECT COUNT(*) FROM la_article_collect WHERE status = 1 AND delete_time IS NULL) AS source_count,
  (SELECT SUM(like_count) FROM kb_document) AS total_likes;

-- ============================================
-- 11. 数据验证查询 (可选，执行后可删除)
-- ============================================

-- 验证知识库及其文档数
-- SELECT 
--   kb.id,
--   kb.name,
--   kb.doc_count,
--   (SELECT COUNT(*) FROM kb_document d WHERE d.knowledge_base_id = kb.id) AS actual_count
-- FROM kb_knowledge_base kb;

-- 验证文档详情
-- SELECT 
--   d.id,
--   d.title,
--   kb.name AS knowledge_base,
--   dir.name AS directory,
--   d.view_count,
--   d.like_count,
--   d.comment_count,
--   d.status
-- FROM kb_document d
-- INNER JOIN kb_knowledge_base kb ON d.knowledge_base_id = kb.id
-- LEFT JOIN kb_directory dir ON d.directory_id = dir.id;

-- 验证评论
-- SELECT 
--   c.id,
--   d.title AS document_title,
--   c.user_name,
--   c.content,
--   c.parent_id,
--   FROM_UNIXTIME(c.create_time / 1000) AS create_time
-- FROM kb_document_comment c
-- INNER JOIN kb_document d ON c.document_id = d.id;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- 完成
-- ============================================
-- 迁移完成！
-- 
-- 后续操作建议:
-- 1. 验证数据完整性
-- 2. 测试新API接口
-- 3. 确认无误后，可选择:
--    a. 保留原表（推荐，用于回滚）
--    b. 归档原表（rename la_article to la_article_archive）
--    c. 删除原表（谨慎操作）

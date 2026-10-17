-- ============================================================
-- AI 知识库 —— 关联字段补丁 SQL（MySQL 8.0 兼容 / 幂等）
-- 项目: know-boot (know-boot-biz / know-boot-plan)
-- 版本: V1.1 / 2026-10-17
-- 说明:
--   为行业 4 张表 + plan_info 新增 knowledge_base_id（关联 kb_knowledge_base.id）
--   供「行业/计划 → 知识库」关联使用
--
--   注意: MySQL 8.0 不支持 ALTER TABLE ... ADD COLUMN IF NOT EXISTS（那是 MariaDB 语法），
--         故这里用 INFORMATION_SCHEMA 判断 + 动态 SQL 实现幂等。
--
-- 已在生产环境执行并通过校验（2026-10-17）。
-- ============================================================

SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS `add_kb_col`;
DELIMITER $$
CREATE PROCEDURE `add_kb_col`(IN tbl VARCHAR(64))
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tbl
      AND COLUMN_NAME = 'knowledge_base_id'
  ) THEN
    SET @ddl = CONCAT(
      'ALTER TABLE `', tbl, '` ',
      'ADD COLUMN `knowledge_base_id` BIGINT DEFAULT NULL ',
      'COMMENT ''关联知识库ID（kb_knowledge_base.id）'', ',
      'ADD KEY `idx_', tbl, '_kb_id` (`knowledge_base_id`)'
    );
    PREPARE stmt FROM @ddl;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

-- 行业模块
CALL add_kb_col('biz_industry');
CALL add_kb_col('biz_industry_product');
CALL add_kb_col('biz_industry_enterprise');
CALL add_kb_col('biz_industry_market');

-- 计划模块（V1 仅 plan_info）
CALL add_kb_col('plan_info');

-- 可选：计划模板
-- CALL add_kb_col('plan_info_template');

DROP PROCEDURE IF EXISTS `add_kb_col`;

-- ============================================================
-- 校验（执行后可跑）
-- ============================================================
-- SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_SCHEMA = DATABASE()
--   AND COLUMN_NAME = 'knowledge_base_id'
--   AND TABLE_NAME IN ('biz_industry','biz_industry_product','biz_industry_enterprise','biz_industry_market','plan_info')
-- ORDER BY TABLE_NAME;
-- 预期: 5 行, bigint, YES

-- ============================================================
-- END
-- ============================================================

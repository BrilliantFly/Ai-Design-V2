-- 支付配置表
CREATE TABLE IF NOT EXISTS `dev_pay_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `name` varchar(50) DEFAULT NULL COMMENT '支付方式名称',
  `icon` varchar(255) DEFAULT NULL COMMENT '图标',
  `pay_way` varchar(50) DEFAULT NULL COMMENT '支付渠道',
  `sort` int(11) DEFAULT 0 COMMENT '排序',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `config` text COMMENT '配置JSON',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付配置表';

-- 支付方式表
CREATE TABLE IF NOT EXISTS `dev_pay_way` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `code` varchar(50) DEFAULT NULL COMMENT '编码',
  `name` varchar(50) DEFAULT NULL COMMENT '名称',
  `icon` varchar(255) DEFAULT NULL COMMENT '图标',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态 0=禁用 1=启用',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付方式表';

-- 短信发送记录表
CREATE TABLE IF NOT EXISTS `sms_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `content` text COMMENT '短信内容',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态 0=发送中 1=成功 2=失败',
  `result_msg` varchar(255) DEFAULT NULL COMMENT '返回信息',
  `create_time` bigint(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信发送记录表';

-- 公告记录表
CREATE TABLE IF NOT EXISTS `notice_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `notice_id` bigint(20) DEFAULT NULL COMMENT '公告ID',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `is_read` tinyint(1) DEFAULT 0 COMMENT '是否已读 0=否 1=是',
  `read_time` bigint(20) DEFAULT NULL COMMENT '阅读时间',
  `create_time` bigint(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_notice_id` (`notice_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告记录表';

-- 公告设置表
CREATE TABLE IF NOT EXISTS `notice_setting` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `notice_id` bigint(20) DEFAULT NULL COMMENT '公告ID',
  `notice_title` varchar(255) DEFAULT NULL COMMENT '公告标题',
  `notice_type` varchar(50) DEFAULT NULL COMMENT '通知类型',
  `receive_type` varchar(50) DEFAULT NULL COMMENT '接收类型 all=user all_system=全员',
  `user_ids` text COMMENT '指定用户ID列表',
  `create_time` bigint(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告设置表';

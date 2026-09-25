# 01 - 数据库表结构设计（客户信息调用子域）

> 全部表统一 `biz_` 前缀，归属 `know-boot-biz` 模块，由 `BizSchemaMigration`（`@PostConstruct` + `JdbcTemplate`）自动建表，不再依赖 system 模块 `la_` 存量表。时间字段沿用 plan 模块约定使用 `BIGINT` 毫秒时间戳。

## 1.1 biz_customer（客户主表）

**字段设计**（调研表《客户信息调研.xlsx》"客户信息"Sheet 完整映射）：

```sql
CREATE TABLE biz_customer (
  -- ===== 基础信息-个人情况 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  name            VARCHAR(64)  NOT NULL  COMMENT '客户姓名',
  gender          TINYINT      DEFAULT NULL COMMENT '性别(0:未知 1:男 2:女)',
  age             INT          DEFAULT NULL COMMENT '年龄',
  phone           VARCHAR(128) DEFAULT NULL COMMENT '手机号(AES加密)',
  email           VARCHAR(128) DEFAULT NULL COMMENT '邮箱(AES加密)',
  address         VARCHAR(255) DEFAULT NULL COMMENT '地址',
  region_code     VARCHAR(64)  DEFAULT NULL COMMENT '区域编码(行政区划，用于按区域统计)',
  education       VARCHAR(64)  DEFAULT NULL COMMENT '学历(小学/初中/高中/大专/本科/硕士/博士)',
  education_raw   VARCHAR(255) DEFAULT NULL COMMENT '教育背景详情(学校/专业，用于认知层度分析)',
  occupation      VARCHAR(64)  DEFAULT NULL COMMENT '职业',
  position        VARCHAR(64)  DEFAULT NULL COMMENT '职务/职位',
  personality     VARCHAR(255) DEFAULT NULL COMMENT '性格(外向/内向/理性/感性等)',
  hobby           VARCHAR(255) DEFAULT NULL COMMENT '兴趣爱好',
  values_text     VARCHAR(512) DEFAULT NULL COMMENT '价值观(核心信念/关注点)',
  lifestyle       VARCHAR(512) DEFAULT NULL COMMENT '衣食住行(消费习惯/生活品质信号)',

  -- ===== 基础信息-关系/家庭情况 =====
  marital_status  VARCHAR(16)  DEFAULT NULL COMMENT '婚姻状况(未婚/已婚/离异/保密)',
  family_situation VARCHAR(512) DEFAULT NULL COMMENT '家庭情况(成员构成/子女情况等)',

  -- ===== 客户属性 =====
  customer_type   TINYINT      DEFAULT 1 COMMENT '客户类型(1:个人 2:企业)',
  company_id      BIGINT       DEFAULT NULL COMMENT '所属企业ID(biz_customer_company.id)',
  status          TINYINT      DEFAULT 1 COMMENT '状态(1:潜在 2:意向 3:成交 4:流失)',
  source          VARCHAR(64)  DEFAULT NULL COMMENT '来源(线上推广/转介绍/展会/陌拜)',
  demand_level    INT          DEFAULT NULL COMMENT '需求层级(1-5)',
  value_score     INT          DEFAULT NULL COMMENT '价值评分(1-5)',
  demand_willingness TINYINT   DEFAULT NULL COMMENT '需求意愿(0-100)',
  demand_budget   DECIMAL(12,2) DEFAULT NULL COMMENT '需求预算',
  demand_decision VARCHAR(64)  DEFAULT NULL COMMENT '决策角色(使用者/把关者/决策者)',
  demand_priority TINYINT      DEFAULT NULL COMMENT '需求优先级(1-5)',
  demand_tags     VARCHAR(255) DEFAULT NULL COMMENT '需求标签(JSON数组)',
  demand_desc     VARCHAR(512) DEFAULT NULL COMMENT '需求描述',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  deleted         TINYINT      DEFAULT 0    COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0    COMMENT '删除时间(毫秒时间戳)',

  PRIMARY KEY (id),
  KEY idx_customer_name     (name),
  KEY idx_customer_status   (status, deleted),
  KEY idx_customer_type     (customer_type, deleted),
  KEY idx_customer_company  (company_id),
  KEY idx_customer_region   (region_code, deleted),
  KEY idx_customer_phone    (phone)
) COMMENT = '客户主表';
```

> `phone`/`email` 采用 AES 加密存储（沿用项目 AesUtil 工具），查询展示时 Service 层脱敏。

## 1.2 biz_customer_company（客户所属企业）

```sql
CREATE TABLE biz_customer_company (
  -- ===== 企业基本信息 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  name            VARCHAR(128) NOT NULL  COMMENT '企业名称',
  industry        VARCHAR(64)  DEFAULT NULL COMMENT '所属行业分类',
  scale           VARCHAR(32)  DEFAULT NULL COMMENT '企业规模(初创/小型/中型/大型/集团)',
  business        VARCHAR(512) DEFAULT NULL COMMENT '主要业务',
  main_products   VARCHAR(512) DEFAULT NULL COMMENT '主要产品/服务',
  established_date DATE        DEFAULT NULL COMMENT '成立时间',
  capital         VARCHAR(64)  DEFAULT NULL COMMENT '注册资本',
  address         VARCHAR(255) DEFAULT NULL COMMENT '地址',

  -- ===== 市场表现与竞争优势（调研表扩展） =====
  market_performance   VARCHAR(512) DEFAULT NULL COMMENT '市场表现(营收概况/增长态势)',
  competitive_advantage VARCHAR(512) DEFAULT NULL COMMENT '竞争优势(技术/渠道/品牌)',

  -- ===== 联系人 =====
  contact_name     VARCHAR(64)  DEFAULT NULL COMMENT '联系人姓名',
  contact_phone    VARCHAR(128) DEFAULT NULL COMMENT '联系人手机(AES加密)',
  contact_position VARCHAR(64)  DEFAULT NULL COMMENT '联系人职务',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  deleted         TINYINT      DEFAULT 0    COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0    COMMENT '删除时间(毫秒时间戳)',

  PRIMARY KEY (id),
  KEY idx_company_name (name)
) COMMENT = '客户企业表';
```

## 1.3 biz_customer_profile（客户深度画像，1:1）

> 承载调研表 **动态信息 / 价值信息 / 如何把握** 三层，与 biz_customer 一对一。

```sql
CREATE TABLE biz_customer_profile (
  -- ===== 主键与归属 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  customer_id     BIGINT       NOT NULL  COMMENT '客户ID(biz_customer.id)',

  -- ===== 动态信息(人性/心理学/读心术) =====
  dynamic_info    TEXT         DEFAULT NULL COMMENT '动态信息(人性观察/心理学特征/读心术信号；制度对客户的影响)',

  -- ===== 价值信息(马斯洛需求层次) =====
  value_level     INT          DEFAULT NULL COMMENT '需求层次(1生理 2安全 3社交 4尊重 5自我实现)',
  value_expect    VARCHAR(512) DEFAULT NULL COMMENT '客户期望(对产品或服务的核心期待)',
  value_interest  VARCHAR(512) DEFAULT NULL COMMENT '利益点(客户的利益诉求/关注维度)',

  -- ===== 如何把握(应对策略) =====
  strategy        VARCHAR(1024) DEFAULT NULL COMMENT '应对策略(沟通定位/切入角度)',
  talk_script     TEXT          DEFAULT NULL COMMENT '话术设计(开场/痛点/方案/成交话术)',
  analysis        TEXT          DEFAULT NULL COMMENT '分析(综合判断/下一步动作)',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0    COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0    COMMENT '删除时间',

  PRIMARY KEY (id),
  UNIQUE KEY uk_customer_profile (customer_id)
) COMMENT = '客户深度画像表';
```

## 1.4 biz_customer_followup（跟进记录）

```sql
CREATE TABLE biz_customer_followup (
  id              BIGINT       NOT NULL  COMMENT '主键',
  customer_id     BIGINT       NOT NULL  COMMENT '客户ID(biz_customer.id)',
  type            VARCHAR(16)  DEFAULT NULL COMMENT '跟进方式(电话/面谈/微信/邮件)',
  content         TEXT         DEFAULT NULL COMMENT '跟进内容',
  result          VARCHAR(512) DEFAULT NULL COMMENT '跟进结果',
  next_time       BIGINT       DEFAULT NULL COMMENT '下次跟进时间(毫秒时间戳)',
  create_user     BIGINT       DEFAULT NULL COMMENT '创建人ID',
  create_user_name VARCHAR(64) DEFAULT NULL COMMENT '创建人姓名',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',

  PRIMARY KEY (id),
  KEY idx_followup_customer (customer_id, create_time)
) COMMENT = '客户跟进记录表';
```

## 1.5 biz_customer_industry（客户-行业多对多关联表）

> 核心关联表：客户可选多个行业（多个行业），行业可反查多个客户（多个客户）。

```sql
CREATE TABLE biz_customer_industry (
  -- ===== 主键与关联 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  customer_id     BIGINT       NOT NULL  COMMENT '客户ID(biz_customer.id)',
  industry_id     BIGINT       NOT NULL  COMMENT '行业ID(biz_industry.id，同模块 industry 子域)',

  -- ===== 关联属性 =====
  relation_type   TINYINT      DEFAULT 1 COMMENT '关系类型(1:主营行业 2:关联行业 3:潜在行业)',
  is_main         TINYINT      DEFAULT 0 COMMENT '是否主营行业(0:否 1:是，每个客户至多一个)',
  remark          VARCHAR(255) DEFAULT NULL COMMENT '关联备注(如"客户在该行业的角色")',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0    COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0    COMMENT '删除时间',

  PRIMARY KEY (id),
  UNIQUE KEY uk_customer_industry (customer_id, industry_id),
  KEY idx_ci_industry (industry_id, del_flag)
) COMMENT = '客户-行业关联表';
```

## 1.6 数据关系图

```
biz_customer(客户主表) 1 ───── 1 biz_customer_profile(深度画像)
      │  │
      │  └── N biz_customer_followup(跟进记录)
      │
      │  N ── biz_customer_industry(客户-行业关联) ── N ── biz_industry(行业表)
      │
      └── N biz_customer_company(企业表)  (customer_type=2 时关联)
```

**双向查询示意**：
- 客户详情 → 携带 `industryIds: [2, 5, 9]` 及行业名称列表（关联 `biz_industry`）
- 行业详情 → 携带 `customerIds: [...]` 及客户名称列表（industry 子域反查）

## 1.7 预置数据（远程库 know_boot_v1）

```sql
-- 客户主表（3 条示例客户）
INSERT INTO biz_customer (id, name, gender, age, phone, email, address, customer_type, status, source, company_id, demand_level, value_score, create_time) VALUES
(1, '张三', 1, 30, 'AES_ENC("13800138000")', 'AES_ENC("zhangsan@example.com")', '广东省深圳市南山区', 1, 2, '线上推广', NULL, 4, 4, 1757520000000),
(2, '李四', 1, 35, 'AES_ENC("13900139000")', 'AES_ENC("lisi@example.com")', '上海市浦东新区', 1, 1, '转介绍', NULL, 3, 3, 1757520000000),
(3, '王五', 2, 28, 'AES_ENC("13700137000")', 'AES_ENC("wangwu@example.com")', '北京市朝阳区', 2, 3, '展会', 1, 5, 5, 1757520000000);

-- 客户-行业关联示例（张三：主营"互联网"、关联"人工智能"）
INSERT INTO biz_customer_industry (id, customer_id, industry_id, relation_type, is_main, create_time) VALUES
(1, 1, 1, 1, 1, 1757520000000),  -- 张三 → 互联网
(2, 1, 2, 2, 0, 1757520000000),  -- 张三 → 人工智能(ID=2)
(3, 2, 3, 1, 1, 1757520000000),  -- 李四 → 金融
(4, 3, 4, 1, 1, 1757520000000);  -- 王五 → 制造业
```

> 行业 ID 以同模块 industry 子域 `01-database-schema.md` 预置数据为准。
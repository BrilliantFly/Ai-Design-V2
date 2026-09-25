# 01 - 数据库表结构设计（市场与行业调研子域）

> 全部表统一 `biz_` 前缀，归属 `know-boot-biz` 模块，由 `BizSchemaMigration`（`@PostConstruct` + `JdbcTemplate`）自动建表。时间字段统一 `BIGINT` 毫秒时间戳（对齐 plan 模块约定）。

## 1.1 新增表

### 1.1.1 biz_industry（行业主表）

> 对应调研表 Sheet1「行业（产品与企业）」的基础信息/动态信息/价值信息/行业资源/如何把握/其他（财务指标）。

```sql
CREATE TABLE biz_industry (
  -- ===== 基础信息 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  industry_name   VARCHAR(128) NOT NULL  COMMENT '行业名称',
  definition      VARCHAR(1024) DEFAULT NULL COMMENT '行业定义（边界说明）',
  technology      VARCHAR(1024) DEFAULT NULL COMMENT '核心技术（行业需要的技术/设计能力）',
  industry_code   VARCHAR(32)  DEFAULT NULL COMMENT '行业编码（自定义，便于引用）',
  tags            VARCHAR(256) DEFAULT NULL COMMENT '标签(逗号分隔)',

  -- ===== 产业链结构（三段） =====
  upstream_chain      VARCHAR(1024) DEFAULT NULL COMMENT '上游产业链（原材料/供应商）',
  midstream_chain     VARCHAR(1024) DEFAULT NULL COMMENT '中游产业链（产品制造商/集成商）',
  downstream_channel  VARCHAR(1024) DEFAULT NULL COMMENT '下游销售渠道',
  downstream_marketing VARCHAR(1024) DEFAULT NULL COMMENT '下游营销方式',

  -- ===== 行业格局概况 =====
  development_overview VARCHAR(1024) DEFAULT NULL COMMENT '行业发展概况',
  market_size          VARCHAR(128) DEFAULT NULL COMMENT '市场规模（可含单位）',
  growth_potential     VARCHAR(128) DEFAULT NULL COMMENT '增长潜力/增速',

  -- ===== 动态信息/价值信息/资源/战略 =====
  dynamic_info     TEXT         DEFAULT NULL COMMENT '动态信息（社会/文化/行业/市场变化；制度影响）',
  value_info       TEXT         DEFAULT NULL COMMENT '价值信息（行业价值/机会评估）',
  industry_resources VARCHAR(1024) DEFAULT NULL COMMENT '行业资源（关键资源/人脉/资质）',
  strategy         TEXT         DEFAULT NULL COMMENT '如何把握（布局策略/竞争打法）',

  -- ===== 财务指标（调研表"其他"页） =====
  gross_profit     DECIMAL(12,2) DEFAULT NULL COMMENT '毛利润（销售收入-销售成本）',
  gross_margin     DECIMAL(5,2)  DEFAULT NULL COMMENT '毛利率（%）',
  net_profit       DECIMAL(12,2) DEFAULT NULL COMMENT '净利润（总收入-总费用）',
  net_margin       DECIMAL(5,2)  DEFAULT NULL COMMENT '净利率（%）',

  -- ===== 标准字段 =====
  visibility       TINYINT       DEFAULT 1 COMMENT '可见性(0:私有 1:公开 2:系统预置)',
  sort             INT           DEFAULT 0 COMMENT '排序(越小越前)',
  create_by        BIGINT        DEFAULT NULL COMMENT '创建人',
  create_time      BIGINT        DEFAULT NULL COMMENT '创建时间',
  update_by        BIGINT        DEFAULT NULL COMMENT '更新人',
  update_time      BIGINT        DEFAULT NULL COMMENT '更新时间',
  del_flag         TINYINT       DEFAULT 0 COMMENT '删除标记(0:正常 1:删除)',
  delete_time      BIGINT        DEFAULT 0 COMMENT '删除时间',
  delete_by        BIGINT        DEFAULT NULL COMMENT '删除人',

  PRIMARY KEY (id),
  KEY idx_industry_name (industry_name),
  KEY idx_industry_code (industry_code)
) COMMENT = '行业主表';
```

### 1.1.2 biz_industry_product（行业-产品表）

> 对应调研表 Sheet2「行业（产品）」：产品概念/消费者洞察/利益承诺/支撑点/产品细分/生命周期/产业链角色。

```sql
CREATE TABLE biz_industry_product (
  -- ===== 主键与归属 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  industry_id     BIGINT       NOT NULL  COMMENT '所属行业ID(biz_industry.id)',

  -- ===== 产品定义 =====
  category        VARCHAR(64)  DEFAULT NULL COMMENT '产品分类',
  product_name    VARCHAR(128) NOT NULL  COMMENT '产品名称',
  product_concept TEXT         DEFAULT NULL COMMENT '产品概念（核心定义）',

  -- ===== 消费者洞察 =====
  consumer_insight TEXT        DEFAULT NULL COMMENT '消费者洞察（市场关联点）',
  benefit_promise VARCHAR(512) DEFAULT NULL COMMENT '利益承诺（给客户的利益）',
  support_point   VARCHAR(512) DEFAULT NULL COMMENT '支撑点（承诺的依据）',

  -- ===== 产品细分（核心/基础/附加/潜在） =====
  core_product    VARCHAR(512) DEFAULT NULL COMMENT '核心产品（核心价值层）',
  basic_product   VARCHAR(512) DEFAULT NULL COMMENT '基础产品（基本效用层）',
  additional_product VARCHAR(512) DEFAULT NULL COMMENT '附加产品（服务/售后/增值层）',
  potential_product  VARCHAR(512) DEFAULT NULL COMMENT '潜在产品（未来延伸层）',

  -- ===== 生命周期 =====
  life_cycle      VARCHAR(32)  DEFAULT NULL COMMENT '产品生命周期(导入期/成长期/成熟期/衰退期)',

  -- ===== 产业链角色 =====
  upstream_chain      VARCHAR(1024) DEFAULT NULL COMMENT '上游（原材料）',
  midstream_chain     VARCHAR(1024) DEFAULT NULL COMMENT '中游（产品制造商）',
  downstream_channel  VARCHAR(1024) DEFAULT NULL COMMENT '下游渠道',
  downstream_marketing VARCHAR(1024) DEFAULT NULL COMMENT '下游营销方式',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0 COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0 COMMENT '删除时间',
  delete_by       BIGINT       DEFAULT NULL COMMENT '删除人',

  PRIMARY KEY (id),
  KEY idx_product_industry (industry_id, del_flag)
) COMMENT = '行业产品表';
```

### 1.1.3 biz_industry_enterprise（行业-企业表）

> 对应调研表 Sheet3「行业（企业）」：企业/平台工商信息/核心技术/市场表现/竞争格局/产业链角色。

```sql
CREATE TABLE biz_industry_enterprise (
  -- ===== 主键与归属 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  industry_id     BIGINT       NOT NULL  COMMENT '所属行业ID(biz_industry.id)',

  -- ===== 企业/平台基本信息 =====
  enterprise_type   VARCHAR(32)  DEFAULT NULL COMMENT '企业/平台类型(如:生产商/经销商/平台/SaaS服务商)',
  enterprise_name   VARCHAR(128) NOT NULL  COMMENT '企业/平台名称',
  established_date  DATE         DEFAULT NULL COMMENT '成立时间',
  registered_capital VARCHAR(64) DEFAULT NULL COMMENT '注册资本',
  paid_capital      VARCHAR(64)  DEFAULT NULL COMMENT '实缴资本',
  scale             VARCHAR(50)  DEFAULT NULL COMMENT '企业规模(人数)',
  insured_count     INT          DEFAULT NULL COMMENT '参保人数',
  is_listed         TINYINT      DEFAULT 0 COMMENT '是否上市(0:否 1:是)',

  -- ===== 业务与技术 =====
  main_business    VARCHAR(1024) DEFAULT NULL COMMENT '主要业务',
  core_technology  VARCHAR(512) DEFAULT NULL COMMENT '核心技术',
  products         VARCHAR(1024) DEFAULT NULL COMMENT '产品/服务',

  -- ===== 市场与竞争 =====
  market_performance VARCHAR(1024) DEFAULT NULL COMMENT '市场表现(营收/市占率)',
  competitors      VARCHAR(1024) DEFAULT NULL COMMENT '主要竞争对手',
  advantage        VARCHAR(512) DEFAULT NULL COMMENT '竞争优势',
  disadvantage     VARCHAR(512) DEFAULT NULL COMMENT '竞争不足',

  -- ===== 产业链角色 =====
  upstream_chain      VARCHAR(1024) DEFAULT NULL COMMENT '上游（原材料）',
  midstream_chain     VARCHAR(1024) DEFAULT NULL COMMENT '中游（产品制造商）',
  downstream_channel  VARCHAR(1024) DEFAULT NULL COMMENT '下游渠道',
  downstream_marketing VARCHAR(1024) DEFAULT NULL COMMENT '下游营销方式',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0 COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0 COMMENT '删除时间',
  delete_by       BIGINT       DEFAULT NULL COMMENT '删除人',

  PRIMARY KEY (id),
  KEY idx_enterprise_industry (industry_id, del_flag)
) COMMENT = '行业企业表';
```

### 1.1.4 biz_industry_market（行业-市场表）

> 对应调研表 Sheet4「行业与市场」：需求/商机/商业模式九要素/营销手段。

```sql
CREATE TABLE biz_industry_market (
  -- ===== 主键与归属 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  industry_id     BIGINT       NOT NULL  COMMENT '所属行业ID(biz_industry.id)',

  -- ===== 需求与商机 =====
  demand          TEXT         DEFAULT NULL COMMENT '市场需求（客群规模/痛点）',
  opportunity      TEXT         DEFAULT NULL COMMENT '商机（可切入的机会点）',

  -- ===== 商业模式（价值创造） =====
  value_proposition VARCHAR(512) DEFAULT NULL COMMENT '价值主张（为客户创造什么价值）',
  customer_segment  VARCHAR(512) DEFAULT NULL COMMENT '客户细分',
  channel          VARCHAR(512) DEFAULT NULL COMMENT '渠道通路',
  customer_relation VARCHAR(512) DEFAULT NULL COMMENT '客户关系（如何建立/维护）',
  revenue_source   VARCHAR(512) DEFAULT NULL COMMENT '收入来源',
  key_resource     VARCHAR(512) DEFAULT NULL COMMENT '关键资源',
  key_partner      VARCHAR(512) DEFAULT NULL COMMENT '关键伙伴',
  key_activity     VARCHAR(512) DEFAULT NULL COMMENT '关键活动',
  cost_structure   VARCHAR(512) DEFAULT NULL COMMENT '成本结构',

  -- ===== 价值评价与分配 =====
  value_evaluation TEXT         DEFAULT NULL COMMENT '价值评价',
  value_distribution TEXT       DEFAULT NULL COMMENT '价值分配（产业链利润分配）',

  -- ===== 营销 =====
  competition_method TEXT       DEFAULT NULL COMMENT '竞争手段（行业/产品/企业三层）',
  promo_channel     TEXT        DEFAULT NULL COMMENT '推广引流（企业/产品两个维度）',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0 COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0 COMMENT '删除时间',
  delete_by       BIGINT       DEFAULT NULL COMMENT '删除人',

  PRIMARY KEY (id),
  UNIQUE KEY uk_market_industry (industry_id)
) COMMENT = '行业市场表';
```

## 1.2 关联客户子域（多对多）

> 行业 ⇄ 客户 多对多关联复用同模块 customer 子域的 `biz_customer_industry` 表（见《客户信息调用设计》01 文档 1.5），行业子域写入与读取同一张表：
> `industry_id, customer_id, relation_type, is_main, remark`
> 同模块部署，Service 层直接依赖 customer 子域 Mapper，无跨服务调用。

## 1.3 索引设计

```sql
-- 已随表内置：idx_industry_name / idx_industry_code / idx_product_industry / idx_enterprise_industry
-- 客户分布反查（复用 customer 子域已有 idx_ci_industry）
-- SELECT ... FROM biz_customer_industry ci WHERE ci.industry_id = ? AND ci.del_flag = 0
CREATE INDEX idx_ci_industry ON biz_customer_industry(industry_id, del_flag);
```

## 1.4 数据关系图

```
biz_industry(行业主表) 1 ───── 1 biz_industry_market(行业市场/商业模式)
      │  │
      │  ├── N biz_industry_product(行业产品)
      │  └── N biz_industry_enterprise(行业企业)
      │
      │  N ── biz_customer_industry(行业-客户关联，共享) ── N ── biz_customer(客户表)
      │
      └── 财务指标(gross_profit/gross_margin/net_profit/net_margin) 内嵌主表
```

## 1.5 预置数据（远程库 know_boot_v1）

```sql
-- 行业主表（预置 5 个行业，ID 供 customer 子域关联使用）
INSERT INTO biz_industry (id, industry_name, definition, industry_code, sort, visibility, create_time) VALUES
(1, '互联网/IT',     '以信息技术为核心的软件、硬件、网络服务行业', 'IT',      1, 2, 1757520000000),
(2, '人工智能',      '涵盖机器学习、计算机视觉、NLP 等的智能技术产业', 'AI',     2, 2, 1757520000000),
(3, '金融',          '银行、证券、保险、投资等金融服务行业',        'FIN',     3, 2, 1757520000000),
(4, '制造业',        '以机械、电子、化工等为主的实体制造行业',      'MFG',     4, 2, 1757520000000),
(5, '医疗健康',      '医药、器械、医疗服务、健康管理行业',          'MED',     5, 2, 1757520000000);
```

> 行业-产品/企业/市场预置数据由业务录入时填充，此处不做种子示例（避免示意数据污染）。
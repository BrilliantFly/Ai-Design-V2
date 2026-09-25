# 市场与行业调研系统设计方案 V2

> 创建日期：2026-09-12
> 版本：V2.0（调整：合并为 business 模块、表前缀 biz、支持单例/微服务双模式、远程数据库开发）
> 状态：设计稿

## 背景

市场与行业调研支撑企业**进入新行业、评估商机、定位竞争**的决策链路。调研成果来自《市场与行业调研.xlsx》四维调研模型：

1. **行业（产品与企业）**：行业定义、技术边界、产品概览、上下游产业链、企业/平台格局
2. **行业（产品）**：产品概念、消费者洞察、产品细分（核心/基础/附加/潜在）、生命周期、产业链角色
3. **行业（企业）**：企业/平台工商信息、核心技术、市场表现、竞争格局（对手/优势/不足）
4. **行业与市场**：需求、商机、商业模式（价值主张/客户细分/渠道/收入/资源/伙伴/活动/成本）、营销手段

本子域与 **客户信息调用子域** 同属 `know-boot-biz` 业务模块，双向打通：**行业可选择拥有的客户（多个客户）**，客户侧也可归属多个行业，形成多对多关联，支撑"行业客户分布"与"客户行业画像"两个视角的联动分析。

## 设计目标

1. **行业四维全景建模**：定义/技术/产品/产业链/企业/商业模式/营销逐层落地
2. **行业 ⇄ 客户多对多**：`biz_customer_industry` 中间表（与客户子域共享），行业侧反查客户分布
3. **产业链结构化管理**：上游/中游/下游三段建模，每段含渠道与营销
4. **商业模式九要素建模**：价值主张/客户细分/渠道通路/客户关系/收入来源/关键资源/关键伙伴/关键活动/成本结构
5. **财务指标内置**：毛利/毛利率/净利/净利率四指标（调研表"其他"页）
6. **模块双模式启动**：归入 `know-boot-biz` 模块，支持 **单例（standalone）** 与 **微服务（microservice）** 两种启动方式
7. **远程数据库开发**：开发期直连远程库 `101.37.83.88/know_boot_v1`，表统一 `biz_` 前缀

## 核心实体（全部 biz_ 前缀）

| 实体 | 表名 | 说明 |
|------|------|------|
| Industry | `biz_industry` | 行业主表（定义/技术/产业链/动态/资源/战略） |
| IndustryProduct | `biz_industry_product` | 行业-产品（细分/概念/洞察/生命周期） |
| IndustryEnterprise | `biz_industry_enterprise` | 行业-企业（工商/技术/市场/竞争） |
| IndustryMarket | `biz_industry_market` | 行业-市场（需求/商机/商业模式/营销） |
| CustomerIndustry | `biz_customer_industry` | 行业-客户多对多关联表（共享自 customer 子域） |
| Customer | `biz_customer` | 客户表（customer 子域提供，行业侧引用其 ID） |

## 行业 ⇄ 客户多对多关系

```
biz_industry ──┐                      ┌── biz_customer（customer 子域）
               │  biz_customer_industry │
biz_industry ──┘  (industry_id,      └── biz_customer
                   customer_id)
```

| 方向 | 场景 | 实现 |
|------|------|------|
| 行业 → 客户 | 行业详情页查看客户分布 | `biz_customer_industry` 按 industry_id 反查 |
| 客户 → 行业 | 客户建档时多选行业 | customer 子域写入 `biz_customer_industry` 多行 |

## 模块落位（know-boot-biz，industry 子域）

```
know-boot-biz/                            # 业务 Maven 模块（与 customer 子域同模块）
└── src/main/java/com/know/knowboot/
    ├── KnowBootBizApplication.java       # 微服务独立启动类（@EnableDiscoveryClient）
    ├── config/
    │   └── BizSchemaMigration.java       # @PostConstruct + JdbcTemplate 建表（全部 biz_ 前缀）
    ├── controller/biz/industry/          # IndustryController / IndustryProductController /
    │                                     # IndustryEnterpriseController / IndustryMarketController
    ├── dto/biz/industry/                 # IndustryDTO / ProductDTO / EnterpriseDTO / MarketDTO
    ├── entity/biz/industry/              # BizIndustry / BizIndustryProduct / BizIndustryEnterprise /
    │                                     # BizIndustryMarket
    ├── mapper/biz/industry/              # BizIndustryMapper / ...（IBaseMapper）
    └── service/biz/industry/             # IBizIndustryService / ... + impl/
└── src/main/resources/
    ├── application.yml                   # 公共配置 + profile 切换入口
    ├── application-standalone.yml        # 单例模式：直连远程库、关闭 Seata/Feign
    └── application-microservice.yml      # 微服务模式：Nacos 注册发现、开启 Seata/Feign
```

## 双模式启动（对齐 know-boot 架构）

know-boot 支持**单例（单体）启动**与**微服务启动**，biz 模块两种方式均可用：

| 模式 | 启动方式 | 说明 |
|------|---------|------|
| 单例 standalone | ① `KnowBootSystemApplication` 聚合启动（扫描 `com.know` 全包，`@MapperScan("com.know.*.mapper")`）<br>② biz 模块独立 `java -jar` + `--spring.profiles.active=standalone` | 直连远程库、关闭 Seata/Feign，单实例运行 |
| 微服务 microservice | biz 模块独立 `java -jar` + `--spring.profiles.active=microservice` | 注册 Nacos（39.98.108.121:10006）、开启 Seata/Feign；网关 `Path=/biz/**` → `lb://biz` 路由（需在网关配置中新增） |

> **开发约定**：本地开发默认用 `standalone` 模式 + 远程数据库。行业子域与客户子域同模块，跨子域直接 Spring Bean 注入调用，无网络开销。

## 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表结构设计（4 张行业主表 + 产业链/商业模式/财务建模 + 客户反查视图） |
| [02-backend-api.md](./02-backend-api.md) | 后端 API 接口设计（行业 CRUD + 产品/企业/市场子资源 + 客户分布反查） |
| [03-frontend-design.md](./03-frontend-design.md) | 前端页面与组件设计（行业详情四 Tab + 客户分布面板） |
| [04-data-flow.md](./04-data-flow.md) | 数据流程与实例化逻辑（调研录入 → 行业全景 → 客户联动） |
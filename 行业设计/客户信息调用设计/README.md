# 客户信息调用系统设计方案 V2

> 创建日期：2026-09-12
> 版本：V2.0（调整：合并为 business 模块、表前缀 biz、支持单例/微服务双模式、远程数据库开发）
> 状态：设计稿

## 背景

客户信息调用是 **business（biz）业务模块** 的核心子域之一。为支撑**销售线索全生命周期管理**，需将客户信息完整落地为后端能力，并打通与**市场与行业调研子域**的双向关联：

1. **客户可关联多个行业**：一个客户可能横跨多个行业（如"智能制造+工业软件"），需支持多选
2. **行业可关联多个客户**：行业调研可反查该行业的客户分布，辅助市场定位与投放决策
3. 客户画像三维度（基础信息 / 动态信息 / 价值信息 / 如何把握）完整建模

## 设计目标

1. **客户 360° 画像**：基础信息（个人/家庭/企业）+ 动态信息（人性心理学）+ 价值信息（马斯洛需求）+ 应对策略（话术设计）逐层建模
2. **客户 ⇄ 行业多对多**：中间表 `biz_customer_industry` 承载双向关联，客户侧可选多个行业、行业侧可反查多个客户
3. **加密字段规范**：手机号/邮箱沿用 AES 加密存储
4. **模块双模式启动**：归入 `know-boot-biz` 模块，支持 **单例（standalone）** 与 **微服务（microservice）** 两种启动方式
5. **远程数据库开发**：开发期直连远程库 `101.37.83.88/know_boot_v1`，表统一 `biz_` 前缀

## 核心实体（全部 biz_ 前缀、全新建表）

| 实体 | 表名 | 说明 |
|------|------|------|
| Customer | `biz_customer` | 客户主表 |
| CustomerCompany | `biz_customer_company` | 客户所属企业 |
| CustomerProfile | `biz_customer_profile` | 客户深度画像（动态信息/价值信息/如何把握） |
| CustomerFollowup | `biz_customer_followup` | 跟进记录 |
| CustomerIndustry | `biz_customer_industry` | **客户-行业多对多关联表** |
| Industry | `biz_industry` | 行业表（同模块 industry 子域提供，客户侧引用其 ID） |

> 注：不再复用 system 模块的 `la_` 存量表，业务表全部以 `biz_` 前缀新建，保证 biz 模块可独立部署、独立迁移，与系统表完全解耦。

## 客户 ⇄ 行业多对多关系

```
biz_customer ──┐                      ┌── biz_industry（同模块 industry 子域）
               │  biz_customer_industry │
biz_customer ──┘  (customer_id,      └── biz_industry
                   industry_id)
```

| 方向 | 场景 | 实现 |
|------|------|------|
| 客户 → 行业 | 新建/编辑客户时勾选多个行业 | 写入 `biz_customer_industry` 多行 |
| 行业 → 客户 | 行业调研详情查看客户分布 | `biz_customer_industry` 按 industry_id 反查 |

## 模块落位（know-boot-biz，customer + industry 双子域）

```
know-boot-biz/                            # 新业务 Maven 模块（根 pom 注册）
├── pom.xml
└── src/main/java/com/know/knowboot/
    ├── KnowBootBizApplication.java       # 微服务独立启动类（@EnableDiscoveryClient）
    ├── config/
    │   └── BizSchemaMigration.java       # @PostConstruct + JdbcTemplate 建表（全部 biz_ 前缀）
    ├── controller/biz/customer/          # CustomerController / CustomerCompanyController /
    │                                     # CustomerFollowupController
    ├── controller/biz/industry/          # IndustryController / IndustryProductController /
    │                                     # IndustryEnterpriseController / IndustryMarketController
    ├── dto/biz/customer/                 # CustomerRequest / CustomerProfileDTO / CustomerIndustryDTO
    ├── dto/biz/industry/                 # IndustryDTO / ProductDTO / EnterpriseDTO / MarketDTO
    ├── entity/biz/customer/              # BizCustomer / BizCustomerCompany / BizCustomerProfile /
    │                                     # BizCustomerFollowup / BizCustomerIndustry
    ├── entity/biz/industry/              # BizIndustry / BizIndustryProduct / BizIndustryEnterprise /
    │                                     # BizIndustryMarket
    ├── mapper/biz/customer/              # BizCustomerMapper / ...（IBaseMapper）
    ├── mapper/biz/industry/              # BizIndustryMapper / ...
    └── service/biz/
        ├── customer/                     # IBizCustomerService / ... + impl/
        └── industry/                     # IBizIndustryService / ... + impl/
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

> **开发约定**：本地开发默认用 `standalone` 模式 + 远程数据库（见 application-standalone.yml 示例）。Mapper 放 `com.know.knowboot.mapper.biz.*` 可同时被单体聚合与 biz 独立启动扫描到。

```yaml
# application-standalone.yml（开发直连远程库）
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://101.37.83.88:3306/know_boot_v1?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: root
    password: 123456aA@
  redis:
    host: 127.0.0.1      # 远程 Redis 经 SSH 隧道转发到本地 16379
    port: 16379
    database: 6
know:
  mode: standalone
seata:
  enabled: false
feign:
  circuitbreaker:
    enabled: false
  loadbalancer:
    enabled: false
```

## 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表结构设计（5 张业务表 + 多对多中间表 + 建表 SQL，biz_ 前缀） |
| [02-backend-api.md](./02-backend-api.md) | 后端 API 接口设计（客户 CRUD + 画像 + 行业关联 + 报表统计） |
| [03-frontend-design.md](./03-frontend-design.md) | 前端页面与组件设计（客户列表/详情/画像编辑/行业多选） |
| [04-data-flow.md](./04-data-flow.md) | 数据流程与实例化逻辑（客户建档 → 画像完善 → 行业关联 → 跟进闭环） |
# know-boot 开发规范

> 本文档基于当前代码库实际结构和代码风格梳理，**仅记录代码中实际存在的约定**，不做主观臆造。路径均为相对或绝对文件路径，关键位置均附带简短代码片段。

## 1. 模块结构与 Maven 布局

**项目根路径：** `E:\Ai-Project\Ai-Service\know-boot`

**父 POM：** `E:\Ai-Project\Ai-Service\know-boot\pom.xml` (Spring Boot 2.6.6，Java 1.8，依赖版本统一在 `<dependencyManagement>` 中管理)

**子模块清单（root pom.xml 26-37 行）：**

```xml
<modules>
    <module>know-boot-base</module>
    <module>know-boot-start</module>
    <module>know-boot-system</module>
    <module>know-boot-api</module>
    <module>know-boot-accumulate</module>
    <module>know-boot-common</module>
    <module>know-boot-camera</module>
    <module>know-boot-plan</module>
    <module>know-boot-knowledge</module>
    <module>know-boot-biz</module>
</modules>
```

**模块说明（按包扫描路径 `com.know.*`）：**

- `know-boot-base`（`com.know.knowboot.base` 等基础设施）：基础实体、工具类、配置、全局处理相关类。示例：`know-boot-base/src/main/java/com/know/knowboot/base/BaseEntity.java`。
- `know-boot-common`（`com.know.knowboot.*`）：公共核心、枚举、异常、Mapper/Entity 公共部分、工具类。示例：`know-boot-common/src/main/java/com/know/knowboot/core/AjaxResult.java`、`com/know/knowboot/core/basics/IBaseMapper.java`。
- `know-boot-system`：系统管理、租户、认证、字典（平铺/级联）等核心业务模块。启动类：`know-boot-system/src/main/java/com/know/knowboot/KnowBootSystemApplication.java`（`@MapperScan(basePackages = {"com.know.*.mapper"})`，`@ComponentScan(basePackages = {"com.know"}, excludeFilters = {...feign.*})`）。
- `know-boot-plan`：计划管理（计划、日程、习惯、四象限、模板等）。示例：`know-boot-plan/src/main/java/com/know/knowboot/controller/plan/PlanInfoController.java`。
- `know-boot-biz`：客户与行业业务（行业主体、客户、企业、产品等）。示例：`know-boot-biz/src/main/java/com/know/knowboot/controller/biz/industry/BizIndustryController.java`。
- `know-boot-knowledge`：知识库模块。
- `know-boot-camera`：摄像头相关业务。
- `know-boot-start`：启动器/Starter 模块集（cloud/elasticsearch/gateway/rabbitmq/workflow 等）。
- `know-boot-accumulate`：子模块集（cas/cloud-gateway/cloud-hystrix/cloud-ribbon/fundamental/oauth/security 等）。
- `know-boot-api`：API 暴露相关。

**包命名约定：** 按业务域组织，如 `com.know.knowboot.controller.plan`、`com.know.knowboot.service.plan.impl`、`com.know.knowboot.mapper.plan`、`com.know.knowboot.entity.plan`、`com.know.knowboot.config`。

**Maven Profile 相关（参考）：** 根 POM 提供 `dev/test/prod/SpringCloud` profile（`pom.xml` 600-684 行）；`know-boot-system/pom.xml` 单机 `standalone`（默认激活）与微服务 `microservice` 区分（微服务引入 `cloud-know-boot-starter`），详见 `docs/dual-mode-guide.md`。

---

## 2. 数据库设计与命名约定

**MySQL 8.x**（`pom.xml` 52 行 `mysql-connector-java 8.0.22`），**JDBC URL** 示例：`know-boot-system/src/main/resources/application-dev.yml:35` `jdbc:mysql://101.37.83.88:3306/know_boot_v1?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&useSSL=false&serverTimezone=Asia/Shanghai`

**表命名：** 业务表统一下划线命名（实际代码中存在 `plan_info`、`plan_schedule_event`、`biz_industry`、`sys_cascade_dict_type`、`sys_cascade_dict_data`、`sys_role_menu` 等）。DDL 通过 `JdbcTemplate` 的 **Schema Migration** 模式（`@PostConstruct`）自动创建/补列。

**通用字段（实体设计模式）：**

- **ID 主键：** 
  - `BaseEntity`（`know-boot-base/.../BaseEntity.java:19-21`）：`@TableId(type = IdType.ASSIGN_ID)`，字段类型 `String id`。
  - **业务实体（plan/biz）：** 多数使用 `@TableId(value="id", type=IdType.ASSIGN_ID)`，字段类型 `Long id`。示例：`PlanInfo.java:22` `private Long id;`、`BizIndustry.java:24` `private Long id;`。
  - **系统/字典类实体：** 部分使用 `IdType.AUTO`。示例：`SysCascadeDictType.java:24` `@TableId(value="id", type=IdType.AUTO)` `private Long id;`。
- **逻辑删除：**
  - `PlanInfo.java:90-93`：`@TableLogic(value="0", delval="1")`，字段 `private Long deleteTime = 0L;`（部分业务表使用 `delete_time` 时间戳）。
  - `BizIndustry.java:117-122`：`@TableLogic(value="0", delval="1")`，字段 `private Integer delFlag;`、`private Long deleteTime;`。
  - `SysCascadeDictType.java:52-54`：`@TableLogic`，字段 `private Integer delFlag;`（`delval` 未显式指定，使用 MP 默认）。
- **审计字段（创建/更新时间）：**
  - `BaseEntity`：`createBy(String)`、`createTime(Date)`（`@TableField(fill=FieldFill.INSERT)`）、`updateBy(String)`、`updateTime(Date)`（`@TableField(fill=FieldFill.UPDATE)`），并使用 `@JsonFormat(timezone="GMT+8", pattern="yyyy-MM-dd HH:mm:ss")`、`@DateTimeFormat`。
  - **业务实体（plan/biz）：** 使用 `Long` 毫秒时间戳形式：`createBy(Long)/createTime(Long)/updateBy(Long)/updateTime(Long)`；删除使用 `deleteTime(Long)`。示例：`PlanInfo.java:78-93`。
  - 字典实体：`createBy(String)/createTime(Long)/updateBy(String)/updateTime(Long)`（`SysCascadeDictType.java:40-54`）。

**数据库脚本：** 根目录 `db/` 下按日期/主题存放 SQL（如 `db/know_boot_v1.sql`、`db/20260317/plan_schedule.sql` 等），用于参考。生产部署参考 `standalone/deploy.js`（指定 DB `know_boot_v1`、Redis `16379` db1，见 deploy.js 63-72 行）。

---

## 3. MyBatis-Plus 数据访问约定

**基础 Mapper：** 所有业务 Mapper 接口继承 `IBaseMapper<T>`。路径：`know-boot-common/src/main/java/com/know/knowboot/core/basics/IBaseMapper.java:24-25`

```java
@Mapper
public interface IBaseMapper<T> extends MPJBaseMapper<T> {
    // 提供 sum(...)、setSearch(MPJQueryWrapper<T>, ..., String[])、
    // setSearch(QueryWrapper<T>, ..., String[]) 等辅助方法
}
```

- 依赖 `MyBatis-Plus 3.5.2`（`pom.xml:61`）、`MyBatis-Plus-Join 1.2.4`（`pom.xml:62,199-202`）。
- Mapper 接口示例：`PlanInfoMapper.java:11` `extends IBaseMapper<PlanInfo>`；`BizIndustryMapper` 类似（`know-boot-biz/.../mapper/biz/industry/BizIndustryMapper.java`）。
- Mapper XML 定位：`mybatis-plus.mapper-locations: classpath*:/mapper/**Mapper.xml`（`application-dev.yml:78`）。实际存在的 XML：`know-boot-system/src/main/resources/mapper/tenant/SysRoleMenuMapper.xml`（批量插入示例）。大部分 CRUD 基于 MP 注解/内置方法，不强制要求 XML。

**分页配置：**

- **system 模块：** `know-boot-system/src/main/java/com/know/knowboot/config/MybatisPlusConfig.java` 注册 `MybatisPlusInterceptor`，添加 `TenantLineInnerInterceptor`（多租户，优先级在前）与 `PaginationInnerInterceptor(DbType.MYSQL)`（行 20-36）。
- **biz 模块：** `know-boot-biz/src/main/java/com/know/knowboot/config/MybatisPlusConfig.java` 仅添加 `PaginationInnerInterceptor(DbType.MYSQL)`（行 16-21）。

**Service 层约定：** Service 接口命名 `I{Entity}Service`，实现类命名 `{Entity}ServiceImpl`，并继承 `ServiceImpl<Mapper, Entity>`。示例：`IPlanInfoService.java:11`、`PlanInfoServiceImpl.java:23`；`IBizIndustryService.java`、`BizIndustryServiceImpl.java:47`。

**查询助手：** `IBaseMapper#setSearch(...)` 提供基于 `conditions` 字符串数组的条件构造（支持 `=, <>, >, >=, <, <=, between/notBetween, like/notLike/likeLeft/likeRight, in/notIn, datetime`，可指定类型 `int/long/str`），同时支持 `MPJQueryWrapper` 与 `QueryWrapper` 两种重载（`IBaseMapper.java:51-317`）。

**实体注解：** 使用 `@Data`、`@TableName("table_name")`、`@TableId(...)`、`@TableField(...)`、`@TableLogic(...)`，必要时 `@ApiModel/@ApiModelProperty`（Swagger）。

---

## 4. 统一响应与异常处理

### 4.1 统一响应体

项目中存在 **两套响应模式**，实际使用场景不同：

**A. 新版 `AjaxResult<T>`（common 模块，推荐新模块使用）：** 路径 `know-boot-common/src/main/java/com/know/knowboot/core/AjaxResult.java`

- 字段：`Integer code`、`String msg`、`T data`、`Integer show`（是否显示错误信息）。
- 静态工厂：`success()`、`success(T)`、`success(String)`、`success(Integer code, String msg, T data, ...)` 等；`failed(...)` 同理。
- 默认成功：`ErrorEnum.SUCCESS.getCode()=1`，失败：`ErrorEnum.FAILED.getCode()=0`，`show` 由 `ErrorEnum.SHOW_MSG/HIDE_MSG` 控制（`AjaxResult.java:47-49,92,156-168`）。

**B. 旧版 `Result<T>`（base 模块）：** 路径 `know-boot-base/src/main/java/com/know/knowboot/base/Result.java`

- 字段：`boolean success`、`String message`、`Integer code`（默认0，成功 `ResultCodeEnum.REQUEST_SUCCESS`）、`T result`、`long timestamp`。
- 静态方法：`ok()`/`ok(msg)`/`ok(data)`、`error(msg/data)`/`error(code,msg)`/`error500(msg)`。

**实际使用：** `PlanInfoController`、`BizIndustryController`、`SysCascadeDictController`、`AuthController` 等控制器统一使用 `AjaxResult`（见各 Controller 返回值）。`know-boot-base` 的 `Result` 主要用于旧有代码路径。

**状态码枚举：** `ErrorEnum`（`know-boot-common/src/main/java/com/know/knowboot/enums/ErrorEnum.java`）定义基础码值（SUCCESS=1、FAILED=0、参数校验/类型/请求方法/断言错误等，含 LOGIN/TOKEN/PERMISSION/404/SYSTEM）。

---

### 4.2 全局异常处理

**全局异常处理器：** `know-boot-common/src/main/java/com/know/knowboot/exception/GlobalException.java`

- `@ControllerAdvice`、`@Slf4j`
- `@ExceptionHandler(Exception.class)`：统一处理未知异常，返回 `AjaxResult.failed(ErrorEnum.SYSTEM_ERROR.getCode(), e.getMessage())`；`GlobalConfig.debug` 时打印堆栈（`line 30-39`）。
- `@ExceptionHandler(NoHandlerFoundException.class)`：404 → `REQUEST_404_ERROR`（`44-49`）。
- `@ExceptionHandler(BaseException.class)`：自定义业务异常（`52-62`）。
- 参数校验：`BindException`（`67-75`）、`MissingServletRequestParameterException`（`78-87`）、`MethodArgumentNotValidException`（`90-100`）→ 返回 `ErrorEnum.PARAMS_VALID_ERROR`，取首个字段错误消息。
- 类型不匹配：`HttpMessageNotReadableException`（`103-112`）→ `PARAMS_TYPE_ERROR`，截取 `;` 前部分。
- 请求方法：`HttpRequestMethodNotSupportedException`（`115-124`）→ `REQUEST_METHOD_ERROR`。
- 断言：`IllegalArgumentException`（`127-136`）→ `ASSERT_ARGUMENT_ERROR`。
- MyBatis-Plus：`MybatisPlusException`（`139-148`）→ `ASSERT_MYBATIS_ERROR`。

**异常基类：** `BaseException`（`know-boot-common/src/main/java/com/know/knowboot/exception/BaseException.java`）：字段 `Integer code, String msg, Integer show`，继承 `RuntimeException`。

**业务异常子类示例（common）：** `OperateException.java`、`PaymentException.java`、`LoginException.java` 等位于 `know-boot-common/src/main/java/com/know/knowboot/exception/`。

---

## 5. API 设计约定

**REST 风格：** 控制器使用 `@RestController`，基础路径以 `/api/...` 开头。

**示例路径：**

- 计划：`@RequestMapping("/api/plan/info")`（`PlanInfoController.java:20`） → `/page`、`/{id}`、`/{id}/progress`、`/{id}/status`、`/{id}/to-schedule` 等。
- 行业：`@RequestMapping("/api/biz/industry")`（`BizIndustryController.java:20`） → `/page`、`/list`、`/tree`、`/{id}`、`/{id}/customers`、`/statistics`。
- 级联字典：`@RequestMapping("/api/system/cascade-dict")`（`SysCascadeDictController.java:21`） → `/type/*`、`/data/*`（树形 `/data/tree`、列表 `/data/list`）。
- 认证：`@RequestMapping("/api")`（`AuthController.java:24`） → `/login/account`、`/login/refreshToken`、`/login/getUserInfo`、`/login/logout`。

**分页：** 分页参数统一采用 `@RequestParam(defaultValue="1") Integer pageNum, @RequestParam(defaultValue="10") Integer pageSize`，返回 `IPage<T>` 或封装 `PageResult<T>`（见第6节）。Controller 层直接将 `IPage` 包装进 `AjaxResult.success(...)`（如 `PlanInfoController.page` 返回 `AjaxResult<IPage<PlanInfo>>`，`BizIndustryController.page` 同理）。

**参数接收：** 查询条件使用实体接收（`@GetMapping("/page") public AjaxResult<IPage<PlanInfo>> page(PlanInfo query, ...)`），提交数据使用 `@RequestBody`（POST/PUT）。路径参数 `@PathVariable`。

**前端代理约定（参考）：** Uni-App 请求前缀 `/api`，Nginx 单机模式下 `/api/*` → `/know-boot/*`（`docs/dual-mode-guide.md:246-275`）；微服务模式 `/api/*` → Gateway（9999）。

**Swagger：** 使用 `springfox-boot-starter 3.0.0` + `knife4j-spring-boot-starter 3.0.3`（`pom.xml:175-187`），类/方法加 `@Api`、`@ApiOperation`、`@ApiParam`。

---

## 6. 分页与数据封装

**MyBatis-Plus 原生分页：** Service 层使用 `page(new Page<>(pageNum,pageSize), wrapper)`（`PlanInfoServiceImpl.java:40`），Controller 返回 `IPage<T>` 包装在 `AjaxResult` 中。

**自定义分页封装：** `PageResult<T>`（`know-boot-common/src/main/java/com/know/knowboot/core/PageResult.java`）提供静态方法：

```java
public static <T> PageResult<T> of(List<T>, long total, int pageNo, int pageSize);
public static <T> PageResult<T> iPageHandle(IPage<T> iPage);  // 从 IPage 提取
public static <T> PageResult<T> iPageHandle(Long total, Long pageNo, Long size, List<T> list, Map<String,Object> extend);
public static <T> PageResult<T> empty();
```

字段：`count(Long)`、`page_no(Integer)`、`page_size(Integer)`、`lists(List<T>)`、`extend(Map<String,Object>)`（蛇形/小写命名，与前端约定一致）。

**使用方式：** 当前业务 Controller 多直接返回 `IPage`（通过 MP），`PageResult` 作为可选的统一分页 VO 存在于 common/core。

---

## 7. 认证、权限与租户

### 7.1 Sa-Token 认证

**框架：** `sa-token-spring-boot-starter 1.32.0`、`sa-token-dao-redis-jackson 1.32.0`（`pom.xml:232-244`）。

**配置：** `know-boot-system/src/main/resources/application-dev.yml:94-104`

```yaml
sa-token:
  token-name: token        # token名称
  timeout: 2592000          # 30天（秒）
  activity-timeout: -1
  is-concurrent: true
  is-share: false
  token-style: random-64
  is-print: false
  is-log: false
```

**登录登出：** `AuthController`（`know-boot-system/.../controller/AuthController.java`）
- 登录：`@PostMapping("/login/account")`，校验账号密码（`BCryptPasswordEncoder`，对 `123456` 做了测试兼容逻辑 `line 59-66`），调用 `StpUtil.login(user.getId())` 获取 `token`，返回 `{token, tokenName, userId, username, realname}`（`line 77-94`）。
- 刷新：`@PostMapping("/login/refreshToken")` 校验登录状态，调用 `StpUtil.renewTimeout(...)`（`line 101-121`）。
- 用户信息：`@GetMapping("/login/getUserInfo")` 根据 `StpUtil.getLoginId()` 查询用户信息（`line 124-162`）。
- 登出：`@GetMapping("/login/logout")` 调用 `StpUtil.logout()` 并记录日志（`line 165-185`）。
- Token 名称：`token`（请求头/参数使用该名称）。

**拦截器/配置类：** `SaTokenConfig.java`（空配置类，实际参数从 yml 读取）。系统拦截器 `KnowBootSystemInterceptor.java` 位于 `know-boot-system/src/main/java/com/know/knowboot/KnowBootSystemInterceptor.java`（按需校验 `/api`、`/adminapi` 路径，支持 `@NotLogin`/`@NotPower` 注解）。

---

### 7.2 多租户

**插件配置：** `TenantLineInnerInterceptor` + `CustomTenantLineHandler`。

- **system 模块 MP 配置：** `know-boot-system/config/MybatisPlusConfig.java:20-36` — 先添加租户拦截器，再添加分页拦截器。
- **自定义处理器：** `know-boot-system/config/CustomTenantLineHandler.java:19-94`
  - 忽略表集合 `IGNORE_TENANT_TABLES`（静态初始化）：`sys_tenant`、`sys_dict_type`、`sys_dict_data`、`sys_cascade_dict_type`、`sys_cascade_dict_data`、`sys_permission`、`sys_role_permission`、`sys_menu_permission`、`sys_oper_log`、`sys_login_log`、`sys_user`、`sys_role`（`line 25-44`）。
  - `ignoreTable(String tableName)`：对 `sys_*` 前缀做短名匹配；若当前为系统租户（`TenantContextHolder.isSystemTenant()`）也跳过过滤（`line 64-84`）。
  - 租户列名：`tenant_id`（`line 92`）。
  - 租户ID 来源：`TenantContextHolder.getTenantId()` → 返回 `LongValue`（`line 50-55`）。
- **上下文：** `TenantContextHolder`（ThreadLocal）默认租户ID `0` 表示系统租户（从代码可推断，结合 `isSystemTenant()` 判断）。

---

## 8. 缓存、中间件

**Redis：** 依赖 `spring-boot-starter-data-redis`（`pom.xml:545`）、`commons-pool2`（`pom.xml:556`）、`redisson 3.11.0`（`pom.xml:560-564`）、`jetcache-starter-redis 2.6.2`（`pom.xml:566-570`）。

**配置（dev）：** `application-dev.yml:57-69`
- host `127.0.0.1`、port `16379`、password 空、database `6`、timeout `5000`、lettuce 连接池配置。
- `know.redisson.enabled: false`（`line 140`），需要时改为 true。

**部署环境 Redis：** `standalone/deploy.js:69-72` 配置 `REDIS.database: 1`（与 application-dev 中 db6 不一致，属于配置差异，文档仅记录实际配置位置，不推断优先级）。

**缓存框架：** 启用 `@EnableCaching`、`@EnableCreateCacheAnnotation`、`@EnableMethodCache(basePackages="com.know.knowboot")`（`KnowBootSystemApplication.java:23-27`）。基类提供 Redis 工具（`know-boot-base/src/main/java/com/know/knowboot/redis/...`）。

---

## 9. 字典与级联字典

### 9.1 级联字典（系统级）

**实体：** 
- 类型 `SysCascadeDictType`（`know-boot-common/.../entity/tenant/SysCascadeDictType.java`）：`id AUTO`、`typeName`、`typeCode`（唯一）、`status(1启用/0停用)`、`remark`、审计字段（String 类型 createBy/updateBy，Long 时间）、`@TableLogic delFlag`。
- 数据 `SysCascadeDictData`（路径同 common）：含 `dictTypeId`、`parentId(默认0顶级)`、`name`、`value`、`icon`、`color`、`sort`、`status`、审计、`delFlag`，唯一键 `(dictType_id, value)`，索引 `(dict_type_id,parent_id)`。

**树形节点 VO：** `SysCascadeDictNode`（`know-boot-system/.../vo/SysCascadeDictNode.java`）继承 `SysCascadeDictData`，附加 `List<SysCascadeDictNode> children = new ArrayList<>()`。

**控制器：** `SysCascadeDictController`（`/api/system/cascade-dict`）
- 类型：`/type/list`（支持 typeName/typeCode/status）、`/type/{id}`、POST `/type`、PUT `/type`、DELETE `/type/{id}`
- 数据：`GET /data/tree`（typeCode 或 typeId，可选 status）、`GET /data/list`（typeId 必传）、POST/PUT/DELETE `/data`

**Service：** `ISysCascadeDictService` 与实现 `SysCascadeDictServiceImpl`（`know-boot-system/.../service/*`）。

**Schema Migration（system）：** `SystemSchemaMigration.java`
- `@PostConstruct` 检查并创建 `sys_cascade_dict_type`、`sys_cascade_dict_data`。
- 种子：`seedPlanTypeCascade()` 初始化 typeCode=`plan_type`，顶层节点含 life/cognition/skill/project/hobby/study（含 icon/color/sort）。
- `seedIndustryTypeCascade()` 初始化 typeCode=`industry_type`（部分节点，见 migration 148+ 行截断部分）。
- 同时维护级联字典菜单项 `seedCascadeDictMenu()`。

### 9.2 平铺字典

`sys_dict_type`、`sys_dict_data`（common mapper/entity 存在 `SysDictTypeMapper`、`SysDictMapper` 等），在租户忽略列表中（`CustomTenantLineHandler:30-34,40-44` 包含 `sys_dict_type/sys_dict_data`），与级联字典并行。

---

## 10. Schema Migration 与数据初始化

项目采用 **手动 Schema Migration（JdbcTemplate + @PostConstruct）** 模式，不依赖 Flyway（Flyway 依赖在 parent POM 中配置但实际未激活使用，注释说明见注释行）。共三个 Migration 组件：

**10.1 SystemSchemaMigration**（`know-boot-system/config/SystemSchemaMigration.java`）
- 职责：创建 `sys_cascade_dict_type`、`sys_cascade_dict_data`，种子 `plan_type`、`industry_type`，初始化级联字典菜单。
- 工具方法：`tableExists()`、`insertCascadeNode()`。

**10.2 PlanSchemaMigration**（`know-boot-plan/config/PlanSchemaMigration.java`）
- 职责：创建计划模块全套表（`plan_quadrant`、`plan_type`、`plan_info`、`plan_schedule_category`、`plan_schedule_event`、`plan_habit`、`plan_habit_record`、`plan_focus_session`、`plan_home_config`、`plan_home_slogan`、`plan_info_template`、`plan_habit_template`、`plan_schedule_event_template`）。
- 列补全：大量 `ensureColumnExists()`（修复历史版本缺失列，如 `plan_schedule_event.event_type/tags/subtasks/...`、`plan_habit.*`、`plan_info.template_id/industry_id` 等）。
- 时间戳字段校正：`ensureBigintTimestampColumn()`（处理 bigint/int/timestamp 字符串等历史格式）。
- 种子数据：四象限（Q1-Q4）、计划类型（life/cognition/skill/project/hobby/study）、日程分类、首页标语。
- 数据归一化：`normalizeLegacyPlanTypeData()` 将历史模板中的 `fitness→life`、`reading→cognition` 做映射（针对 `plan_info_template/plan_habit_template/plan_schedule_event_template`）。
- 工具方法：`tableExists()`、`ensureColumnExists()`、`ensureBigintTimestampColumn()`。

**10.3 BizSchemaMigration**（`know-boot-biz/config/BizSchemaMigration.java`，路径 `know-boot-biz/src/main/java/com/know/knowboot/config/BizSchemaMigration.java`）
- 职责：客户与行业业务相关表结构迁移（行业、产品、企业、客户、关系表等），含列补全与必要种子/修复逻辑（按实际文件内容）。

**Migration 模式特点：**
- `@Component` + `@Autowired JdbcTemplate` + `@PostConstruct migrateSchema()`
- 先判断 `tableExists()` 再 `CREATE TABLE`，使用 `ALTER TABLE ADD COLUMN` 补列，幂等执行。
- 无 Flyway 版本文件强制要求（存在 `db/migration/V1_*.sql` 类 Flyway 文件但未启用）。

---

## 11. 配置、端口与部署

### 11.1 配置文件

**激活配置：** `application.yml` 指定 `spring.profiles.active: dev`。

**开发环境（dev）：** `application-dev.yml`
- 服务器端口：`server.port: 8082`（`line 22`）、`context-path: /`（`line 24`）
- 静态资源：`spring.mvc.static-path-pattern: /adminapi/static/**`（`line 29`）
- MySQL：URL 指向 `know_boot_v1`，HikariCP 配置完整（`line 34-49`）
- Redis：host 127.0.0.1:16379，db 6（`line 57-62`）
- MyBatis-Plus：`mapper-locations: classpath*:/mapper/**Mapper.xml`，`typeAliasesPackage: com.know.**.mapper`，`global-config.banner: false`（`line 77-82`）
- 日志：logback 配置路径 `logback-spring.xml`，日志目录 `E:\Ai-Master\know-boot\know-boot-system\logs`、文件名前缀 `system`（`line 84-93`）
- Sa-Token：见 7.1
- know.mode：`standalone`（`line 106`）
- Seata：`enabled: false`（`line 146`）
- Feign/CircuitBreaker/LoadBalancer：均 `false`（`line 157-161`）

**其他 profile：** `application-test.yml`、`application-prod.yml`、`application-prod-bak.yml`、`application-dev-bak.yml`、`application-bak.yml` 存在于 resources。

**bootstrap：** `bootstrap.yml`、`bootstrap-microservice.yml`（Nacos 相关配置，结合 SpringCloud profile 使用）。

### 11.2 启动类

**单机（默认）：** `KnowBootSystemApplication.java`
```java
@SpringBootApplication(exclude={RedisRepositoriesAutoConfiguration.class, SecurityAutoConfiguration.class, OAuth2ResourceServerAutoConfiguration.class}, scanBasePackages={"com.know"})
@ComponentScan(basePackages={"com.know"}, excludeFilters = {@ComponentScan.Filter(type=FilterType.REGEX, pattern="com\\.know\\.knowboot\\.feign\\..*")})
@EnableCaching
@EnableScheduling
@EnableCreateCacheAnnotation
@EnableMethodCache(basePackages="com.know.knowboot")
@EnableTransactionManagement
@MapperScan(basePackages={"com.know.*.mapper"})
```

**微服务：** `MicroserviceApplication.java`（`know-boot-system/src/main/java/com/know/knowboot/MicroserviceApplication.java`）启用 `@EnableDiscoveryClient`、`@Import(MicroserviceConfiguration.class)`，排除规则略有差异（详见 `docs/dual-mode-guide.md:108-162`）。

### 11.3 部署脚本

**独立部署：** `standalone/deploy.js`（Node.js + ssh2）
- 目标服务器 `101.37.83.88:22`，密钥认证（`~/.ssh/id_rsa`）
- 后端 JAR：`know-boot-system/target/know-boot-system-0.0.1-SNAPSHOT.jar` → 远程 `/opt/ai-agent/apps/backend/know-boot-system.jar`
- Wrapper 脚本：`start-system.sh`，使用 `-Dspring.profiles.active=prod`，注入 MySQL/Redis 配置（DB `know_boot_v1` root/`123456aA@`，Redis 16379 db1）
- systemd 服务：`/etc/systemd/system/know-boot-system.service`
- 前端：Vue Admin `/opt/ai-agent/apps/know-vue`、Mobile H5 `/opt/ai-agent/apps/know-mobile`
- 健康检查：POST `/api/login/account`、GET `/api/plan/slogan/current`、GET `/api/camera/device/page`、GET Nginx 9191
- JVM：`-Xms64m -Xmx320m`、`-XX:MaxMetaspaceSize=256m -XX:+HeapDumpOnOutOfMemoryError`（`deploy.js:54-58`）

**Nginx 配置参考：** 单机模式 `/api/*` rewrite 到 `/know-boot/*`，转发到 8085（参考 dual-mode-guide），摄像头 `/camera/` 转发 8088。当前部署使用端口 8082（system 模块 dev/prod 配置不同）。

---

## 12. Java 代码风格

**基础规范：**
- Java 1.8，Lombok 广泛使用（`@Data`、`@Slf4j`、`@RequiredArgsConstructor`、`@EqualsAndHashCode` 等）。
- `@Data` 用于 Entity/VO/DTO，减少 getter/setter。
- 字段命名：驼峰命名（Java），数据库下划线。MP 自动映射。
- 异常处理：业务异常抛 `BaseException` 或子类，控制层不直接捕获复杂异常（交由 `GlobalException` 处理）。
- 事务：关键写操作使用 `@Transactional(rollbackFor = Exception.class)`（见 `PlanInfoServiceImpl.add/update/delete/...`、`BizIndustryServiceImpl.create/update/delete/...`）。
- 依赖注入：优先使用构造器注入（部分类用 `@RequiredArgsConstructor`，如 `SysCascadeDictController`），也存在字段注入 `@Autowired`（如 `PlanInfoController`、`AuthController`、`BizIndustryController`）——两种风格在代码库中并存。

**Controller 层：**
- `@RestController` + `@RequestMapping`，返回 `AjaxResult<T>`（主流）。
- 分页参数命名 `pageNum/pageSize`，默认值 1/10。
- 路径参数 `@PathVariable`，查询 `@RequestParam` 或实体，提交 `@RequestBody`。

**Service 层：**
- 接口 `I*Service`，实现 `*ServiceImpl extends ServiceImpl<Mapper, Entity> implements I*Service`。
- 使用 MP 条件构造器（`LambdaQueryWrapper`、`LambdaUpdateWrapper`）进行查询/更新。
- 复杂查询优先使用 MP/Join 能力，必要时可扩展 Mapper XML。

**Entity 层：**
- 实现 `Serializable`（`BaseEntity`、业务实体均有 `serialVersionUID`）。
- `@TableName`、`@TableId`、`@TableLogic`、`@TableField(exist=false)` 用于非数据库字段。
- 时间戳统一使用 `Long`（毫秒）或 `Date`（仅 BaseEntity）。业务新模块倾向 `Long` 毫秒。

**工具类：** `know-boot-base/utils/*`、`know-boot-common/util/*` 提供通用工具（hutool/commons-lang3/fastjson2 等）。

**代码注释：** 类注释、方法注释使用中文，关键字段添加 `@ApiModelProperty`（接口文档）。

**日志：** 使用 `@Slf4j`，关键操作打印 info/debug，异常统一由 GlobalException 记录 error。

---

## 13. 代码骨架示例（按规范）

> 以下示例基于代码库实际风格提取，展示 Controller、ServiceImpl、Mapper、Entity、Schema Migration 方法的典型写法。

### 13.1 Entity（示例：PlanInfo）

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/entity/plan/PlanInfo.java`

```java
@Data
@TableName("plan_info")
@ApiModel("计划信息实体")
public class PlanInfo implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    @ApiModelProperty("主键")
    private Long id;

    @ApiModelProperty("计划名称")
    private String planName;

    // ... 其他字段 ...

    @ApiModelProperty("创建人")
    private Long createBy;
    @ApiModelProperty("创建时间")
    private Long createTime;
    @ApiModelProperty("更新人")
    private Long updateBy;
    @ApiModelProperty("更新时间")
    private Long updateTime;

    @TableLogic(value = "0", delval = "1")
    @ApiModelProperty("删除时间")
    private Long deleteTime = 0L;
}
```

> 注：BaseEntity 使用 String id + Date 时间（旧风格），业务模块多用 Long id + Long 毫秒时间（新风格），按模块现有风格保持一致。

### 13.2 Mapper

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/mapper/plan/PlanInfoMapper.java`

```java
@Mapper
public interface PlanInfoMapper extends IBaseMapper<PlanInfo> {
}
```

> 继承 `IBaseMapper<T>`（含 MPJBaseMapper 与 setSearch 辅助方法）。

### 13.3 Service 接口

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/service/plan/IPlanInfoService.java`

```java
public interface IPlanInfoService {
    IPage<PlanInfo> page(PlanInfo query, Long userId, Integer pageNum, Integer pageSize);
    List<PlanInfo> listByQuadrant(Long quadrantId);
    PlanInfo getById(Long id);
    boolean add(PlanInfo plan, Long userId);
    boolean update(PlanInfo plan);
    boolean delete(Long id);
    boolean updateProgress(Long id, Integer progress);
    Long toSchedule(Long planId, Long startTime, Long endTime);
    boolean updateStatus(Long id, Integer status, Long userId);
    List<PlanInfo> listByTemplateId(Long templateId);
}
```

### 13.4 ServiceImpl

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/service/plan/impl/PlanInfoServiceImpl.java`

```java
@Service
public class PlanInfoServiceImpl extends ServiceImpl<PlanInfoMapper, PlanInfo> implements IPlanInfoService {
    @Autowired
    private PlanInfoMapper planInfoMapper;
    @Autowired
    private IPlanScheduleEventService scheduleEventService;

    @Override
    public IPage<PlanInfo> page(PlanInfo query, Long userId, Integer pageNum, Integer pageSize) {
        LambdaQueryWrapper<PlanInfo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(query.getPlanType() != null, PlanInfo::getPlanType, query.getPlanType())
               .like(query.getPlanName() != null, PlanInfo::getPlanName, query.getPlanName())
               .orderByDesc(PlanInfo::getCreateTime);
        return page(new Page<>(pageNum, pageSize), wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean add(PlanInfo plan, Long userId) {
        plan.setCreateBy(userId);
        plan.setCreateTime(System.currentTimeMillis());
        if (plan.getStatus() == null) plan.setStatus(0);
        if (plan.getProgress() == null) plan.setProgress(0);
        return save(plan);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean update(PlanInfo plan) {
        plan.setUpdateTime(System.currentTimeMillis());
        return updateById(plan);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean delete(Long id) {
        return removeById(id); // 逻辑删除由 @TableLogic 控制
    }
}
```

### 13.5 Controller

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/controller/plan/PlanInfoController.java`

```java
@Api(tags = "计划管理")
@RestController
@RequestMapping("/api/plan/info")
public class PlanInfoController {
    @Autowired
    private IPlanInfoService planInfoService;

    @ApiOperation("分页查询")
    @GetMapping("/page")
    public AjaxResult<IPage<PlanInfo>> page(PlanInfo query,
                                            @RequestParam(defaultValue="1") Integer pageNum,
                                            @RequestParam(defaultValue="10") Integer pageSize) {
        Long userId = 1L; // TODO: 从 Token 获取
        return AjaxResult.success(planInfoService.page(query, userId, pageNum, pageSize));
    }

    @ApiOperation("获取详情")
    @GetMapping("/{id}")
    public AjaxResult<PlanInfo> get(@PathVariable Long id) {
        return AjaxResult.success(planInfoService.getById(id));
    }

    @ApiOperation("新增计划")
    @PostMapping
    public AjaxResult<Boolean> add(@RequestBody PlanInfo plan) {
        Long userId = 1L; // TODO
        return AjaxResult.success(planInfoService.add(plan, userId));
    }

    @ApiOperation("修改计划")
    @PutMapping
    public AjaxResult<Boolean> update(@RequestBody PlanInfo plan) {
        return AjaxResult.success(planInfoService.update(plan));
    }

    @ApiOperation("删除计划")
    @DeleteMapping("/{id}")
    public AjaxResult<Boolean> delete(@PathVariable Long id) {
        return AjaxResult.success(planInfoService.delete(id));
    }
}
```

### 13.6 Schema Migration 方法骨架

**路径：** `know-boot-plan/src/main/java/com/know/knowboot/config/PlanSchemaMigration.java`（典型模式）

```java
@Component
public class PlanSchemaMigration {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void migrateSchema() {
        System.out.println("[PlanSchemaMigrate] 检查计划模块表结构...");
        try {
            createPlanInfo();
            ensureColumnExists("plan_info", "template_id", "bigint DEFAULT NULL COMMENT '关联模板ID' AFTER `remark`");
            // ... 其他表/列/种子 ...
            System.out.println("[PlanSchemaMigrate] 完成");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private boolean tableExists(String tableName) {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=(SELECT DATABASE()) AND TABLE_NAME=?",
            Integer.class, tableName);
        return count != null && count > 0;
    }

    private void ensureColumnExists(String tableName, String columnName, String columnDefinition) {
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=(SELECT DATABASE()) AND TABLE_NAME=? AND COLUMN_NAME=?",
            Integer.class, tableName, columnName);
        if (count == null || count == 0) {
            jdbcTemplate.execute("ALTER TABLE `" + tableName + "` ADD COLUMN `" + columnName + "` " + columnDefinition);
        }
    }

    private void createPlanInfo() {
        if (!tableExists("plan_info")) {
            jdbcTemplate.execute(
                "CREATE TABLE `plan_info` (" +
                "  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键'," +
                // ... 字段 ...
                "  PRIMARY KEY (`id`)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划表'"
            );
        }
    }
}
```

---

## 14. 注意事项与不一致点（实际存在）

基于代码库实测，以下不一致点是**实际存在**的约定共存情况，开发时需遵循**所修改模块/文件的现有风格**，不要强行统一：

1. **响应体双模式共存：** 新模块（plan/biz/system 新控制器）使用 `AjaxResult`，`know-boot-base` 存在 `Result`。按现有文件风格选择同类响应。
2. **主键/ID 类型不一致：** `BaseEntity.id` 为 `String`（ASSIGN_ID），业务实体多为 `Long`（ASSIGN_ID），系统字典类部分为 `Long` + `AUTO`（`SysCascadeDictType`）。
3. **时间字段类型不一致：** `BaseEntity` 使用 `Date`，业务模块使用 `Long` 毫秒时间戳。
4. **逻辑删除字段不一致：** 有的用 `deleteTime(Long)`，有的用 `delFlag(Integer)`，部分实体同时存在（按表设计不同）。
5. **依赖注入风格不一致：** `@Autowired`（字段注入）与 `@RequiredArgsConstructor`（构造器注入）并存。
6. **Redis 数据库索引不一致：** `application-dev.yml` 配置 `database: 6`，`standalone/deploy.js` 配置 `REDIS.database: 1`（环境差异，按部署环境配置为准）。
7. **硬编码 TODO：** 控制器中存在 `Long userId = 1L; // TODO: 从Token获取用户ID`（`BizIndustryController.create/update`、`PlanInfoController` 多处），实际应从认证上下文（Sa-Token `StpUtil.getLoginId()`）获取。
8. **校验注解使用较少：** `spring-boot-starter-validation` 已引入，但业务控制器中 `@Valid/@NotBlank` 使用不普遍（仅在少数实体/控制器见到）。

**开发原则：** 本文档只记录已存在的约定。新增代码时优先**贴合所在模块的现有代码风格与命名**，避免跨模块风格大幅漂移。

---

**文档版本：** 基于代码库快照生成  
**输出路径：** `E:\Ai-Project\Ai-Service\know-boot\docs\开发规范.md`
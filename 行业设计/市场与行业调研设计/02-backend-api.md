# 02 - 后端 API 接口设计（市场与行业调研子域）

## 2.0 模块与启动说明

- 所属模块：`know-boot-biz`（business 业务模块），本子域为 industry
- 包结构：`com.know.knowboot.controller.biz.industry`、`com.know.knowboot.service.biz.industry` 等
- 路径前缀：`/api/biz/industry`
- 启动方式：单例 `standalone` / 微服务 `microservice` 均支持（详见 README「双模式启动」）
- 数据库连接：远程库 `101.37.83.88:3306/know_boot_v1`（开发直连），表前缀 `biz_`
- 与 customer 子域同模块：跨子域（客户分布反查）直接 Spring Bean 注入，无 Feign 网络开销

## 2.1 Controller 结构

```
com.know.knowboot.controller.biz.industry/
  ├── IndustryController.java              (行业主表 + 客户分布反查)
  ├── IndustryProductController.java       (行业-产品)
  ├── IndustryEnterpriseController.java    (行业-企业)
  └── IndustryMarketController.java        (行业-市场/商业模式)
```

---

## 2.2 IndustryController 端点

### 路径前缀：`/api/biz/industry`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/page` | 分页查询行业（支持名称/编码/标签筛选） | name, code, keyword, pageNum, pageSize |
| GET | `/list` | 全部行业（下拉/多选用，轻量返回 id+name） | keyword |
| GET | `/{id}` | 行业全景详情（主表 + market + 产品/企业列表摘要） | id |
| POST | `` | 新建行业（可同时带 market/product/enterprise） | IndustryDTO body |
| PUT | `` | 修改行业 | IndustryDTO body |
| DELETE | `/{id}` | 删除行业（逻辑删除，级联产品/企业/市场；不删客户关联） | id |
| GET | `/{id}/customers` | **行业客户分布（反查多对多）** | id, keyword, pageNum, pageSize |
| GET | `/statistics` | 行业统计（行业数/产品数/企业数/关联客户数） | — |

---

## 2.3 IndustryProductController 端点

### 路径前缀：`/api/biz/industry/product`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 按行业查产品列表 | industryId, category, pageNum, pageSize |
| GET | `/{id}` | 产品详情 | id |
| POST | `` | 新建产品 | IndustryProductDTO body |
| PUT | `` | 修改产品 | IndustryProductDTO body |
| DELETE | `/{id}` | 删除产品 | id |

## 2.4 IndustryEnterpriseController 端点

### 路径前缀：`/api/biz/industry/enterprise`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 按行业查企业列表 | industryId, type, pageNum, pageSize |
| GET | `/{id}` | 企业详情 | id |
| POST | `` | 新建企业记录 | IndustryEnterpriseDTO body |
| PUT | `` | 修改企业记录 | IndustryEnterpriseDTO body |
| DELETE | `/{id}` | 删除企业记录 | id |

## 2.5 IndustryMarketController 端点

### 路径前缀：`/api/biz/industry/market`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/{industryId}` | 获取行业市场/商业模式信息 | industryId |
| PUT | `/{industryId}` | 保存行业市场信息（upsert，商业模式九要素） | IndustryMarketDTO body |

---

## 2.6 核心接口详细设计

### 2.6.1 GET `/api/biz/industry/{id}` — 行业全景详情

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": {
    "id": 1,
    "industryName": "互联网/IT",
    "definition": "以信息技术为核心...",
    "technology": "云计算/大数据/AI 工程化",
    "upstreamChain": "芯片/服务器/带宽",
    "midstreamChain": "软件厂商/集成商",
    "downstreamChannel": "直销/渠道商/云市场",
    "downstreamMarketing": "SEM/私域/行业会议",
    "developmentOverview": "...",
    "marketSize": "5000亿",
    "grossProfit": 350000000.00,
    "grossMargin": 60.00,
    "netProfit": 120000000.00,
    "netMargin": 20.00,
    "dynamicInfo": "...",
    "valueInfo": "...",
    "industryResources": "...",
    "strategy": "...",
    "market": {
      "demand": "企业数字化转型需求旺盛",
      "opportunity": "中小客户 SaaS 化切入",
      "valueProposition": "...",
      "customerSegment": "...",
      "channel": "...",
      "customerRelation": "...",
      "revenueSource": "...",
      "keyResource": "...",
      "keyPartner": "...",
      "keyActivity": "...",
      "costStructure": "..."
    },
    "products": [
      { "id": 11, "productName": "ERP 系统", "category": "企业管理软件", "lifeCycle": "成熟期" }
    ],
    "enterprises": [
      { "id": 21, "enterpriseName": "某云服务商", "enterpriseType": "云平台", "isListed": 1 }
    ]
  }
}
```

### 2.6.2 GET `/api/biz/industry/{id}/customers` — 行业客户分布（多对多反查核心）

> 行业选择拥有的客户：跨子域读取 customer 数据（同模块进程内调用）。

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": {
    "records": [
      { "id": 1001, "name": "张三", "customerType": 1, "status": 2,
        "relationType": 1, "isMain": 1, "remark": "主营行业" },
      { "id": 1003, "name": "王五", "customerType": 2, "status": 3,
        "relationType": 2, "isMain": 0 }
    ],
    "total": 8,
    "size": 10,
    "current": 1
  }
}
```

**后端实现（跨子域，同模块）：**

```java
// IndustryServiceImpl.getCustomers(industryId, pageNum, pageSize)
// 1. 校验 industry 存在（del_flag=0）
// 2. 通过 biz_customer_industry 反查：
//    SELECT ci.customer_id, ci.relation_type, ci.is_main, ci.remark
//    FROM biz_customer_industry ci
//    WHERE ci.industry_id = ? AND ci.del_flag = 0
// 3. 注入 customer 子域 Service/Mapper，按 customer_id 批量查 biz_customer 摘要★同模块跨子域
// 4. 组装分页返回
```

### 2.6.3 POST `/api/biz/industry` — 新建行业（全景一次提交）

**请求体：**

```json
{
  "industryName": "智能制造",
  "definition": "以智能装备与工业软件为核心的制造升级行业",
  "technology": "工业物联网/数字孪生/MES",
  "upstreamChain": "传感器/工业芯片",
  "midstreamChain": "装备厂商/系统集成商",
  "downstreamChannel": "汽车/电子/半导体工厂直销",
  "downstreamMarketing": "行业展会/标杆案例营销",
  "market": {
    "demand": "工厂降本增效诉求",
    "opportunity": "中小企业智改数转政策红利"
  },
  "products": [
    { "productName": "MES 制造执行系统", "category": "工业软件" }
  ]
}
```

**后端处理逻辑：**

```
1. INSERT biz_industry 主记录
2. 若 market 非空 → INSERT biz_industry_market（一对一 uk 保护）
3. 若 products 非空 → INSERT biz_industry_product ×N
4. 嵌套事务 @Transactional，任一失败回滚
```

---

## 2.7 Entity（新增，biz 前缀命名）

### BizIndustry.java

```java
@Data
@TableName("biz_industry")
@ApiModel("行业实体")
public class BizIndustry implements Serializable {
    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private String industryName;
    private String definition;
    private String technology;
    private String industryCode;
    private String tags;
    private String upstreamChain;
    private String midstreamChain;
    private String downstreamChannel;
    private String downstreamMarketing;
    private String developmentOverview;
    private String marketSize;
    private String growthPotential;
    private String dynamicInfo;
    private String valueInfo;
    private String industryResources;
    private String strategy;
    private BigDecimal grossProfit;
    private BigDecimal grossMargin;
    private BigDecimal netProfit;
    private BigDecimal netMargin;
    // 标准字段 createBy/createTime/updateBy/updateTime
    @TableLogic(value = "0", delval = "1")
    private Integer delFlag;
    private Long deleteTime;
    private Long deleteBy;

    @TableField(exist = false)
    private IndustryMarketDTO market;           // 非表字段：市场/商业模式
    @TableField(exist = false)
    private List<IndustryProductDTO> products;  // 非表字段：产品摘要
    @TableField(exist = false)
    private List<IndustryEnterpriseDTO> enterprises;  // 非表字段：企业摘要
}
```

### BizIndustryProduct.java / BizIndustryEnterprise.java / BizIndustryMarket.java（同构，略）

---

## 2.8 Service & Mapper 层

```java
public interface IBizIndustryService {
    IPage<BizIndustry> page(IndustryQuery query, Integer pageNum, Integer pageSize);
    BizIndustry getDetail(Long id);
    boolean add(IndustryDTO dto, Long userId);
    boolean update(IndustryDTO dto);
    boolean delete(Long id);
    IPage<CustomerIndustryDTO> getCustomers(Long industryId, String keyword, Integer pageNum, Integer pageSize);
    Map<String, Object> statistics();
}

@Mapper
public interface BizIndustryMapper extends IBaseMapper<BizIndustry> {
}
```

> 产品/企业/市场三个子资源 Service 对齐同样结构（`ServiceImpl<XxxMapper, Xxx>` + 普通接口 + `@Transactional`）。
>
> **Mapper 扫描兼容性**：单体聚合 `KnowBootSystemApplication` 用 `@MapperScan("com.know.*.mapper")`；biz 独立启动类 `KnowBootBizApplication` 用 `@MapperScan("com.know.knowboot.mapper.biz..*")`。两个入口都能扫描到 `mapper.biz.customer` 与 `mapper.biz.industry`。
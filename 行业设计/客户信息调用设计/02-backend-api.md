# 02 - 后端 API 接口设计（客户信息调用子域）

## 2.0 模块与启动说明

- 所属模块：`know-boot-biz`（business 业务模块），本子域为 customer
- 包结构：`com.know.knowboot.controller.biz.customer`、`com.know.knowboot.service.biz.customer` 等
- 路径前缀：`/api/biz/customer`
- 启动方式：单例 `standalone` / 微服务 `microservice` 均支持（详见 README「双模式启动」）
- 数据库连接：远程库 `101.37.83.88:3306/know_boot_v1`（开发直连），表前缀 `biz_`

## 2.1 Controller 结构

```
com.know.knowboot.controller.biz.customer/
  ├── CustomerController.java          (客户主表 CRUD + 画像 + 行业关联)
  ├── CustomerCompanyController.java   (企业信息)
  └── CustomerFollowupController.java  (跟进记录)
```

---

## 2.2 CustomerController 端点

### 路径前缀：`/api/biz/customer`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/page` | 分页查询客户（支持姓名/手机尾号/行业/状态/客户类型/区域筛选） | name, phone, status, customerType, industryId, regionCode, pageNum, pageSize |
| GET | `/{id}` | 获取客户详情（含画像 profile + 关联行业 industries + 所属企业） | id |
| POST | `` | 新建客户（可选同时写 profile / industries / company） | CustomerDTO body |
| PUT | `` | 修改客户 | CustomerDTO body |
| DELETE | `/{id}` | 删除客户（逻辑删除，级联画像；企业/跟进保留但标记客户已删） | id |
| PUT | `/{id}/status` | 更新客户状态（潜在→意向→成交/流失） | status |
| POST | `/{id}/industries` | **设置客户关联行业（多选，全量覆盖）** | industryIds[], relations[] |
| GET | `/{id}/industries` | 获取客户关联行业（含行业名称/关系类型） | id |
| GET | `/statistics` | 统计（状态分布 / 行业分布 / 区域分布） | — |

---

## 2.3 CustomerCompanyController 端点

### 路径前缀：`/api/biz/customer/company`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/page` | 分页查询企业 | name, industry, pageNum, pageSize |
| GET | `/{id}` | 企业详情 | id |
| POST | `` | 新建企业（客户建档时可同时提交） | CustomerCompanyDTO body |
| PUT | `` | 修改企业 | CustomerCompanyDTO body |
| DELETE | `/{id}` | 删除企业（逻辑删除） | id |

---

## 2.4 CustomerFollowupController 端点

### 路径前缀：`/api/biz/customer/followup`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 按客户查询跟进记录（时间倒序） | customerId |
| GET | `/today` | 今日待跟进列表（next_time 为今天） | pageNum, pageSize |
| POST | `` | 新增跟进记录 | FollowupDTO body |
| PUT | `` | 修改跟进记录 | FollowupDTO body |
| DELETE | `/{id}` | 删除跟进记录 | id |

---

## 2.5 核心接口详细设计

### 2.5.1 POST `/api/biz/customer` — 新建客户（含画像与行业）

**请求体：**

```json
{
  "name": "赵六",
  "gender": 1,
  "age": 33,
  "phone": "13800138000",
  "email": "zhaoliu@example.com",
  "address": "广东省广州市天河区",
  "education": "本科",
  "occupation": "互联网/IT",
  "position": "技术总监",
  "customerType": 2,
  "status": 1,
  "source": "行业展会",
  "demandLevel": 4,
  "valueScore": 4,
  "company": {
    "name": "ABC 信息科技有限公司",
    "industry": "互联网/IT",
    "scale": "100-500人",
    "business": "企业级 SaaS"
  },
  "industryIds": [1, 5],
  "profile": {
    "dynamicInfo": "决策快速，关注数据指标",
    "valueLevel": 4,
    "valueExpect": "系统落地后 3 个月见效"
  }
}
```

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": { "id": 1001 }
}
```

**后端处理逻辑（CustomerServiceImpl.add）：**

```
1. INSERT biz_customer（AES 加密 phone/email，create_time=now）
2. 若 customerType=2 且有 company → INSERT biz_customer_company → 回填 company_id
3. 若 profile 非空 → INSERT biz_customer_profile（一对一）
4. 若有 industryIds → 逐条 INSERT biz_customer_industry（校验 is_main 唯一）
5. 返回新客户 id（事务 @Transactional）
```

### 2.5.2 POST `/api/biz/customer/{id}/industries` — 设置客户关联行业（多对多核心）

**请求体：**

```json
{
  "industryIds": [1, 5, 9],
  "relations": [
    { "industryId": 1, "relationType": 1, "isMain": 1, "remark": "主营：企业软件" },
    { "industryId": 5, "relationType": 2, "isMain": 0, "remark": "关联：AI 方向" }
  ]
}
```

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": true
}
```

**后端处理逻辑：**

```
1. 校验 industryIds 全部存在于 biz_industry（del_flag=0）★同模块跨子域校验
2. 软删该客户旧关联：UPDATE biz_customer_industry SET del_flag=1 WHERE customer_id=?
3. 批量 INSERT 新关联（is_main 唯一：同一客户只允许一条 is_main=1）
4. 返回操作结果
```

### 2.5.3 GET `/api/biz/customer/page` — 按行业过滤分页

**请求参数：**

```
GET /api/biz/customer/page?industryId=5&name=赵&status=1&pageNum=1&pageSize=10
```

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": {
    "records": [
      {
        "id": 1001,
        "name": "赵六",
        "phone": "138****8000",
        "status": 1,
        "customerType": 2,
        "industries": [ { "industryId": 5, "industryName": "人工智能" } ]
      }
    ],
    "total": 3,
    "size": 10,
    "current": 1
  }
}
```

**SQL 实现（IBaseMapper MPJ 多表关联）：**

```java
// 按行业过滤：biz_customer
//   JOIN biz_customer_industry ci ON ci.customer_id = t.id AND ci.industry_id = ? AND ci.del_flag = 0
// 分页查询，phone 脱敏（LEFT(phone,3) + **** + RIGHT(phone,4)）
```

### 2.5.4 GET `/api/biz/customer/statistics` — 客户统计（联动行业反查）

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": {
    "byStatus":  { "potential": 12, "intent": 5, "dealt": 3, "lost": 2 },
    "byIndustry": [ { "industryId": 1, "industryName": "互联网", "count": 8 } ],
    "byRegion":   [ { "regionCode": "440100", "count": 6 } ]
  }
}
```

---

## 2.6 Entity（新增，biz 前缀命名）

### BizCustomer.java（entity 宽表 + 关联字段）

```java
@Data
@TableName("biz_customer")
public class BizCustomer implements Serializable {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private String name;
    private Integer gender;
    private Integer age;
    private String phone;      // AES 加密存储
    private Integer customerType;   // 1个人 2企业
    private Long companyId;
    private Integer status;          // 1潜在 2意向 3成交 4流失
    // ... 画像相关扩展
    private String maritalStatus;
    private String familySituation;
    private String valuesText;
    private String lifestyle;

    @TableLogic(value = "0", delval = "1")
    private Integer deleted;

    // ---- 非表字段（查询展平用）----
    @TableField(exist = false)
    private List<CustomerIndustryDTO> industries;
    @TableField(exist = false)
    private BizCustomerProfile profile;
    @TableField(exist = false)
    private BizCustomerCompany company;
}
```

### BizCustomerProfile.java

```java
@Data
@TableName("biz_customer_profile")
public class BizCustomerProfile implements Serializable {
    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private Long customerId;
    private String dynamicInfo;   // 动态信息
    private Integer valueLevel;   // 马斯洛需求层次
    private String valueExpect;   // 期望
    private String valueInterest; // 利益点
    private String strategy;      // 应对策略
    private String talkScript;    // 话术设计
    private String analysis;      // 分析
    // 标准字段 createBy/createTime/updateBy/updateTime
    @TableLogic(value = "0", delval = "1")
    private Integer delFlag;
    private Long deleteTime;
}
```

### BizCustomerIndustry.java（多对多中间表实体）

```java
@Data
@TableName("biz_customer_industry")
public class BizCustomerIndustry implements Serializable {
    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private Long customerId;
    private Long industryId;
    private Integer relationType; // 1主营 2关联 3潜在
    private Integer isMain;       // 0否 1是
    private String remark;
    // 标准字段 + @TableLogic delFlag
}
```

---

## 2.7 Service 层

### IBizCustomerService

```java
public interface IBizCustomerService {
    IPage<BizCustomer> page(CustomerQuery query, Integer pageNum, Integer pageSize);
    BizCustomer getDetail(Long id);                 // 组合 profile/company/industries
    boolean add(CustomerDTO dto, Long userId);
    boolean update(CustomerDTO dto);
    boolean delete(Long id);
    boolean updateStatus(Long id, Integer status);
    boolean setIndustries(Long customerId, List<CustomerIndustryDTO> list);
    List<CustomerIndustryDTO> getIndustries(Long customerId);
    Map<String, Object> statistics(StatsQuery query);
}
```

### CustomerServiceImpl 关键实现（对齐现有规范）

```java
@Service
public class CustomerServiceImpl extends ServiceImpl<BizCustomerMapper, BizCustomer>
        implements IBizCustomerService {

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean add(CustomerDTO dto, Long userId) {
        BizCustomer customer = BeanUtil.copyProperties(dto, BizCustomer.class);
        customer.setPhone(AesUtil.encrypt(dto.getPhone()));  // AES 加密
        customer.setCreateBy(userId);
        customer.setCreateTime(System.currentTimeMillis());
        save(customer);
        // 企业 / 画像 / 行业关联（见 2.5.1 逻辑）
        return true;
    }

    @Override
    public IPage<BizCustomer> page(CustomerQuery query, Integer pageNum, Integer pageSize) {
        Page<BizCustomer> page = new Page<>(pageNum, pageSize);
        LambdaQueryWrapper<BizCustomer> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(StringUtils.hasText(query.getName()), BizCustomer::getName, query.getName())
               .eq(query.getStatus() != null, BizCustomer::getStatus, query.getStatus());
        // industryId 过滤走 JOIN（MPJQueryWrapper）
        return page(page, wrapper);
    }
}
```

---

## 2.8 Mapper 层（放 `com.know.knowboot.mapper.biz.customer`，双模式均被扫描）

```java
@Mapper
public interface BizCustomerMapper extends IBaseMapper<BizCustomer> {
}
```

> 行业过滤场景使用 `MPJQueryWrapper`（IBaseMapper 继承 MPJBaseMapper 自带 join 能力）：
> `selectJoinList(BizCustomer.class, wrapper.join(BizCustomerIndustry.class, ...))`
>
> **Mapper 扫描兼容性**：单体聚合 `KnowBootSystemApplication` 用 `@MapperScan("com.know.*.mapper")`；biz 独立启动类 `KnowBootBizApplication` 用 `@MapperScan("com.know.knowboot.mapper.biz..*")`。两个入口都能扫描到 `mapper.biz.customer` 与 `mapper.biz.industry`。

## 2.9 加密与脱敏规范

| 字段 | 存储 | 展示 |
|------|------|------|
| phone | AES 密文 | 脱敏 `138****8000` |
| email | AES 密文 | 登录名部分脱敏 |

## 2.10 跨模块（子域）调用约定

- 行业主数据（`biz_industry`）与本子域同属 `know-boot-biz` 模块，**直接 Service 注入**（`IBizIndustryService`），不走 Feign
- 微服务模式下若行业子域后续独立拆分，可改为 Feign 客户端 `BizIndustryApi`，接口签名与 Service 对齐，切换成本低
# 02 - 后端 API 接口设计

## 2.1 Controller 结构

```
com.know.knowboot.controller.plan/
  ├── PlanInfoController.java          (已有，需启用)
  ├── PlanInfoTemplateController.java  (新增)
  ├── PlanHabitController.java         (已有)
  ├── PlanScheduleEventController.java (已有)
  ├── PlanCalendarController.java      (已有)
  └── PlanFocusSessionController.java  (已有)
```

---

## 2.2 PlanInfoTemplateController 端点

### 路径前缀：`/api/plan/template`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 分页查询模板列表 | planType, visibility, keyword, pageNum, pageSize |
| GET | `/hot` | 热门模板（按 use_count 排序） | limit(默认10) |
| GET | `/{id}` | 获取模板详情（含默认习惯/日程 JSON 解析） | id |
| GET | `/{id}/children` | 获取子模板列表 | id |
| GET | `/{id}/tree` | 递归获取完整模板树 | id |
| POST | `` | 新增自定义模板 | PlanInfoTemplate body（含 parentId） |
| PUT | `` | 修改模板 | PlanInfoTemplate body |
| DELETE | `/{id}` | 删除模板（仅自定义模板，级联处理子模板） | id |
| POST | `/{id}/use` | **从模板创建计划**（核心接口） | id, startDate, customizations(可选) |
| POST | `/from-plan/{planId}` | **从现有计划生成模板** | planId, templateName, description |

---

## 2.3 PlanInfoController 端点（需启用）

### 路径前缀：`/api/plan/info`

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/list` | 分页查询计划列表 |
| GET | `/{id}` | 获取计划详情 |
| POST | `` | 新建计划 |
| PUT | `` | 修改计划 |
| DELETE | `/{id}` | 删除计划 |
| PUT | `/{id}/status` | 更新计划状态(0待开始→1进行中→2完成/3取消) |
| PUT | `/{id}/progress` | 更新进度百分比 |
| GET | `/by-template/{templateId}` | 查询某模板下所有计划 |

---

## 2.4 核心接口详细设计

### POST `/api/plan/template/{id}/use` — 从模板创建计划

**请求体：**

```json
{
  "startDate": 1755590400000,
  "planName": "我的健身计划",
  "customizations": {
    "skipHabits": [1],
    "skipEvents": [0],
    "modifyHabits": [
      {
        "index": 0,
        "changes": {
          "reminderTime": "06:30",
          "targetDays": 60
        }
      }
    ],
    "modifyEvents": [
      {
        "index": 1,
        "changes": {
          "title": "月度体测",
          "remindMinutes": 120
        }
      }
    ]
  }
}
```

**响应：**

```json
{
  "code": 1,
  "msg": "success",
  "data": {
    "plan": {
      "id": 1001,
      "planName": "我的健身计划",
      "planType": "fitness",
      "status": 0,
      "planStartTime": 1755590400000,
      "planEndTime": 1758268800000,
      "templateId": 1
    },
    "habitsCreated": 2,
    "eventsCreated": 3
  }
}
```

**后端处理逻辑（PlanInfoTemplateServiceImpl）：**

```
1. 查询模板 + 解析 JSON 字段
2. 创建根 plan_info 记录
   - 填充模板默认值
   - 计算 planEndTime = startDate + default_duration_days
   - status = 0 (待开始)
3. 遍历根级 default_habits JSON
   - 跳过 skipHabits 中的 index
   - 应用 modifyHabits 中的 changes
   - 创建 plan_habit 记录（planId = 根计划 ID）
4. 遍历根级 default_events JSON
   - 跳过 skipEvents 中的 index
   - 应用 modifyEvents 中的 changes
   - 创建 plan_schedule_event 记录（planId = 根计划 ID）
5. 递归遍历 default_sub_plans JSON ★
   - 对每个子计划节点：
     a. 创建 plan_info 记录（parentId = 父计划 ID）
     b. 创建该子计划的 habits → plan_habit（planId = 子计划 ID）
     c. 创建该子计划的 events → plan_schedule_event（planId = 子计划 ID）
     d. 递归处理 sub_plans（如有）
   - 时间线自动串联：
     * 同级子计划按顺序排列
     * 子计划 startDate = 父计划 startDate + 前序兄弟累计 duration_days
     * 子计划 endDate = startDate + duration_days
6. 更新模板 use_count += 1
7. 返回创建结果（含 plans_created, habits_created, events_created）
```

---

### POST `/api/plan/template/from-plan/{planId}` — 从计划生成模板

**请求体：**

```json
{
  "templateName": "我的健身模板",
  "description": "基于 30 天健身计划的成功经验",
  "visibility": 1
}
```

**后端处理逻辑：**

```
1. 查询 plan_info (planId) — 根计划
2. 递归查询子计划树：
   - 查询所有 parent_id = planId 的子 plan_info
   - 对每个子计划递归查询其子计划
3. 对每个计划节点：
   a. 查询关联的 plan_habit 列表 → 提取为 habits JSON
   b. 查询关联的 plan_schedule_event 列表 → 提取为 events JSON
   c. 递归构建 sub_plans JSON
4. 构建完整的 default_sub_plans JSON 树
5. 构建根级 default_habits / default_events（根计划自身的习惯和日程）
6. 创建 plan_info_template 记录
7. 返回新模板 ID
```

---

## 2.5 Entity 变更

### 新增：PlanInfoTemplate.java

```java
@Data
@TableName("plan_info_template")
public class PlanInfoTemplate implements Serializable {
    private Long id;
    private Long parentId;           // 父模板ID（WBS层级）
    private String templateName;
    private String description;
    private String icon;
    private String color;
    private String planType;
    private Long categoryId;
    private Long quadrantId;
    private String tags;
    private Integer defaultPriority;
    private Integer defaultDurationDays;
    private String defaultRemindTime;
    private String defaultHabits;      // JSON string
    private String defaultEvents;      // JSON string
    private String defaultSubPlans;    // JSON string (递归子计划树)
    private Integer useCount;
    private BigDecimal rating;
    private Integer visibility;        // 0:私有 1:公开 2:系统预置
    private Integer sort;
    private Long createBy;
    private Long createTime;
    private Long updateBy;
    private Long updateTime;
    @TableLogic(value = "0", delval = "1")
    private Integer delFlag;
    private Long deleteTime;
}
```

### 变更：PlanInfo.java 新增字段

```java
@ApiModelProperty("创建自模板ID")
private Long templateId;
```

### 变更：PlanHabit.java 新增字段

```java
@ApiModelProperty("创建自模板ID")
private Long templateId;
```

### 变更：PlanScheduleEvent.java 新增字段

```java
@ApiModelProperty("创建自模板ID")
private Long templateId;
```

---

## 2.6 Service 层

```
com.know.knowboot.service.plan/
  ├── IPlanInfoTemplateService.java       (新增)
  ├── IPlanInfoService.java               (新增/启用)
  └── impl/
      ├── PlanInfoTemplateServiceImpl.java (新增)
      └── PlanInfoServiceImpl.java         (新增/启用)
```

### PlanInfoTemplateServiceImpl 关键方法

```java
public interface IPlanInfoTemplateService {
    IPage<PlanInfoTemplate> page(String planType, Integer visibility, String keyword, int pageNum, int pageSize);
    List<PlanInfoTemplate> hotList(int limit);
    PlanInfoTemplate getDetail(Long id);
    List<PlanInfoTemplate> getChildren(Long parentId);  // 查询子模板
    List<PlanInfoTemplate> getTree(Long rootId);         // 递归获取模板树
    Long create(PlanInfoTemplate template, Long userId);
    void update(PlanInfoTemplate template, Long userId);
    void delete(Long id, Long userId);

    /** 从模板创建计划（含递归子计划） — 核心方法 */
    UseTemplateResult useTemplate(Long templateId, Long userId, UseTemplateRequest request);

    /** 从现有计划生成模板（递归提取子计划树） */
    Long generateFromPlan(Long planId, String templateName, String description, Integer visibility, Long userId);

    /** 递归创建子计划树 — 内部方法 */
    private int createSubPlans(List<Map> subPlanDefs, Long parentId, Long userId, long parentStartMs, Long templateId);

    /** 递归提取计划树为 JSON — 内部方法 */
    private List<Map> extractPlanTree(Long planId);
}
```

---

## 2.7 Mapper 层

```
com.know.knowboot.mapper.plan/
  ├── PlanInfoTemplateMapper.java  (新增)
  └── PlanInfoMapper.java          (新增/启用)
```

使用 MyBatis-Plus，无需手写 SQL，标准 CRUD 通过 `ServiceImpl` 继承实现。
`useTemplate` 方法涉及多表事务，需在 Service 层使用 `@Transactional`。

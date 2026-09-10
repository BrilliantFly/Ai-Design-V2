# 02 - 后端 API 接口设计

## 2.1 Controller 结构

```
com.know.knowboot.controller.plan/
  ├── PlanInfoController.java              (已有，需启用)
  ├── PlanInfoTemplateController.java      (新增 — 计划模板)
  ├── PlanHabitTemplateController.java     (新增 — 习惯模板)
  ├── PlanScheduleEventTemplateController.java (新增 — 日程模板)
  ├── PlanHabitController.java             (已有)
  ├── PlanScheduleEventController.java     (已有)
  ├── PlanCalendarController.java          (已有)
  └── PlanFocusSessionController.java      (已有)
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
| POST | `/{id}/use` | **从模板创建计划**（核心接口） | id, startDate, execStatus, customizations(可选) |
| POST | `/use-in-plan` | **计划内使用模板**（挂载习惯/日程到现有计划）★新增 | planId, templateId, execStatus, selectedHabitIds, selectedEventIds |
| POST | `/from-plan/{planId}` | **从现有计划生成模板** | planId, templateName, description |

---

## 2.3 PlanHabitTemplateController 端点

### 路径前缀：`/api/plan/habit-template`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 分页查询习惯模板 | planType, visibility, keyword, pageNum, pageSize |
| GET | `/hot` | 热门习惯模板 | limit(默认10) |
| GET | `/{id}` | 获取习惯模板详情 | id |
| POST | `` | 新增习惯模板 | PlanHabitTemplate body |
| PUT | `` | 修改习惯模板 | PlanHabitTemplate body |
| DELETE | `/{id}` | 删除习惯模板 | id |

---

## 2.4 PlanScheduleEventTemplateController 端点

### 路径前缀：`/api/plan/event-template`

| 方法 | 端点 | 说明 | 参数 |
|------|------|------|------|
| GET | `/list` | 分页查询日程模板 | planType, visibility, keyword, pageNum, pageSize |
| GET | `/hot` | 热门日程模板 | limit(默认10) |
| GET | `/{id}` | 获取日程模板详情 | id |
| POST | `` | 新增日程模板 | PlanScheduleEventTemplate body |
| PUT | `` | 修改日程模板 | PlanScheduleEventTemplate body |
| DELETE | `/{id}` | 删除日程模板 | id |

## 2.3 PlanInfoController 端点（需启用）

### 路径前缀：`/api/plan/info`

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/list` | 分页查询计划列表（支持 execStatus 过滤） |
| GET | `/{id}` | 获取计划详情 |
| POST | `` | 新建计划 |
| PUT | `` | 修改计划 |
| DELETE | `/{id}` | 删除计划 |
| PUT | `/{id}/status` | 更新计划状态(0待开始→1进行中→2完成/3取消) |
| PUT | `/{id}/progress` | 更新进度百分比 |
| GET | `/by-template/{templateId}` | 查询某模板下所有计划 |

## 2.5 执行状态切换端点

### PlanHabitController 新增

| 方法 | 端点 | 说明 |
|------|------|------|
| PUT | `/api/plan/habit/{id}/exec-status` | 切换习惯执行状态，body: `{ "execStatus": 0 或 1 }` |

### PlanScheduleEventController 新增

| 方法 | 端点 | 说明 |
|------|------|------|
| PUT | `/api/plan/event/{id}/exec-status` | 切换日程执行状态，body: `{ "execStatus": 0 或 1 }` |

### 切换逻辑说明

```java
// 管理端（know-vue）审批流程：
//   草稿(exec_status=0) ──切换──► 执行中(exec_status=1) ──切换──► 草稿(exec_status=0)
//   切换接口仅校验记录归属，不做其他业务干预（打卡记录/完成状态不受影响）

// 调用方：
//   - know-vue 管理端：列表页可切换按钮
//   - know-uniapp：无此入口（移动端只创建执行中事项，不管理草稿）
```

### 列表查询 execStatus 过滤规则

| 客户端 | 过滤行为 |
|--------|----------|
| know-uniapp | 所有列表/日历/统计接口自动带 `execStatus=1`，只看到执行中事项 |
| know-vue | 不带过滤（默认），可手动传 `execStatus` 参数筛选草稿/执行中 |
| 后端口子 | 参数缺省时默认不过滤（管理端视角）；App 端由客户端显式传参 |

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
    private String defaultHabits;      // JSON string (内联定义)
    private String defaultHabitIds;    // JSON array (引用习惯模板ID)
    private String defaultEvents;      // JSON string (内联定义)
    private String defaultEventIds;    // JSON array (引用日程模板ID)
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

### 新增：PlanHabitTemplate.java

```java
@Data
@TableName("plan_habit_template")
public class PlanHabitTemplate implements Serializable {
    private Long id;
    private String templateName;
    private String description;
    private String name;              // 习惯名称
    private String icon;
    private String color;
    private Integer frequencyType;    // 1:每天 2:每周 3:每月 4:自定义
    private String frequencyRule;
    private String reminderTime;
    private String restDays;
    private Integer targetDays;
    private Integer targetValue;
    private String targetUnit;
    private String trackingType;      // boolean/numeric
    private String planType;          // 适用计划类型(NULL=通用)
    private String tags;
    private Integer useCount;
    private Integer visibility;       // 0:私有 1:公开 2:系统预置
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

### 新增：PlanScheduleEventTemplate.java

```java
@Data
@TableName("plan_schedule_event_template")
public class PlanScheduleEventTemplate implements Serializable {
    private Long id;
    private String templateName;
    private String description;
    private String title;
    private Integer eventType;
    private Integer quadrant;
    private Integer priority;
    private Integer isRepeat;
    private Integer repeatType;
    private String repeatRule;
    private Integer isAllDay;
    private Long startTime;
    private Long endTime;
    private Integer remindMinutes;
    private String location;
    private String description;       // 日程详情
    private String planType;          // 适用计划类型(NULL=通用)
    private String tags;
    private Integer useCount;
    private Integer visibility;       // 0:私有 1:公开 2:系统预置
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
@ApiModelProperty("创建自计划模板ID")
private Long templateId;

@ApiModelProperty("创建自习惯模板ID")
private Long habitTemplateId;

@ApiModelProperty("执行状态(0:非执行/草稿 1:执行中)")
private Integer execStatus;
```

### 变更：PlanScheduleEvent.java 新增字段

```java
@ApiModelProperty("创建自计划模板ID")
private Long templateId;

@ApiModelProperty("创建自日程模板ID")
private Long eventTemplateId;

@ApiModelProperty("执行状态(0:非执行/草稿 1:执行中)")
private Integer execStatus;
```

### 执行状态创建默认值规则

```java
// PlanHabitServiceImpl.add() 与 PlanScheduleEventServiceImpl.add()
// 统一逻辑：客户端显式传递 execStatus，服务端兜底默认 1（执行中）

public PlanHabit add(PlanHabit habit) {
    if (habit.getExecStatus() == null) {
        habit.setExecStatus(1); // 兜底：执行中（保持兼容）
    }
    ...
}

// 客户端职责：
//   know-uniapp 创建 → 请求体携带 execStatus=1（执行中，App 立即可见）
//   know-vue 创建     → 请求体携带 execStatus=0（非执行/草稿，App 不显示）
//   useTemplate 创建  → 透传请求体的 execStatus
```

---

## 2.6 Service 层

```
com.know.knowboot.service.plan/
  ├── IPlanInfoTemplateService.java           (新增 — 计划模板)
  ├── IPlanHabitTemplateService.java          (新增 — 习惯模板)
  ├── IPlanScheduleEventTemplateService.java  (新增 — 日程模板)
  ├── IPlanInfoService.java                   (新增/启用)
  └── impl/
      ├── PlanInfoTemplateServiceImpl.java    (新增)
      ├── PlanHabitTemplateServiceImpl.java   (新增)
      ├── PlanScheduleEventTemplateServiceImpl.java (新增)
      └── PlanInfoServiceImpl.java            (新增/启用)
```

### DTO 定义（新增执行状态相关）

```java
@Data
@ApiModel("使用模板创建计划请求")
public class UseTemplateRequest {
    @ApiModelProperty("计划名称")
    private String planName;

    @ApiModelProperty("开始日期时间戳")
    private Long startDate;

    @ApiModelProperty("执行状态(0:非执行/草稿 1:执行中)，缺省=1")
    private Integer execStatus;

    @ApiModelProperty("自定义修改（勾选/改名/改时间线）")
    private Customizations customizations;

    @Data
    public static class Customizations {
        private List<Integer> skipSubPlans;        // 跳过的子计划下标
        private Map<String, Object> habitOverrides; // 习惯字段覆盖
        private Map<String, Object> eventOverrides; // 日程字段覆盖
    }
}

@Data
@ApiModel("计划内使用模板请求")
public class UseInPlanRequest {
    @ApiModelProperty("目标计划ID（必填）")
    private Long planId;

    @ApiModelProperty("计划模板ID（必填）")
    private Long templateId;

    @ApiModelProperty("执行状态(0:非执行/草稿 1:执行中)，缺省=1")
    private Integer execStatus;

    @ApiModelProperty("勾选的习惯模板ID（空=全部）")
    private List<Long> selectedHabitIds;

    @ApiModelProperty("勾选的日程模板ID（空=全部）")
    private List<Long> selectedEventIds;

    @ApiModelProperty("自定义修改")
    private UseTemplateRequest.Customizations customizations;
}

@Data
@ApiModel("计划内使用模板结果")
public class UseInPlanResult {
    private Long planId;
    private int habitCount;
    private int eventCount;
}
```

### PlanInfoTemplateServiceImpl 关键方法

```java
public interface IPlanInfoTemplateService {
    IPage<PlanInfoTemplate> page(String planType, Integer visibility, String keyword, int pageNum, int pageSize);
    List<PlanInfoTemplate> hotList(int limit);
    PlanInfoTemplate getDetail(Long id);
    List<PlanInfoTemplate> getChildren(Long parentId);
    List<PlanInfoTemplate> getTree(Long rootId);
    Long create(PlanInfoTemplate template, Long userId);
    void update(PlanInfoTemplate template, Long userId);
    void delete(Long id, Long userId);

    /** 从模板创建计划（含递归子计划） — 核心方法 */
    UseTemplateResult useTemplate(Long templateId, Long userId, UseTemplateRequest request);

    /** 计划内使用模板：将模板的习惯/日程挂载到现有计划（不创建新计划节点）★ 新增 */
    UseInPlanResult useInPlan(Long planId, Long templateId, Long userId, UseInPlanRequest request);

    /** 切换事项执行状态 */
    void updateExecStatus(Long id, Integer execStatus, Long userId);

    /** 从现有计划生成模板（递归提取子计划树） */
    Long generateFromPlan(Long planId, String templateName, String description, Integer visibility, Long userId);

    /** 递归创建子计划树 — 内部方法 */
    private int createSubPlans(List<Map> subPlanDefs, Long parentId, Long userId, long parentStartMs, Long templateId);

    /** 递归提取计划树为 JSON — 内部方法 */
    private List<Map> extractPlanTree(Long planId);

    /** 解析模板引用（合并 default_habit_ids + default_habits 内联定义） */
    private List<Map> resolveHabitDefs(PlanInfoTemplate tpl);

    /** 解析模板引用（合并 default_event_ids + default_events 内联定义） */
    private List<Map> resolveEventDefs(PlanInfoTemplate tpl);
}
```

### PlanHabitTemplateServiceImpl 关键方法

```java
public interface IPlanHabitTemplateService {
    IPage<PlanHabitTemplate> page(String planType, Integer visibility, String keyword, int pageNum, int pageSize);
    List<PlanHabitTemplate> hotList(int limit);
    PlanHabitTemplate getDetail(Long id);
    Long create(PlanHabitTemplate template, Long userId);
    void update(PlanHabitTemplate template, Long userId);
    void delete(Long id, Long userId);
}
```

### PlanScheduleEventTemplateServiceImpl 关键方法

```java
public interface IPlanScheduleEventTemplateService {
    IPage<PlanScheduleEventTemplate> page(String planType, Integer visibility, String keyword, int pageNum, int pageSize);
    List<PlanScheduleEventTemplate> hotList(int limit);
    PlanScheduleEventTemplate getDetail(Long id);
    Long create(PlanScheduleEventTemplate template, Long userId);
    void update(PlanScheduleEventTemplate template, Long userId);
    void delete(Long id, Long userId);
}
```

---

## 2.7 Mapper 层

```
com.know.knowboot.mapper.plan/
  ├── PlanInfoTemplateMapper.java         (新增)
  ├── PlanHabitTemplateMapper.java        (新增)
  ├── PlanScheduleEventTemplateMapper.java (新增)
  └── PlanInfoMapper.java                 (新增/启用)
```

使用 MyBatis-Plus，无需手写 SQL，标准 CRUD 通过 `ServiceImpl` 继承实现。
`useTemplate` 方法涉及多表事务，需在 Service 层使用 `@Transactional`。

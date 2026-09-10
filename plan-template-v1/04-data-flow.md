# 04 - 数据流程与实例化逻辑

## 4.1 核心数据流

### 流程 1：用户从模板创建计划

```
用户                    前端                     后端                    数据库
 │                       │                       │                       │
 │  选择模板             │                       │                       │
 │──────────────────────>│                       │                       │
 │                       │  GET /template/{id}   │                       │
 │                       │──────────────────────>│  SELECT * FROM        │
 │                       │                       │  plan_info_template   │
 │                       │<──────────────────────│                       │
 │                       │                       │                       │
 │  配置计划参数         │                       │                       │
 │  (名称/日期/习惯选择) │                       │                       │
 │──────────────────────>│                       │                       │
 │                       │                       │                       │
 │  确认创建             │                       │                       │
 │──────────────────────>│                       │                       │
 │                       │  POST /template/{id}/use                       │
 │                       │  { startDate, planName, customizations }      │
 │                       │──────────────────────>│                       │
 │                       │                       │  ① 创建根 plan_info   │
 │                       │                       │──────────────────────>│
 │                       │                       │  ② 创建根级 habit ×N │
 │                       │                       │──────────────────────>│
 │                       │                       │  ③ 创建根级 event ×M │
 │                       │                       │──────────────────────>│
 │                       │                       │  ④ 递归创建子计划树   │
 │                       │                       │     plan_info ×P      │
 │                       │                       │     habit ×H          │
 │                       │                       │     event ×E          │
 │                       │                       │──────────────────────>│
 │                       │                       │  ⑤ 更新 use_count     │
 │                       │                       │──────────────────────>│
 │                       │<──────────────────────│                       │
 │  跳转到计划树详情     │                       │                       │
 │<──────────────────────│                       │                       │
```

### 流程 2：用户将计划存为模板

```
用户                    前端                     后端                    数据库
 │                       │                       │                       │
 │  点击"存为模板"       │                       │                       │
 │──────────────────────>│                       │                       │
 │                       │  填写模板名称/描述     │                       │
 │──────────────────────>│                       │                       │
 │                       │  POST /template/from-plan/{planId}            │
 │                       │──────────────────────>│                       │
 │                       │                       │  ① 递归查 plan_info   │
 │                       │                       │     (根+所有子计划)    │
 │                       │                       │  ② 查每层 habit ×N   │
 │                       │                       │  ③ 查每层 event ×M   │
 │                       │                       │  ④ 构建递归 JSON 树   │
 │                       │                       │  ⑤ INSERT template    │
 │                       │                       │──────────────────────>│
 │                       │<──────────────────────│                       │
 │  跳转到模板列表       │                       │                       │
 │<──────────────────────│                       │                       │
```

---

## 4.2 实例化算法详解

### `useTemplate` 核心逻辑（支持递归子计划）

```java
@Transactional
public UseTemplateResult useTemplate(Long templateId, Long userId, UseTemplateRequest req) {
    // 1. 查询模板
    PlanInfoTemplate tpl = templateMapper.selectById(templateId);
    if (tpl == null) throw new BizException("模板不存在");

    // 2. 创建根 plan_info
    PlanInfo rootPlan = buildPlanFromTemplate(tpl, req.getPlanName(), userId);
    rootPlan.setPlanStartTime(req.getStartDate());
    rootPlan.setTemplateId(templateId);
    if (tpl.getDefaultDurationDays() != null) {
        rootPlan.setPlanEndTime(req.getStartDate() + tpl.getDefaultDurationDays() * 86400000L);
    }
    planInfoMapper.insert(rootPlan);

    int[] counters = {0, 0, 0}; // [plans, habits, events]

    // 3. 创建根级习惯
    counters[1] += createHabitsFromJson(tpl.getDefaultHabits(), rootPlan.getId(), userId, templateId, req.getStartDate(), req.getCustomizations(), "root");

    // 4. 创建根级日程
    counters[2] += createEventsFromJson(tpl.getDefaultEvents(), rootPlan.getId(), userId, templateId, req.getCustomizations(), "root");

    // 5. 递归创建子计划树 ★
    if (tpl.getDefaultSubPlans() != null) {
        List<Map> subPlanDefs = JSON.parseArray(tpl.getDefaultSubPlans(), Map.class);
        counters[0] += createSubPlans(subPlanDefs, rootPlan.getId(), userId, req.getStartDate(), templateId, req.getCustomizations());
    }

    // 6. 更新使用次数
    tpl.setUseCount(tpl.getUseCount() + 1);
    templateMapper.updateById(tpl);

    return new UseTemplateResult(rootPlan, counters[0], counters[1], counters[2]);
}

/**
 * 递归创建子计划树
 * @param parentStartMs 父计划的开始时间戳
 * @return 创建的计划数量
 */
private int createSubPlans(List<Map> subPlanDefs, Long parentId, Long userId,
                           long parentStartMs, Long templateId, UseTemplateRequest.Customizations customs) {
    int count = 0;
    long currentStartMs = parentStartMs; // 同级子计划按时间线顺序排列

    for (int i = 0; i < subPlanDefs.size(); i++) {
        Map def = subPlanDefs.get(i);

        // 检查是否跳过该子计划
        if (customs != null && customs.getSkipSubPlans() != null
            && customs.getSkipSubPlans().contains(i)) continue;

        // 应用自定义修改
        applySubPlanModifications(def, customs, i);

        // 创建子 plan_info
        PlanInfo subPlan = new PlanInfo();
        subPlan.setPlanName((String) def.get("plan_name"));
        subPlan.setPlanType((String) def.getOrDefault("plan_type", "general"));
        subPlan.setQuadrantId(def.get("quadrant_id") != null ? ((Number) def.get("quadrant_id")).longValue() : null);
        subPlan.setPriority((Integer) def.getOrDefault("priority", 5));
        subPlan.setParentId(parentId);
        subPlan.setTemplateId(templateId);
        subPlan.setStatus(0);
        subPlan.setProgress(0);
        subPlan.setLeaderId(userId);
        subPlan.setCreateBy(userId);
        subPlan.setCreateTime(System.currentTimeMillis());

        // 计算时间线
        Integer durationDays = (Integer) def.get("duration_days");
        subPlan.setPlanStartTime(currentStartMs);
        if (durationDays != null) {
            subPlan.setPlanEndTime(currentStartMs + durationDays * 86400000L);
        }
        planInfoMapper.insert(subPlan);
        count++;

        // 创建该子计划的习惯
        if (def.get("habits") != null) {
            List<Map> habits = (List<Map>) def.get("habits");
            count += createHabitsFromJson(JSON.toJSONString(habits), subPlan.getId(), userId, templateId, currentStartMs, customs, "sub_" + i);
        }

        // 创建该子计划的日程
        if (def.get("events") != null) {
            List<Map> events = (List<Map>) def.get("events");
            count += createEventsFromJson(JSON.toJSONString(events), subPlan.getId(), userId, templateId, customs, "sub_" + i);
        }

        // 递归创建下一层子计划
        if (def.get("sub_plans") != null && !((List) def.get("sub_plans")).isEmpty()) {
            List<Map> deeperPlans = (List<Map>) def.get("sub_plans");
            count += createSubPlans(deeperPlans, subPlan.getId(), userId, currentStartMs, templateId, customs);
        }

        // 推进时间线：下一个兄弟子计划从当前子计划结束后开始
        if (durationDays != null) {
            currentStartMs += durationDays * 86400000L;
        }
    }
    return count;
}

/**
 * 从 JSON 创建习惯列表
 */
private int createHabitsFromJson(String habitsJson, Long planId, Long userId,
                                  Long templateId, long startDateMs,
                                  UseTemplateRequest.Customizations customs, String scope) {
    if (habitsJson == null) return 0;
    List<Map> defs = JSON.parseArray(habitsJson, Map.class);
    int count = 0;
    for (int i = 0; i < defs.size(); i++) {
        Map def = defs.get(i);
        // 应用自定义修改
        applyHabitModifications(def, customs, scope, i);

        PlanHabit habit = new PlanHabit();
        habit.setName((String) def.get("name"));
        habit.setIcon((String) def.get("icon"));
        habit.setColor((String) def.get("color"));
        habit.setFrequencyType((Integer) def.get("frequencyType"));
        habit.setFrequencyRule((String) def.get("frequencyRule"));
        habit.setReminderTime((String) def.get("reminderTime"));
        habit.setRestDays((String) def.get("restDays"));
        habit.setTargetDays((Integer) def.get("targetDays"));
        habit.setTargetValue((Integer) def.get("targetValue"));
        habit.setTargetUnit((String) def.get("targetUnit"));
        habit.setTrackingType((String) def.get("trackingType"));
        habit.setStartDate(startDateMs);
        if (habit.getTargetDays() != null) {
            habit.setEndDate(startDateMs + habit.getTargetDays() * 86400000L);
        }
        habit.setCurrentDays(0);
        habit.setTotalDays(0);
        habit.setStatus(0);
        habit.setPlanId(planId);
        habit.setTemplateId(templateId);
        habit.setUserId(userId);
        habit.setCreateBy(userId);
        habit.setCreateTime(System.currentTimeMillis());
        habitMapper.insert(habit);
        count++;
    }
    return count;
}

/**
 * 从 JSON 创建日程列表
 */
private int createEventsFromJson(String eventsJson, Long planId, Long userId,
                                  Long templateId, UseTemplateRequest.Customizations customs, String scope) {
    if (eventsJson == null) return 0;
    List<Map> defs = JSON.parseArray(eventsJson, Map.class);
    int count = 0;
    for (int i = 0; i < defs.size(); i++) {
        Map def = defs.get(i);
        applyEventModifications(def, customs, scope, i);

        PlanScheduleEvent event = new PlanScheduleEvent();
        event.setTitle((String) def.get("title"));
        event.setEventType((Integer) def.getOrDefault("eventType", 1));
        event.setQuadrant((Integer) def.getOrDefault("quadrant", 2));
        event.setPriority((Integer) def.getOrDefault("priority", 1));
        event.setIsRepeat(def.get("repeatType") != null ? 1 : 0);
        event.setRepeatType((Integer) def.get("repeatType"));
        event.setRepeatRule((String) def.get("repeatRule"));
        event.setIsAllDay((Integer) def.getOrDefault("isAllDay", 0));
        event.setRemindMinutes((Integer) def.get("remindMinutes"));
        event.setPlanId(planId);
        event.setTemplateId(templateId);
        event.setUserId(userId);
        event.setCreateBy(userId);
        event.setCreateTime(System.currentTimeMillis());
        event.setStatus(0);
        eventMapper.insert(event);
        count++;
    }
    return count;
}
```

### `fromPlan` 递归提取逻辑

```java
/**
 * 从现有计划递归生成模板
 */
@Transactional
public Long generateFromPlan(Long planId, String templateName, String description,
                              Integer visibility, Long userId) {
    // 1. 查询根计划
    PlanInfo rootPlan = planInfoMapper.selectById(planId);

    // 2. 递归提取计划树
    List<Map> subPlansTree = extractPlanTree(planId);

    // 3. 提取根级习惯和日程
    String habitsJson = extractHabitsJson(planId);
    String eventsJson = extractEventsJson(planId);

    // 4. 创建模板
    PlanInfoTemplate tpl = new PlanInfoTemplate();
    tpl.setTemplateName(templateName);
    tpl.setDescription(description);
    tpl.setPlanType(rootPlan.getPlanType());
    tpl.setCategoryId(rootPlan.getCategoryId());
    tpl.setQuadrantId(rootPlan.getQuadrantId());
    tpl.setDefaultPriority(rootPlan.getPriority());
    tpl.setDefaultHabits(habitsJson);
    tpl.setDefaultEvents(eventsJson);
    tpl.setDefaultSubPlans(JSON.toJSONString(subPlansTree));
    tpl.setVisibility(visibility);
    tpl.setCreateBy(userId);
    tpl.setCreateTime(System.currentTimeMillis());
    templateMapper.insert(tpl);

    return tpl.getId();
}

/**
 * 递归提取子计划树
 */
private List<Map> extractPlanTree(Long parentId) {
    List<PlanInfo> children = planInfoMapper.selectList(
        new LambdaQueryWrapper<PlanInfo>()
            .eq(PlanInfo::getParentId, parentId)
            .eq(PlanInfo::getDelFlag, 0)
            .orderByAsc(PlanInfo::getPlanStartTime)
    );

    List<Map> tree = new ArrayList<>();
    for (PlanInfo child : children) {
        Map node = new HashMap();
        node.put("plan_name", child.getPlanName());
        node.put("plan_type", child.getPlanType());
        node.put("quadrant_id", child.getQuadrantId());
        node.put("priority", child.getPriority());
        // 计算持续天数
        if (child.getPlanStartTime() != null && child.getPlanEndTime() != null) {
            long days = (child.getPlanEndTime() - child.getPlanStartTime()) / 86400000L;
            node.put("duration_days", (int) days);
        }
        node.put("description", child.getRemark());
        node.put("habits", parseJsonArray(extractHabitsJson(child.getId())));
        node.put("events", parseJsonArray(extractEventsJson(child.getId())));
        node.put("sub_plans", extractPlanTree(child.getId())); // 递归
        tree.add(node);
    }
    return tree;
}
```

---

## 4.3 数据一致性保证

| 场景 | 处理方式 |
|------|----------|
| 模板被删除后使用 | `@TableLogic` 软删除，查询时过滤，使用前校验 `del_flag=0` |
| 模板字段 JSON 格式错误 | `try-catch` 解析，失败时返回错误提示，不创建部分数据 |
| 习惯/日程/子计划创建失败 | `@Transactional` 事务回滚，全部成功才提交 |
| 并发使用同一模板 | `use_count` 非关键字段，允许最终一致；计划创建无冲突 |
| 自定义修改超出范围 | 后端校验 index 不超过 JSON 数组长度 |
| 子计划嵌套过深 | 前端限制最大 5 层，后端 `createSubPlans` 递归安全检查（深度计数器） |
| 子计划时间线冲突 | 同级子计划按 `duration_days` 顺序排列，自动计算 startDate/endDate |
| 跳过子计划后时间线断裂 | 跳过的子计划不占时间，后续兄弟子计划向前填充 |

---

## 4.4 定时任务（可选 V2）

```java
// 模板推荐任务：每周更新热门模板排行
@Scheduled(cron = "0 0 2 ? * MON")
public void refreshTemplateRank() {
    // 根据 use_count + rating 计算推荐分
    // 更新 sort 字段
}
```

---

## 4.5 统计查询

### 模板使用统计

```sql
-- 某模板下的计划数（含子计划）
SELECT COUNT(*) FROM plan_info WHERE template_id = ? AND del_flag = 0;

-- 某模板关联的习惯数（所有层级）
SELECT COUNT(*) FROM plan_habit WHERE template_id = ? AND del_flag = 0;

-- 某用户的模板使用历史
SELECT t.*, p.plan_name, p.status, p.progress
FROM plan_info p
JOIN plan_info_template t ON p.template_id = t.id
WHERE p.leader_id = ? AND p.del_flag = 0 AND p.parent_id IS NULL
ORDER BY p.create_time DESC;

-- 查询某计划的完整子计划树（递归 CTE）
WITH RECURSIVE plan_tree AS (
  SELECT id, plan_name, parent_id, status, progress, plan_start_time, plan_end_time, 0 AS depth
  FROM plan_info WHERE id = ? AND del_flag = 0
  UNION ALL
  SELECT p.id, p.plan_name, p.parent_id, p.status, p.progress, p.plan_start_time, p.plan_end_time, pt.depth + 1
  FROM plan_info p
  JOIN plan_tree pt ON p.parent_id = pt.id
  WHERE p.del_flag = 0 AND pt.depth < 10
)
SELECT * FROM plan_tree ORDER BY plan_start_time, depth;
```

---

## 4.6 未来扩展点

| 扩展方向 | V2 方案 |
|----------|---------|
| 模板市场 | `visibility=2` 全局可见，支持搜索/分类/排行 |
| 模板评分 | 用户对使用过的模板评分，聚合 `rating` |
| 模板继承 | 模板可基于另一个模板派生（`parent_template_id`） |
| 团队模板 | `visibility` 增加 `3:团队可见`，配合 `role_id` 控制 |
| 模板导入导出 | JSON 格式导入导出模板定义 |
| AI 推荐 | 根据用户习惯/日程数据，推荐匹配的模板 |
| 子计划进度聚合 | 父计划 progress = Σ(子计划 progress × weight) |
| 子计划甘特图 | 前端甘特图组件，可视化多层级计划时间线 |
| 子计划依赖关系 | `plan_info` 增加 `depends_on` 字段，支持前置任务依赖 |

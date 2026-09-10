# 计划模板系统设计方案 V1

> 创建日期：2026-08-19
> 版本：V1
> 状态：设计稿

## 背景

当前系统中 `plan_info`（父计划）已定义但未实际启用，习惯（`plan_habit`）和日程（`plan_schedule_event`）各自独立运行，没有"计划"维度的串联。为支持**快速创建标准化计划**，引入计划模板系统。

## 设计目标

1. **快速复用**：预置常用计划模板（如"健身计划"、"读书计划"、"项目冲刺"），用户一键创建
2. **自定义模板**：用户可将成功的计划保存为模板
3. **模板继承**：从模板创建计划时，自动填充字段 + 可选创建关联习惯/日程
4. **WBS 多层拆解**：模板和计划均支持递归父子层级（计划 → 子计划 → 孙计划）
5. **习惯/日程模板复用**：单独的习惯模板和日程模板可供多个计划模板引用
6. **模板市场**：未来扩展为社区共享模板（V2）

## 核心实体

| 实体 | 表名 | 说明 |
|------|------|------|
| PlanInfoTemplate | `plan_info_template` | 计划模板定义（含 WBS 层级 parent_id） |
| PlanHabitTemplate | `plan_habit_template` | 习惯模板（可复用，被计划模板引用） |
| PlanScheduleEventTemplate | `plan_schedule_event_template` | 日程模板（可复用，被计划模板引用） |
| PlanInfo | `plan_info` | 实例化的计划（已有，启用 parent_id + template_id） |
| PlanHabit | `plan_habit` | 习惯（已有，增加 template_id + habit_template_id） |
| PlanScheduleEvent | `plan_schedule_event` | 日程（已有，增加 template_id + event_template_id） |

## 模板引用关系

```
plan_info_template ── default_habit_ids ──► plan_habit_template（习惯模板表）
plan_info_template ── default_event_ids ──► plan_schedule_event_template（日程模板表）
plan_info_template ── parent_id ──► plan_info_template（WBS 模板层级）
```

计划模板通过两种方式关联习惯/日程：
1. **模板引用**：`default_habit_ids` / `default_event_ids` 引用模板表 ID（可复用，推荐）
2. **内联定义**：`default_habits` / `default_events` JSON 直接写死（一次性）

## 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表结构设计（3 张新模板表 + 现有表变更） |
| [02-backend-api.md](./02-backend-api.md) | 后端 API 接口设计（3 个模板 Controller） |
| [03-frontend-design.md](./03-frontend-design.md) | 前端页面与组件设计（3 套模板管理页面） |
| [04-data-flow.md](./04-data-flow.md) | 数据流程与实例化逻辑（递归创建 + 模板引用解析） |
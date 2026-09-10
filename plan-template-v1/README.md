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
4. **模板市场**：未来扩展为社区共享模板（V2）

## 核心实体

| 实体 | 表名 | 说明 |
|------|------|------|
| PlanInfoTemplate | `plan_info_template` | 计划模板定义 |
| PlanInfo | `plan_info` | 实例化的计划（已有，启用） |
| PlanHabit | `plan_habit` | 习惯（已有，增加 templateId 关联） |
| PlanScheduleEvent | `plan_schedule_event` | 日程（已有，增加 templateId 关联） |

## 文件索引

| 文件 | 内容 |
|------|------|
| [01-database-schema.md](./01-database-schema.md) | 数据库表结构设计 |
| [02-backend-api.md](./02-backend-api.md) | 后端 API 接口设计 |
| [03-frontend-design.md](./03-frontend-design.md) | 前端页面与组件设计 |
| [04-data-flow.md](./04-data-flow.md) | 数据流程与实例化逻辑 |

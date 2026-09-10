# 01 - 数据库表结构设计

## 1.1 新增表：plan_info_template（计划模板）

```sql
CREATE TABLE plan_info_template (
  -- ===== 基础信息 =====
  id              BIGINT       NOT NULL  COMMENT '主键',
  parent_id       BIGINT       DEFAULT NULL COMMENT '父模板ID(支持WBS拆解，NULL=顶级模板)',
  template_name   VARCHAR(128) NOT NULL  COMMENT '模板名称',
  description     VARCHAR(512) DEFAULT NULL COMMENT '模板描述',
  icon            VARCHAR(32)  DEFAULT NULL COMMENT '图标(emoji)',
  color           VARCHAR(16)  DEFAULT NULL COMMENT '主题颜色(hex)',

  -- ===== 模板分类 =====
  plan_type       VARCHAR(32)  NOT NULL  COMMENT '计划类型(对应plan_type.type_code)',
  category_id     BIGINT       DEFAULT NULL COMMENT '分类ID',
  quadrant_id     BIGINT       DEFAULT NULL COMMENT '默认四象限ID',
  tags            VARCHAR(256) DEFAULT NULL COMMENT '标签(逗号分隔)',

  -- ===== 默认值配置 =====
  default_priority    INT        DEFAULT 5     COMMENT '默认优先级(0-10)',
  default_duration_days INT       DEFAULT NULL  COMMENT '默认计划天数(null=不限)',
  default_remind_time VARCHAR(16) DEFAULT NULL COMMENT '默认提醒时间(HH:mm)',

  -- ===== 模板内容（JSON） =====
  default_habits      JSON       DEFAULT NULL COMMENT '默认习惯列表JSON',
  default_events      JSON       DEFAULT NULL COMMENT '默认日程列表JSON',
  default_sub_plans   JSON       DEFAULT NULL COMMENT '默认子计划树(JSON递归结构)',

  -- ===== 使用统计 =====
  use_count       INT           DEFAULT 0   COMMENT '使用次数',
  rating          DECIMAL(2,1)  DEFAULT NULL COMMENT '评分(1.0-5.0)',

  -- ===== 可见性 =====
  visibility      TINYINT       DEFAULT 1   COMMENT '可见性(0:私有 1:公开 2:系统预置)',
  sort            INT           DEFAULT 0   COMMENT '排序(越大越前)',

  -- ===== 标准字段 =====
  create_by       BIGINT       DEFAULT NULL COMMENT '创建人',
  create_time     BIGINT       DEFAULT NULL COMMENT '创建时间',
  update_by       BIGINT       DEFAULT NULL COMMENT '更新人',
  update_time     BIGINT       DEFAULT NULL COMMENT '更新时间',
  del_flag        TINYINT      DEFAULT 0    COMMENT '删除标记(0:正常 1:删除)',
  delete_time     BIGINT       DEFAULT 0    COMMENT '删除时间',

  PRIMARY KEY (id)
) COMMENT = '计划模板表';
```

### 字段说明

#### 默认习惯列表 JSON 格式

```json
[
  {
    "name": "晨跑",
    "icon": "🏃",
    "color": "#22b573",
    "frequencyType": 1,
    "frequencyRule": "",
    "reminderTime": "07:00",
    "restDays": "0,6",
    "targetDays": 30,
    "targetValue": 5,
    "targetUnit": "公里",
    "trackingType": "numeric"
  },
  {
    "name": "阅读",
    "icon": "📚",
    "color": "#6366f1",
    "frequencyType": 1,
    "reminderTime": "22:00",
    "restDays": "",
    "targetDays": 30,
    "targetValue": 30,
    "targetUnit": "页",
    "trackingType": "numeric"
  }
]
```

#### 默认日程列表 JSON 格式

```json
[
  {
    "title": "制定周计划",
    "eventType": 1,
    "quadrant": 2,
    "priority": 2,
    "repeatType": 2,
    "repeatRule": "{\"weekDays\":[1]}",
    "isAllDay": 0,
    "remindMinutes": 15
  },
  {
    "title": "复盘总结",
    "eventType": 1,
    "quadrant": 2,
    "priority": 1,
    "repeatType": 2,
    "repeatRule": "{\"weekDays\":[5]}",
    "isAllDay": 0,
    "remindMinutes": 30
  }
]
```

#### 默认子计划树 JSON 格式（递归结构）

每个子计划节点可包含自身的 `habits`、`events`、`sub_plans`，形成任意深度的计划树：

```json
[
  {
    "plan_name": "阶段一：基础建设",
    "plan_type": "project",
    "quadrant_id": 2,
    "priority": 3,
    "duration_days": 7,
    "description": "搭建基础架构，完成核心模块开发",
    "habits": [
      {
        "name": "每日代码审查",
        "icon": "🔍",
        "color": "#6366f1",
        "frequencyType": 1,
        "reminderTime": "10:00",
        "restDays": "0,6",
        "targetDays": 7,
        "trackingType": "boolean"
      }
    ],
    "events": [
      {
        "title": "技术方案评审",
        "eventType": 1,
        "quadrant": 1,
        "priority": 3,
        "isAllDay": 0,
        "remindMinutes": 30
      }
    ],
    "sub_plans": [
      {
        "plan_name": "数据库设计",
        "priority": 3,
        "duration_days": 2,
        "habits": [],
        "events": [
          {"title": "ER 图评审", "eventType": 1, "quadrant": 1, "priority": 3}
        ],
        "sub_plans": []
      },
      {
        "plan_name": "API 开发",
        "priority": 3,
        "duration_days": 3,
        "habits": [
          {"name": "接口自测", "icon": "✅", "color": "#22b573", "frequencyType": 1, "targetDays": 3, "trackingType": "boolean"}
        ],
        "events": [],
        "sub_plans": []
      }
    ]
  },
  {
    "plan_name": "阶段二：核心开发",
    "plan_type": "project",
    "quadrant": 1,
    "priority": 3,
    "duration_days": 14,
    "description": "完成核心业务逻辑开发",
    "habits": [
      {"name": "每日站会", "icon": "🗣️", "color": "#6366f1", "frequencyType": 1, "reminderTime": "09:00", "restDays": "0,6", "targetDays": 14, "trackingType": "boolean"}
    ],
    "events": [
      {"title": "中期 Demo", "eventType": 1, "quadrant": 1, "priority": 3, "isAllDay": 0, "remindMinutes": 60}
    ],
    "sub_plans": [
      {
        "plan_name": "前端开发",
        "priority": 3,
        "duration_days": 10,
        "habits": [{"name": "组件复用率检查", "icon": "📦", "color": "#f97316", "frequencyType": 2, "frequencyRule": "{\"weekDays\":[5]}", "targetDays": 10, "trackingType": "boolean"}],
        "events": [],
        "sub_plans": []
      },
      {
        "plan_name": "后端开发",
        "priority": 3,
        "duration_days": 12,
        "habits": [{"name": "单元测试覆盖", "icon": "🧪", "color": "#a855f7", "frequencyType": 1, "targetDays": 12, "trackingType": "numeric", "targetValue": 80, "targetUnit": "%"}],
        "events": [],
        "sub_plans": []
      }
    ]
  },
  {
    "plan_name": "阶段三：测试验收",
    "plan_type": "project",
    "quadrant": 1,
    "priority": 2,
    "duration_days": 7,
    "habits": [],
    "events": [
      {"title": "UAT 测试", "eventType": 1, "quadrant": 1, "priority": 3, "isAllDay": 1},
      {"title": "上线评审", "eventType": 1, "quadrant": 1, "priority": 3, "isAllDay": 0, "remindMinutes": 60}
    ],
    "sub_plans": []
  }
]
```

---

## 1.2 现有表变更

### plan_info 新增字段

```sql
ALTER TABLE plan_info
  ADD COLUMN template_id BIGINT DEFAULT NULL COMMENT '创建自模板ID' AFTER parent_id;
```

### plan_habit 新增字段

```sql
ALTER TABLE plan_habit
  ADD COLUMN template_id BIGINT DEFAULT NULL COMMENT '创建自模板ID' AFTER plan_id;
```

### plan_schedule_event 新增字段

```sql
ALTER TABLE plan_schedule_event
  ADD COLUMN template_id BIGINT DEFAULT NULL COMMENT '创建自模板ID' AFTER plan_id;
```

### plan_info 确认启用字段

```sql
-- plan_info 已有字段，无需变更，确认以下字段即可：
-- plan_type: 计划类型
-- quadrant_id: 四象限
-- parent_id: WBS 拆解（递归父子关系）
-- progress: 进度百分比
-- status: 0待开始 1进行中 2已完成 3已取消
-- template_id: 创建自模板ID（新增）
```

---

## 1.3 索引设计

```sql
CREATE INDEX idx_template_plan_type ON plan_info_template(plan_type);
CREATE INDEX idx_template_parent_id ON plan_info_template(parent_id);
CREATE INDEX idx_template_visibility ON plan_info_template(visibility, del_flag);
CREATE INDEX idx_template_sort ON plan_info_template(sort DESC, create_time DESC);
CREATE INDEX idx_habit_template_id ON plan_habit(template_id);
CREATE INDEX idx_event_template_id ON plan_schedule_event(template_id);
CREATE INDEX idx_plan_parent_id ON plan_info(parent_id);
CREATE INDEX idx_plan_template_id ON plan_info(template_id);
```

---

## 1.4 数据关系图

```
plan_type (计划类型字典)
    │
    │ type_code
    ▼
plan_info_template ─── parent_id ──► plan_info_template (父模板)
    │                                    │
    │  template_id (创建自模板)           │ parent_id (模板层级)
    │  template_id (创建自模板)           │
    ├────────────────────┐               ▼
    ▼                    ▼          plan_info_template (子模板)
plan_habit          plan_schedule_event
    │                    │
    │ planId (可选)      │ planId (可选)
    ▼                    ▼
plan_info ◄────────────────────── plan_info (通过 planId)
    │
    │ parent_id (WBS 递归父子关系)
    ▼
plan_info (子计划) ──► plan_info (孙计划) ──► ...
    │
    │ id
    ▼
plan_habit_record (打卡记录)
```

### 模板层级树示意

```
顶级模板 (parent_id = NULL)
├── 子模板 A (parent_id = 顶级模板.id)
│   ├── 孙模板 A-1 (parent_id = 子模板A.id)
│   └── 孙模板 A-2 (parent_id = 子模板A.id)
├── 子模板 B (parent_id = 顶级模板.id)
└── 子模板 C (parent_id = 顶级模板.id)
```

### 多层级计划树示意（使用模板后实例化）

```
根计划 (parent_id = NULL)
├── 子计划 A (parent_id = 根计划.id)
│   ├── 孙计划 A-1 (parent_id = 子计划A.id)
│   └── 孙计划 A-2 (parent_id = 子计划A.id)
├── 子计划 B (parent_id = 根计划.id)
│   └── 孙计划 B-1 (parent_id = 子计划B.id)
│       └── 曾孙计划 B-1-a (parent_id = 孙计划B-1.id)
└── 子计划 C (parent_id = 根计划.id)
```

每个计划节点可独立挂载：
- **习惯**（`plan_habit.plan_id`）
- **日程**（`plan_schedule_event.plan_id`）
- **子计划**（`plan_info.parent_id`）

---

## 1.5 预置模板数据

### 模板 1：健身计划

```sql
INSERT INTO plan_info_template (
  id, template_name, description, icon, color,
  plan_type, quadrant_id, default_priority, default_duration_days, default_remind_time,
  default_habits, default_events, visibility, sort
) VALUES (
  1, '健身计划', '30 天健身养成计划，包含跑步、力量训练、拉伸三项习惯', '💪', '#22b573',
  'fitness', 2, 7, 30, '07:00',
  '[{"name":"晨跑","icon":"🏃","color":"#22b573","frequencyType":1,"reminderTime":"07:00","restDays":"0","targetDays":30,"targetValue":5,"targetUnit":"公里","trackingType":"numeric"},{"name":"力量训练","icon":"🏋️","color":"#f97316","frequencyType":1,"reminderTime":"18:00","restDays":"0,6","targetDays":30,"targetValue":30,"targetUnit":"分钟","trackingType":"numeric"},{"name":"拉伸放松","icon":"🧘","color":"#a855f7","frequencyType":1,"reminderTime":"21:00","restDays":"","targetDays":30,"targetValue":15,"targetUnit":"分钟","trackingType":"numeric"}]',
  '[{"title":"制定健身计划","eventType":1,"quadrant":2,"priority":2,"isAllDay":0,"remindMinutes":15},{"title":"中期体测","eventType":1,"quadrant":2,"priority":2,"isAllDay":0,"remindMinutes":60},{"title":"最终体测","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":60}]',
  2, 10
);
```

### 模板 2：读书计划

```sql
INSERT INTO plan_info_template (
  id, template_name, description, icon, color,
  plan_type, quadrant_id, default_priority, default_duration_days, default_remind_time,
  default_habits, default_events, visibility, sort
) VALUES (
  2, '读书计划', '30 天阅读养成计划，每天阅读 30 页', '📚', '#6366f1',
  'reading', 2, 6, 30, '22:00',
  '[{"name":"每日阅读","icon":"📖","color":"#6366f1","frequencyType":1,"reminderTime":"22:00","restDays":"","targetDays":30,"targetValue":30,"targetUnit":"页","trackingType":"numeric"},{"name":"阅读笔记","icon":"📝","color":"#f59e0b","frequencyType":2,"frequencyRule":"{\\"weekDays\\":[1,3,5]}","reminderTime":"22:30","restDays":"","targetDays":30,"targetValue":3,"targetUnit":"篇","trackingType":"numeric"}]',
  '[{"title":"选书下单","eventType":1,"quadrant":3,"priority":1,"isAllDay":1},{"title":"每周读书分享","eventType":1,"quadrant":2,"priority":1,"repeatType":2,"repeatRule":"{\\"weekDays\\":[6]}","isAllDay":0,"remindMinutes":30}]',
  2, 9
);
```

### 模板 3：项目冲刺（多层级计划）

```sql
INSERT INTO plan_info_template (
  id, template_name, description, icon, color,
  plan_type, quadrant_id, default_priority, default_duration_days, default_remind_time,
  default_habits, default_events, default_sub_plans, visibility, sort
) VALUES (
  3, '项目冲刺', '2 周冲刺计划，含 3 个阶段子计划，支持 WBS 多层拆解', '🚀', '#e85a5a',
  'project', 1, 9, 14, '09:00',
  '[{"name":"每日站会","icon":"🗣️","color":"#6366f1","frequencyType":1,"reminderTime":"09:00","restDays":"0,6","targetDays":14,"trackingType":"boolean"},{"name":"当日复盘","icon":"📋","color":"#22b573","frequencyType":1,"reminderTime":"18:00","restDays":"0,6","targetDays":14,"trackingType":"boolean"}]',
  '[{"title":"冲刺启动会","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":30},{"title":"交付评审","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":60}]',
  '[{"plan_name":"阶段一：需求确认","plan_type":"project","priority":3,"duration_days":2,"description":"需求分析与任务拆解","habits":[{"name":"需求文档更新","icon":"📝","color":"#f59e0b","frequencyType":1,"targetDays":2,"trackingType":"boolean"}],"events":[{"title":"需求评审会","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":30}],"sub_plans":[{"plan_name":"功能清单确认","priority":3,"duration_days":1,"habits":[],"events":[],"sub_plans":[]},{"plan_name":"技术方案设计","priority":3,"duration_days":1,"habits":[],"events":[{"title":"方案评审","eventType":1,"quadrant":1,"priority":3}],"sub_plans":[]}]},{"plan_name":"阶段二：核心开发","plan_type":"project","priority":3,"duration_days":8,"description":"核心功能开发与联调","habits":[{"name":"每日站会","icon":"🗣️","color":"#6366f1","frequencyType":1,"reminderTime":"09:00","restDays":"0,6","targetDays":8,"trackingType":"boolean"},{"name":"代码 Review","icon":"🔍","color":"#a855f7","frequencyType":1,"reminderTime":"17:00","restDays":"0,6","targetDays":8,"trackingType":"boolean"}],"events":[{"title":"中期 Demo","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":60}],"sub_plans":[{"plan_name":"前端开发","priority":3,"duration_days":6,"habits":[{"name":"组件文档","icon":"📦","color":"#22b573","frequencyType":2,"frequencyRule":"{\\"weekDays\\":[5]}","targetDays":6,"trackingType":"boolean"}],"events":[],"sub_plans":[]},{"plan_name":"后端开发","priority":3,"duration_days":7,"habits":[{"name":"单元测试","icon":"🧪","color":"#f97316","frequencyType":1,"targetDays":7,"trackingType":"numeric","targetValue":80,"targetUnit":"%"}],"events":[],"sub_plans":[]},{"plan_name":"接口联调","priority":2,"duration_days":3,"habits":[],"events":[{"title":"联调会议","eventType":1,"quadrant":2,"priority":2,"repeatType":2,"repeatRule":"{\\"weekDays\\":[2,4]}"}],"sub_plans":[]}]},{"plan_name":"阶段三：测试上线","plan_type":"project","priority":2,"duration_days":4,"description":"测试修复与部署上线","habits":[],"events":[{"title":"UAT 测试","eventType":1,"quadrant":1,"priority":3,"isAllDay":1},{"title":"上线评审","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":60},{"title":"线上验证","eventType":1,"quadrant":1,"priority":3,"isAllDay":0,"remindMinutes":30}],"sub_plans":[{"plan_name":"Bug 修复","priority":3,"duration_days":2,"habits":[],"events":[],"sub_plans":[]},{"plan_name":"部署发布","priority":3,"duration_days":1,"habits":[],"events":[{"title":"灰度发布","eventType":1,"quadrant":1,"priority":3},{"title":"全量上线","eventType":1,"quadrant":1,"priority":3}],"sub_plans":[]}]}]',
  2, 8
);
```

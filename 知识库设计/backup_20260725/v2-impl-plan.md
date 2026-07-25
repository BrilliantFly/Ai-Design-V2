# 知识管理APP V2 实现方案

基于 `know-uniapp` 已有项目 + 语雀设计方案

---

## 一、现状分析

### 1.1 已有技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | uni-app + Vue 3.2.45 + TypeScript |
| 状态管理 | Pinia |
| UI | 自定义组件 + Tailwind CSS |
| 构建 | Vite 4.1.4 |
| 路由 | uniapp-router-next |
| 分页 | z-paging |
| 后端 | SpringBoot (know-boot) |
| 数据库 | MySQL 8.0 (know_boot_v1) |

### 1.2 已有页面 vs 需要的页面

| 已有页面 | V2改造 | 说明 |
|----------|--------|------|
| `pages/index/index` | 保留+改造 | 首页加入知识库入口 |
| `pages/news/news` | 改造为知识库列表 | 文章→知识库 |
| `pages/news_detail/news_detail` | 改造为文档详情 | 文章详情→文档详情 |
| `pages/user/user` | 保留 | 个人中心 |
| `pages/search/search` | 改造 | 搜索知识库+文档+小记 |
| `pages/collection/collection` | 改造为小记列表 | 收藏→小记 |
| — | 新增 `pages/knowledge/list` | 知识库列表页 |
| — | 新增 `pages/knowledge/detail` | 知识库详情页 |
| — | 新增 `pages/document/edit` | 文档编辑页 |
| — | 新增 `pages/memo/list` | 小记列表页 |
| — | 新增 `pages/memo/edit` | 小记编辑页 |

### 1.3 已有API vs 需要的API

| 已有API | V2改造 |
|---------|--------|
| `/article/cate` | → `/knowledge-base/list` |
| `/article/lists` | → `/document/list` |
| `/article/detail` | → `/document/detail` |
| `/article/addCollect` | → `/memo/add` (小记) |
| `/comment/addNew` | 保留 (评论) |
| `/comment/getComment` | 保留 (评论) |

---

## 二、数据库改造方案

### 2.1 保留现有表

```sql
-- 保留 (已存在)
sys_user              -- 用户表
sys_role              -- 角色表
sys_permission        -- 权限表
sys_menu              -- 菜单表
sys_tenant            -- 租户表
plan_info             -- 计划表 (可关联知识库)
plan_schedule_event   -- 日程事件
plan_habit            -- 习惯表
dev_pay_config        -- 支付配置
notice_record         -- 公告记录
```

### 2.2 新增知识管理表

```sql
-- ============================================
-- 知识库表
-- ============================================
CREATE TABLE IF NOT EXISTS `knowledge_base` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '知识库ID',
  `name` varchar(100) NOT NULL COMMENT '知识库名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `cover` varchar(500) DEFAULT NULL COMMENT '封面图URL',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `visibility` tinyint DEFAULT 1 COMMENT '可见性 0=私密 1=公开',
  `doc_count` int DEFAULT 0 COMMENT '文档数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_create_by` (`create_by`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库表';

-- ============================================
-- 知识库成员表 (多对多)
-- ============================================
CREATE TABLE IF NOT EXISTS `knowledge_base_member` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `knowledge_base_id` bigint NOT NULL COMMENT '知识库ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `role_type` tinyint DEFAULT 1 COMMENT '角色类型 1=查看者 2=编辑者 3=管理者',
  `create_time` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_kb_user` (`knowledge_base_id`, `user_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识库成员表';

-- ============================================
-- 目录表
-- ============================================
CREATE TABLE IF NOT EXISTS `directory` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `parent_id` bigint DEFAULT 0 COMMENT '父目录ID(0为根目录)',
  `name` varchar(100) NOT NULL COMMENT '目录名称',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=禁用 1=正常',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='目录表';

-- ============================================
-- 文档表
-- ============================================
CREATE TABLE IF NOT EXISTS `document` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '文档ID',
  `directory_id` bigint DEFAULT NULL COMMENT '所属目录ID',
  `knowledge_base_id` bigint NOT NULL COMMENT '所属知识库ID',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `content` longtext COMMENT '内容(HTML/JSON)',
  `content_type` tinyint DEFAULT 1 COMMENT '内容类型 1=富文本 2=Markdown',
  `view_count` int DEFAULT 0 COMMENT '浏览次数',
  `like_count` int DEFAULT 0 COMMENT '点赞数',
  `comment_count` int DEFAULT 0 COMMENT '评论数',
  `sort` int DEFAULT 0 COMMENT '排序',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=草稿 1=已发布',
  `create_by` bigint DEFAULT NULL COMMENT '创建人ID',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_directory_id` (`directory_id`),
  KEY `idx_kb_id` (`knowledge_base_id`),
  KEY `idx_create_by` (`create_by`),
  FULLTEXT KEY `ft_title_content` (`title`, `content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档表';

-- ============================================
-- 小记表
-- ============================================
CREATE TABLE IF NOT EXISTS `memo` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '小记ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `content` text NOT NULL COMMENT '内容',
  `tags` varchar(500) DEFAULT NULL COMMENT '标签(逗号分隔)',
  `images` text DEFAULT NULL COMMENT '图片URL(JSON数组)',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=删除 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间',
  `delete_time` bigint DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小记表';

-- ============================================
-- 文档评论表 (复用已有comment表结构)
-- ============================================
CREATE TABLE IF NOT EXISTS `document_comment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `document_id` bigint NOT NULL COMMENT '文档ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `content` text NOT NULL COMMENT '评论内容',
  `parent_id` bigint DEFAULT 0 COMMENT '父评论ID(0为一级评论)',
  `status` tinyint DEFAULT 1 COMMENT '状态 0=删除 1=正常',
  `create_time` bigint DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_document_id` (`document_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档评论表';
```

### 2.3 数据库迁移脚本

```sql
-- 执行顺序:
-- 1. 创建知识库相关表
-- 2. 迁移现有文章数据到document表 (可选)
-- 3. 更新sys_menu添加知识库菜单

-- 插入知识库菜单
INSERT INTO `sys_menu` (`name`, `permission`, `type`, `sort`, `status`) VALUES
('知识库管理', 'knowledge:base:list', 1, 1, 1),
('知识库新增', 'knowledge:base:add', 2, 1, 1),
('知识库编辑', 'knowledge:base:edit', 2, 2, 1),
('知识库删除', 'knowledge:base:delete', 2, 3, 1),
('文档管理', 'knowledge:document:list', 1, 2, 1),
('文档新增', 'knowledge:document:add', 2, 1, 1),
('文档编辑', 'knowledge:document:edit', 2, 2, 1),
('文档删除', 'knowledge:document:delete', 2, 3, 1),
('小记管理', 'knowledge:memo:list', 1, 3, 1),
('小记新增', 'knowledge:memo:add', 2, 1, 1),
('小记删除', 'knowledge:memo:delete', 2, 2, 1);
```

---

## 三、后端API设计

### 3.1 知识库模块

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/knowledge-base/list` | 知识库列表 |
| GET | `/api/knowledge-base/{id}` | 知识库详情 |
| POST | `/api/knowledge-base` | 创建知识库 |
| PUT | `/api/knowledge-base/{id}` | 更新知识库 |
| DELETE | `/api/knowledge-base/{id}` | 删除知识库 |
| GET | `/api/knowledge-base/{id}/members` | 知识库成员 |
| POST | `/api/knowledge-base/{id}/members` | 添加成员 |
| DELETE | `/api/knowledge-base/{id}/members/{userId}` | 移除成员 |

### 3.2 目录模块

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/directory/list` | 目录列表 |
| GET | `/api/directory/tree` | 目录树 |
| POST | `/api/directory` | 创建目录 |
| PUT | `/api/directory/{id}` | 更新目录 |
| DELETE | `/api/directory/{id}` | 删除目录 |

### 3.3 文档模块

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/document/list` | 文档列表 |
| GET | `/api/document/{id}` | 文档详情 |
| POST | `/api/document` | 创建文档 |
| PUT | `/api/document/{id}` | 更新文档 |
| DELETE | `/api/document/{id}` | 删除文档 |
| POST | `/api/document/{id}/like` | 点赞文档 |
| GET | `/api/document/{id}/comments` | 文档评论 |
| POST | `/api/document/{id}/comments` | 添加评论 |

### 3.4 小记模块

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/memo/list` | 小记列表 |
| GET | `/api/memo/{id}` | 小记详情 |
| POST | `/api/memo` | 创建小记 |
| PUT | `/api/memo/{id}` | 更新小记 |
| DELETE | `/api/memo/{id}` | 删除小记 |

---

## 四、前端页面改造

### 4.1 TabBar 改造

**现有:**
```json
{
  "list": [
    { "text": "首页", "pagePath": "pages/index/index" },
    { "text": "文章", "pagePath": "pages/news/news" },
    { "text": "我的", "pagePath": "pages/user/user" }
  ]
}
```

**V2改造:**
```json
{
  "list": [
    { "text": "工作台", "pagePath": "pages/index/index" },
    { "text": "知识库", "pagePath": "pages/knowledge/list" },
    { "text": "", "pagePath": "pages/document/edit" },
    { "text": "小记", "pagePath": "pages/memo/list" },
    { "text": "我的", "pagePath": "pages/user/user" }
  ]
}
```

### 4.2 页面目录结构

```
src/pages/
├── index/
│   └── index.vue                    # 首页 (保留+改造)
├── knowledge/
│   ├── list.vue                     # 知识库列表 (原news.vue改造)
│   └── detail.vue                   # 知识库详情 (新增)
├── document/
│   ├── edit.vue                     # 文档编辑 (新增)
│   └── detail.vue                   # 文档详情 (原news_detail.vue改造)
├── memo/
│   ├── list.vue                     # 小记列表 (新增)
│   └── edit.vue                     # 小记编辑 (新增)
├── search/
│   └── search.vue                   # 搜索 (改造)
├── user/
│   └── user.vue                     # 个人中心 (保留)
├── login/
│   └── login.vue                    # 登录 (保留)
└── ...                              # 其他保留
```

### 4.3 API 服务文件

```
src/api/
├── knowledge.ts                     # 知识库API
├── document.ts                      # 文档API
├── memo.ts                          # 小记API
├── news.ts                          # 保留 (兼容)
└── ...                              # 其他保留
```

---

## 五、实现步骤

### Phase 1: 数据库 (1天)
1. [ ] 执行数据库迁移脚本
2. [ ] 验证表结构
3. [ ] 插入测试数据

### Phase 2: 后端API (3天)
1. [ ] 知识库CRUD接口
2. [ ] 目录CRUD接口
3. [ ] 文档CRUD接口
4. [ ] 小记CRUD接口
5. [ ] 单元测试

### Phase 3: 前端页面 (5天)
1. [ ] 改造TabBar导航
2. [ ] 知识库列表页
3. [ ] 知识库详情页
4. [ ] 文档编辑页
5. [ ] 文档详情页
6. [ ] 小记列表页
7. [ ] 小记编辑页
8. [ ] 搜索页改造
9. [ ] 首页改造

### Phase 4: 联调测试 (2天)
1. [ ] API联调
2. [ ] 功能测试
3. [ ] UI优化

---

## 六、关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 富文本编辑器 | 原生contenteditable | 移动端兼容性好 |
| 文档存储格式 | HTML | 与语雀一致 |
| 时间戳格式 | bigint (毫秒) | 与现有plan表一致 |
| 软删除 | delete_time | 与现有表一致 |
| 租户支持 | 继承sys_user.tenant_id | 与现有架构一致 |
| 图片上传 | 复用现有camera截图功能 | 减少重复开发 |

---

## 七、风险点

1. **编辑器兼容性**: contenteditable在不同平台表现不一致，需要测试
2. **数据迁移**: 现有文章数据需要迁移到新表结构
3. **权限控制**: 知识库级别的权限需要与现有RBAC整合
4. **性能**: 文档全文搜索需要MySQL FULLTEXT索引

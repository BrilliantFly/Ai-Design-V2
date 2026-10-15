# 03 —— Vue 管理端设计

## 一、技术栈与目录

- 现有技术栈：Vue 3 + Ant Design Vue 4 + TypeScript + Vite
- API 已放在 `src/api/knowledge/index.ts`（现有知识库 API 文件，追加新方法即可）
- 页面放在 `src/views/knowledge/file/index.vue`

### 1.1 新增文件

```
know-vue/src/
├── api/knowledge/
│   └── index.ts                       ← 追加 4 个文件上传 API
├── router/menus/
│   └── ...                            ← 菜单 SQL 执行后自动生效（后端动态菜单）
└── views/knowledge/file/
    └── index.vue                      ← 新增「文件管理」页
```

### 1.2 API 追加

在现有 `src/api/knowledge/index.ts` 末尾追加：

```typescript
// ========== 文件上传 API (新增) ==========

// 批量上传 HTML/MD 文件
export function uploadKnowledgeFile(
  files: File[],
  knowledgeBaseId?: number,
  uploadPlatform = 'vue'
) {
  const formData = new FormData()
  files.forEach((f) => formData.append('files', f))
  if (knowledgeBaseId) formData.append('knowledgeBaseId', String(knowledgeBaseId))
  formData.append('uploadPlatform', uploadPlatform)
  return service({
    url: '/api/knowledge/file/upload',
    method: 'post',
    data: formData,
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

// 手动重新解析
export function parseKnowledgeFile(fileId: number) {
  return service({
    url: '/api/knowledge/file/parse',
    method: 'post',
    data: { fileId }
  })
}

// 分页查询
export function getUploadedFilePage(params: any) {
  return service({
    url: '/api/knowledge/file/page',
    method: 'get',
    params
  })
}

// 文件详情（含原始内容）
export function getUploadedFile(id: number) {
  return service({
    url: `/api/knowledge/file/${id}`,
    method: 'get'
  })
}

// 删除
export function deleteUploadedFile(id: number) {
  return service({
    url: `/api/knowledge/file/${id}`,
    method: 'delete'
  })
}
```

## 二、侧边栏菜单入口

执行 `kb_file_upload.sql` 后，菜单自动出现在侧边栏「知识管理」目录下：

```
📚 知识管理 (id=20, 已有)
├── 知识库管理 (id=2001, 已有)
├── 文档管理   (id=2002, 已有)
├── 标签管理   (id=2003, 已有)
├── 小记管理   (id=2004, 已有)
└── 文件管理   (id=2005, 新增) ← ✨
    ├── 文件上传  (按钮)
    ├── 文件删除  (按钮)
    └── 文件解析  (按钮)
```

路由配置（动态菜单从后端拉取后自动生成）：

```ts
{
  path: '/knowledge/file',
  component: () => import('@/views/knowledge/file/index.vue'),
  meta: { title: '文件管理', icon: 'upload' }
}
```

## 三、页面设计：文件管理列表

### 3.1 页面结构（参考现有 `knowledge/base/index.vue` 风格）

```
┌──────────────────────────────────────────────────────────────┐
│ 🔍 文件名搜索   知识库▼   解析状态▼   [查询] [重置]           │
├──────────────────────────────────────────────────────────────┤
│ [📤 批量上传]  归属知识库: [请选择▼]                           │
├──────────────────────────────────────────────────────────────┤
│ #  │ 文件名        │ 类型 │ 大小   │ 知识库  │ 状态   │ 操作    │
│ 1  │ guide.html    │ 🌐   │ 12KB   │ 技术文档│ ✅已入库│ 👁 删  │
│ 2  │ readme.md     │ 📝   │ 3.4KB  │ 技术文档│ ✅已入库│ 👁 删  │
│ 3  │ draft.htm     │ 🌐   │ 8.1KB  │ —       │ ⚠️失败 │ ✗ 删  │
└──────────────────────────────────────────────────────────────┘
                         分页组件
```

### 3.2 核心组件

- **Upload.Dragger**（Ant Design Vue）：拖拽上传，`accept=".html,.htm,.md,.markdown"`，`multiple`，`beforeUpload` 做前端校验（扩展名 + 5MB 限制）
- **a-table**：列表展示，`columns` 如下：

| column | key | width | 说明 |
|--------|-----|-------|------|
| 文件名 | originalName | 自适应 | 图标区分 md/html |
| 类型 | fileExt | 80 | Tag：`html→蓝` / `md→绿` |
| 大小 | fileSize | 100 | 格式化为 KB/MB |
| 归属知识库 | knowledgeBaseId | 160 | 关联 KB 名称或「未分类」 |
| 解析状态 | parseStatus | 120 | Tag：`0待解析(黄)` `1成功(绿)` `2失败(红)` |
| 上传时间 | createTime | 180 | 格式化 |
| 操作 | - | 240 | 预览（弹窗）/ 跳到文档 / 删除 / 重新解析 |

### 3.3 预览交互

三种情况：

**(1) 解析成功，有 document_id** → 点击「👁 预览」直接跳到 `/knowledge/document/detail?id={documentId}`

**(2) 解析失败 / 待解析** → 弹窗显示原始内容 + 重新解析按钮

**(3) HTML / MD 原生预览弹窗**（独立组件 `FilePreviewModal.vue`）

```html
<!-- HTML 预览：用 iframe -->
<iframe v-if="fileExt === 'html' || fileExt === 'htm'"
  :srcdoc="fileContent"
  style="width:100%;height:600px;border:none" />

<!-- MD 预览：marked 转 HTML 渲染 -->
<div v-else-if="fileExt === 'md' || fileExt === 'markdown'"
  v-html="marked.parse(fileContent)"
  class="markdown-body" />
```

### 3.4 完整 Vue 组件骨架

```vue
<template>
  <div class="knowledge-file-container">
    <!-- 搜索 -->
    <a-card :bordered="false" class="search-form">
      <a-form :model="queryParams" layout="inline">
        <a-form-item label="文件名">
          <a-input v-model:value="queryParams.keyword" allow-clear placeholder="搜索文件名" />
        </a-form-item>
        <a-form-item label="知识库">
          <a-select v-model:value="queryParams.knowledgeBaseId" allow-clear placeholder="全部" style="width:160px">
            <a-select-option v-for="kb in kbOptions" :key="kb.id" :value="kb.id">{{ kb.name }}</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="状态">
          <a-select v-model:value="queryParams.parseStatus" allow-clear placeholder="全部" style="width:120px">
            <a-select-option :value="0">待解析</a-select-option>
            <a-select-option :value="1">已入库</a-select-option>
            <a-select-option :value="2">失败</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item>
          <a-space>
            <a-button type="primary" @click="fetchData" :icon="h(SearchOutlined)">查询</a-button>
            <a-button @click="handleReset" :icon="h(ReloadOutlined)">重置</a-button>
          </a-space>
        </a-form-item>
      </a-form>
    </a-card>

    <!-- 主体 -->
    <a-card :bordered="false" class="table-wrapper">
      <a-space class="table-toolbar">
        <a-upload-dragger
          :multiple="true"
          accept=".html,.htm,.md,.markdown"
          :before-upload="beforeUpload"
          :show-upload-list="false"
          :custom-request="handleUpload"
        >
          <div style="padding:12px">
            <UploadOutlined style="font-size:28px;color:#25B864" />
            <div style="margin-top:8px;color:#646A73">
              点击或拖拽文件到此区域上传（支持 .html .htm .md .markdown，单个 ≤ 5MB）
            </div>
          </div>
        </a-upload-dragger>
        <a-select v-model:value="uploadKbId" placeholder="归属知识库（可选）" allow-clear style="width:200px">
          <a-select-option v-for="kb in kbOptions" :key="kb.id" :value="kb.id">{{ kb.name }}</a-select-option>
        </a-select>
      </a-space>

      <a-table :columns="columns" :data-source="list"
        :loading="loading" row-key="id"
        :pagination="{ pageSize: 10, showTotal: t => `共 ${t} 条`, current: queryParams.pageNum, total }"
        @change="handleTableChange">
        <template #bodyCell="{ column, record }">
          <!-- 类型列：图标 -->
          <template v-if="column.key === 'type'">
            <a-tag :color="record.fileExt === 'md' || record.fileExt === 'markdown' ? 'green' : 'blue'">
              {{ record.fileExt }}
            </a-tag>
          </template>
          <!-- 状态列 -->
          <template v-if="column.key === 'parseStatus'">
            <a-tag v-if="record.parseStatus === 1" color="success">已入库</a-tag>
            <a-tag v-else-if="record.parseStatus === 0" color="warning">待解析</a-tag>
            <a-tag v-else color="error" :title="record.parseError">失败</a-tag>
          </template>
          <!-- 操作列 -->
          <template v-if="column.key === 'action'">
            <a-space>
              <a-button type="link" size="small" @click="handlePreview(record)">预览</a-button>
              <a-button v-if="record.documentId" type="link" size="small" @click="goToDocument(record)">查看文档</a-button>
              <a-button v-if="record.parseStatus !== 1" type="link" size="small" @click="handleParse(record)">重新解析</a-button>
              <a-popconfirm title="确定删除?" @confirm="handleDelete(record.id)">
                <a-button type="link" danger size="small">删除</a-button>
              </a-popconfirm>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <!-- 预览弹窗 -->
    <FilePreviewModal v-model:open="previewVisible" :file="previewFile" />
  </div>
</template>
```

### 3.5 前端依赖

- 现有项目已引入 `ant-design-vue`、`vue-router`
- Markdown 预览需要 `marked`：`npm i marked`（管理端页面首次引入即可）

## 四、交互流程

```
拖拽/选择文件 → beforeUpload 校验扩展名+大小
         │
         ▼
 handleUpload 批量上传 → 后端自动解析 → 返回结果
         │
         ▼
 message.success("成功 X 个, 失败 Y 个")
         │
         ▼
 fetchData() 刷新列表
         │
         ├─ 解析成功 → 👁 预览 iframe / 📝 marked
         └─ 解析失败 → 显示 parseError + 重新解析
```

## 五、UniApp / Vue 预览能力对齐

| 场景 | Vue 端 | UniApp H5 | UniApp App | UniApp 小程序 |
|------|--------|-----------|------------|---------------|
| HTML | `iframe srcdoc` | `iframe srcdoc` / `rich-text` | `web-view` 打开 | `rich-text` 渲染 body 内容 |
| MD | `marked.parse` + `v-html` | `marked` + `rich-text` | `marked` + `rich-text` | `marked` + `rich-text` |

Vue 管理端是纯 H5 环境，直接用 `iframe srcdoc` / `v-html` 无任何兼容问题。

# 04 —— UniApp 移动端设计

## 一、核心挑战

UniApp 需同时覆盖 **H5 / App / 小程序** 三端，文件上传和 HTML 预览行为差异大：

| 能力 | H5 | App (Android/iOS) | 小程序 (微信) |
|------|----|-------------------|--------------|
| 文件选择 | `<input type="file">` / uni.chooseFile | uni.chooseFile（App 原生文件选择器） | **受限**：只能选 wx.chooseMessageFile（聊天文件）或拍照 |
| 文件上传 | uni.uploadFile | uni.uploadFile | uni.uploadFile |
| HTML 预览 | `iframe srcdoc` | `web-view` 组件 | `rich-text`（不支持 script） |
| MD 预览 | marked.js + `rich-text` | marked.js + `rich-text` | marked.js + `rich-text` |

**策略**：优先保证 H5 和 App 两端完整体验；小程序做降级处理（可上传 MD 但 HTML 只能看 body 纯内容）。

## 二、新增文件结构

```
know-uniapp/src/
├── api/knowledge.ts                  ← 追加 4 个 API（与 Vue 端相同）
├── pages/knowledge/
│   ├── file-upload/
│   │   ├── index.vue                 ← 新增：上传 + 我的文件列表
│   │   └── index.json                ← 页面配置
│   ├── file-preview/
│   │   ├── index.vue                 ← 新增：预览（HTML iframe/web-view + MD marked）
│   │   └── index.json
│   └── ...                            ← 已有的 home/list/detail/document-view 等
├── pages.json                         ← 注册新页面路径
├── stores/                            ← 无需改动
└── utils/                             ← 新增 marked.js 引入说明
```

### 2.1 pages.json 注册

```json
{
  "pages": [
    // ... 原有
    {
      "path": "pages/knowledge/file-upload/index",
      "style": {
        "navigationBarTitleText": "文件导入",
        "navigationBarBackgroundColor": "#ffffff",
        "navigationBarTextStyle": "black"
      }
    },
    {
      "path": "pages/knowledge/file-preview/index",
      "style": {
        "navigationBarTitleText": "文件预览"
      }
    }
  ]
}
```

## 三、菜单入口（UniApp 端）

### 3.1 首页快捷网格入口

执行 `kb_file_upload.sql` 的 `sys_menu_config` INSERT 后，首页「快捷功能」自动出现：

```
┌─────┬─────┬─────┬─────┬─────┐
│ 📹  │ 📅  │ 🎯  │ 👥  │ 📚  │ ← 已有入口
│智能 │日程 │习惯 │客户 │知识 │
│监控 │计划 │打卡 │管理 │库   │
├─────┼─────┼─────┼─────┼─────┤
│ 📝  │ ... │     │     │ 📤  │ ← 新增 📤 文件导入
│快速 │     │     │     │     │
│小记 │     │     │     │     │
└─────┴─────┴─────┴─────┴─────┘
```

点击 → 跳 `/pages/knowledge/file-upload/index`

### 3.2 我的知识库详情页入口

在现有 `pages/knowledge/detail/index.vue` 的 FAB（悬浮按钮）旁或 header 右上角增加「📤 导入文件」按钮，也跳到同一个 file-upload 页面，自动带 `knowledgeBaseId` 参数。

## 四、文件上传页设计

### 4.1 页面结构

```
┌──────────────────────────────────┐
│ ← 文件导入                       │  ← 顶部导航，统一风格
├──────────────────────────────────┤
│  归属知识库                       │
│  [技术文档 ▼]        可选         │
├──────────────────────────────────┤
│  ┌────────────────────────────┐  │
│  │     📂 点击选择文件         │  │  ← 大拖入区
│  │  支持 .html .htm .md       │  │     （UniApp 用大按钮替代拖拽）
│  │       .markdown             │  │
│  │  单个文件 ≤ 5MB             │  │
│  └────────────────────────────┘  │
├──────────────────────────────────┤
│  [已选 3 个文件  🗑 清空]         │
│  ✅ guide.html    12KB           │
│  ✅ readme.md     3.4KB          │
│  ⏳ draft.htm     上传中...      │
├──────────────────────────────────┤
│  🔥 最近上传                      │
│  （我的上传记录，可点预览）       │
├──────────────────────────────────┤
│  [上传全部，解析入库]              │  ← 主按钮
└──────────────────────────────────┘
```

### 4.2 文件选择实现（关键跨平台代码）

```typescript
const chooseFiles = () => {
  // #ifdef H5
  // H5: 原生 input type=file，可多选
  uni.chooseFile({
    count: 20,
    extension: ['.html', '.htm', '.md', '.markdown'],
    success: (res) => {
      // res.tempFiles[{ path, size, name }]
      selectedFiles.value = res.tempFiles.map((f) => ({
        path: f.path,
        name: f.name,
        size: f.size,
        status: 'pending'
      }))
    }
  })
  // #endif

  // #ifdef APP-PLUS
  // App: uni.chooseFile 可用（HBuilderX 3.4.5+）
  // 降级：plus.io 选文件或用原生插件
  uni.chooseFile({
    count: 20,
    extension: ['.html', '.htm', '.md', '.markdown'],
    success: (res) => {
      selectedFiles.value = res.tempFiles.map((f) => ({
        path: f.path,
        name: f.name,
        size: f.size,
        status: 'pending'
      }))
    },
    fail: () => {
      // 降级：打开原生文件管理器
      uni.showToast({ title: '请在文件管理器选择', icon: 'none' })
    }
  })
  // #endif

  // #ifdef MP-WEIXIN
  // 小程序受限：wx.chooseMessageFile 仅能从聊天记录选
  wx.chooseMessageFile({
    count: 20,
    type: 'file',
    extension: ['html', 'htm', 'md', 'markdown'],
    success: (res) => {
      selectedFiles.value = res.tempFiles.map((f) => ({
        path: f.path,
        name: f.name,
        size: f.size,
        status: 'pending'
      }))
    },
    fail: () => {
      uni.showToast({ title: '小程序暂不支持本地文件选择', icon: 'none' })
    }
  })
  // #endif
}
```

### 4.3 批量上传实现

```typescript
const uploadAll = async () => {
  // 先校验（前端也要做一遍）
  const validExts = ['html', 'htm', 'md', 'markdown']
  const oversized = selectedFiles.value.find((f) => f.size > 5 * 1024 * 1024)
  if (oversized) {
    return uni.showToast({ title: `${oversized.name} 超过 5MB`, icon: 'none' })
  }

  // 逐个调用 uni.uploadFile（uni.uploadFile 不支持多文件，需循环）
  for (const f of selectedFiles.value) {
    if (!validExts.includes(f.name.split('.').pop()?.toLowerCase())) {
      f.status = 'error'
      f.errorMsg = '不支持的文件类型'
      continue
    }
    f.status = 'uploading'
    try {
      await new Promise<void>((resolve, reject) => {
        uni.uploadFile({
          url: `${BASE_URL}/api/knowledge/file/upload`,
          filePath: f.path,
          name: 'files',
          formData: {
            knowledgeBaseId: kbId.value ? String(kbId.value) : '',
            uploadPlatform: getUploadPlatform()
          },
          header: { 'Authorization': `Bearer ${getToken()}` },
          success: (res) => {
            const data = JSON.parse(res.data)
            if (data.code === 200) {
              f.status = 'success'
              f.result = data.data?.items?.[0]
            } else {
              f.status = 'error'
              f.errorMsg = data.message || '上传失败'
            }
            resolve()
          },
          fail: reject
        })
      })
    } catch (e) {
      f.status = 'error'
      f.errorMsg = '网络错误'
    }
  }

  uni.showToast({
    title: `成功 ${selectedFiles.value.filter(f => f.status === 'success').length} 个`,
    icon: 'success'
  })
  // 刷新"最近上传"
  loadMyUploads()
}

const getUploadPlatform = () => {
  // #ifdef H5
  return 'uniapp-h5'
  // #endif
  // #ifdef APP-PLUS
  return 'uniapp-app'
  // #endif
  // #ifdef MP-WEIXIN
  return 'uniapp-mp'
  // #endif
}
```

## 五、文件预览页设计

### 5.1 路由参数

```
/pages/knowledge/file-preview/index?id=1001
或
/pages/knowledge/file-preview/index?documentId=123
```

两种入口：直接看上传文件原文 → 或 跳到已解析好的 kb_document。

### 5.2 HTML 预览跨平台实现

```vue
<template>
  <view class="file-preview">
    <!-- 解析成功：优先展示 kb_document（与文档详情页一致体验） -->
    <template v-if="docContent">
      <view class="doc-content">
        <rich-text :nodes="renderedContent" />
      </view>
    </template>

    <!-- HTML 原文预览（未解析或想直接看源文件） -->
    <template v-else-if="fileExt === 'html' || fileExt === 'htm'">
      <!-- #ifdef H5 -->
      <iframe :srcdoc="fileContent" class="html-frame" />
      <!-- #endif -->

      <!-- #ifdef APP-PLUS -->
      <web-view :src="htmlDataUrl" />
      <!-- #endif -->

      <!-- #ifdef MP-WEIXIN -->
      <!-- 小程序不支持 web-view srcdoc，用 rich-text 渲染 body -->
      <rich-text :nodes="htmlBodyOnly" />
      <!-- #endif -->
    </template>

    <!-- MD 预览：统一 marked.js -->
    <template v-else-if="fileExt === 'md' || fileExt === 'markdown'">
      <rich-text :nodes="markedRendered" />
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { marked } from 'marked'
import { getUploadedFile, getDocument } from '@/api/knowledge'

const fileContent = ref('')
const fileExt = ref('')
const docContent = ref('')

// H5 iframe srcdoc
// App web-view 需用 data URL 或临时页面
const htmlDataUrl = computed(() =>
  `data:text/html;charset=utf-8,${encodeURIComponent(fileContent.value)}`
)

// 小程序 rich-text：只提取 <body> 内容
const htmlBodyOnly = computed(() => {
  const m = fileContent.value.match(/<body[^>]*>([\s\S]*?)<\/body>/i)
  return m ? m[1] : fileContent.value
})

const markedRendered = computed(() => marked.parse(fileContent.value || '') as string)
const renderedContent = computed(() => docContent.value || markedRendered.value)

onMounted(async () => {
  const fileId = route.query.id
  const documentId = route.query.documentId
  if (documentId) {
    const doc = await getDocument(Number(documentId))
    docContent.value = doc?.data?.content || ''
  } else if (fileId) {
    const file = await getUploadedFile(Number(fileId))
    fileContent.value = file?.data?.fileContent || ''
    fileExt.value = file?.data?.fileExt || ''
    // 若已解析成功，顺带拉 doc 内容，让体验一致
    if (file?.data?.documentId) {
      const doc = await getDocument(file.data.documentId)
      docContent.value = doc?.data?.content || ''
    }
  }
})
</script>

<style scoped lang="scss">
.file-preview { padding: 24rpx; min-height: 100vh; background: #fff; }
.html-frame { width: 100%; min-height: 80vh; border: none; }
.doc-content ::v-deep(h1) { font-size: 40rpx; font-weight: 700; margin: 32rpx 0 16rpx; }
.doc-content ::v-deep(h2) { font-size: 36rpx; font-weight: 600; margin: 28rpx 0 14rpx; }
.doc-content ::v-deep(p)  { font-size: 28rpx; line-height: 1.7; margin: 14rpx 0; color: #1F2329; }
.doc-content ::v-deep(code){ background: #F1F5F2; padding: 2rpx 8rpx; border-radius: 6rpx; font-family: monospace; }
.doc-content ::v-deep(pre) { background: #1F2329; color: #E8F8EF; padding: 24rpx; border-radius: 16rpx; overflow-x: auto; }
.doc-content ::v-deep(a) { color: #25B864; text-decoration: underline; }
</style>
```

### 5.3 App 端 web-view 注意

`web-view` 组件的 `src` 不支持直接传 HTML 源码字符串，有两个方案：

1. **后端中转**：后端新增 `/api/knowledge/file/{id}/render` 接口，返回临时 HTML 页面（带 Cache-Control: no-store），web-view 直接打开这个 URL —— **推荐，最稳定**
2. **data URL**：`src="data:text/html;charset=utf-8,xxx"` —— Android 部分版本支持不佳

后端中转方案接口新增（可选增强，不一定需要）：

```
GET /api/knowledge/file/{id}/render
→ Content-Type: text/html
→ Cache-Control: no-store, no-cache, must-revalidate
```

## 六、样式规范（与已有页面对齐）

沿用 `pages/knowledge/list/index.vue` 的主题变量：

```scss
$color-primary: var(--color-primary, #25B864);
$color-bg-app: var(--color-bg-app, #F8FAF9);
$color-surface: var(--color-surface, #fff);
$color-text: var(--color-text, #1F2329);
$color-text-secondary: var(--color-text-secondary, #646A73);
$color-border: var(--color-border-light, #E8E9EB);
$radius-lg: 24rpx;
$radius-xl: 32rpx;
```

## 七、UniApp 特有的坑位

| 坑 | 解决 |
|----|------|
| uni.uploadFile **不**支持 files[] 多文件字段 | 循环逐个调 uni.uploadFile，前端自己累加 |
| 小程序不支持 `<input type=file>` | 用 `wx.chooseMessageFile` 降级，或提示用户用 App/H5 |
| `<web-view>` 会**覆盖整个页面**（不能放局部） | App 端专门开一页 web-view，不要和其他元素混排 |
| App 端 web-view 要配业务域名白名单 | 后端中转 URL 必须加在 `manifest.json` 的 `h5.webViewDomain` |
| H5 端 iframe srcdoc 跨域 | srcdoc 不受同源策略影响，直接用 ✅ |
| MD 转 HTML 的代码高亮 | marked + highlight.js，或前端只渲染文本（V1 不做代码高亮） |
| `rich-text` 不支持 script 标签 | HTML 文件里的 `<script>` 在小程序端不会执行（这是**安全特性**，也是限制） |

## 八、pages.json diff 模板

```json
// 追加到 pages 数组（不要覆盖已有）
{
  "path": "pages/knowledge/file-upload/index",
  "style": {
    "navigationBarTitleText": "文件导入",
    "navigationBarBackgroundColor": "#ffffff",
    "navigationBarTextStyle": "black"
  }
},
{
  "path": "pages/knowledge/file-preview/index",
  "style": {
    "navigationBarTitleText": "文件预览",
    "navigationBarBackgroundColor": "#ffffff",
    "navigationBarTextStyle": "black"
  }
}
```

## 九、依赖引入

```bash
# know-uniapp 根目录执行
npm i marked
```

在 `main.ts` 或具体页面 `import { marked } from 'marked'`。

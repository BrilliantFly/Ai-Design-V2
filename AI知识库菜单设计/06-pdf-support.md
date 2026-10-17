# 06 —— PDF 支持设计

## 1. 需求
文件格式除了 html/md，还要支持 `pdf`。

## 2. 数据库设计

### 2.1 `kb_uploaded_file` 扩展
现有字段已满足需求（`file_ext` VARCHAR(20)、`mime_type` VARCHAR(100)），只需允许值 `pdf`。

**SQL 补丁：**  
无需改字段类型，仅扩展业务校验。推荐同步更新表注释（非必需）。

```sql
-- 注释补充（可选）
ALTER TABLE `kb_uploaded_file` MODIFY COLUMN `file_ext`
  VARCHAR(20) NOT NULL COMMENT '扩展名: html / htm / md / markdown / pdf';
```

### 2.2 `kb_document.contentType` 扩展（推荐）
当前 `kb_document.contentType` 支持 `richtext`/`markdown`。PDF 导入生成的文档建议新增 `pdf` 类型，便于前端判断：

```sql
-- kb_document.contentType 注释扩展（可选，按现有设计不强制改表结构，字符串即可）
```

后端实体注释建议更新：
```java
@ApiModelProperty("内容类型: richtext/markdown/pdf")
private String contentType;
```

## 3. 后端设计

### 3.1 上传校验（`KbFileUploadController` / Service）
- 允许扩展名：`.pdf`, `.PDF`
- MIME 校验：`application/pdf`
- 文件大小限制：建议 ≤ 10MB（可配置）

### 3.2 文件存储
沿用现有逻辑：将文件写入磁盘 `./upload/knowledge/{yyyyMMdd}/`，保存 `filePath`。  
**PDF 不做全文文本提取入库**：`fileContent` 对于 PDF 可设置为 `NULL` 或空字符串（避免将二进制误存为文本）。现有 HTML/MD 会读取文本存库，用于预览回退；PDF 不需要此回退。

### 3.3 解析逻辑（PDF 特殊处理）
现有解析逻辑（HTML→richtext、MD→markdown、生成 kb_document 并回写 document_id + parse_status=1）。

**PDF 推荐处理方式：**
```java
if ("pdf".equalsIgnoreCase(ext)) {
  // PDF：不提取可编辑内容
  doc.setTitle(title);
  doc.setContent(""); // 或保留空，不用于渲染
  doc.setContentType("pdf");
  // parse_status：文件已成功落盘并关联，视为解析成功
  uploadFile.setParseStatus(1);
  uploadFile.setDocumentId(doc.getId());
}
```

> 语义说明：PDF 不需要“解析为编辑器内容”，但需要建立 `kb_uploaded_file.document_id` 关联，以便列表/入口分支能识别“来自文件上传”。

### 3.4 PDF 渲染接口（App 端推荐）
为提升 App 端（uniapp APP-PLUS）web-view 稳定性，新增可直接渲染的 HTML 中转接口：

```java
@GetMapping("/{id}/render")
public void renderPdf(@PathVariable Long id, HttpServletResponse response) throws IOException {
  KbUploadedFile file = service.getById(id);
  // 设置 Content-Type
  if ("pdf".equalsIgnoreCase(file.getFileExt())) {
    response.setContentType("application/pdf");
  } else {
    response.setContentType("text/html;charset=UTF-8");
  }
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  // 读取磁盘文件流写出
  // ...
}
```

返回的 URL：`/api/knowledge/file/{id}/render`，可直接用于 `web-view :src`。

> 此接口为可选增强（H5 可直接用 `/uploads/...pdf`，App 推荐用此中转）。

## 4. 前端设计

### 4.1 know-vue（管理端）

**文件上传页校验**（`views/knowledge/file/index.vue`）：`accept=".html,.htm,.md,.markdown,.pdf"`

**文件管理列表**：`fileExt` 标签新增 `pdf`（颜色建议 `volcano`/`red`）

**文件预览弹窗 `FilePreviewModal.vue`（增强）：**
```vue
<template v-if="isPdf">
  <!-- 推荐 PDF.js 内嵌，或直接 iframe -->
  <iframe :src="pdfViewerUrl" style="width:100%;height:700px;border:none" />
</template>
```

`pdfViewerUrl`：
- 方案A（PDF.js）：`/pdfjs/web/viewer.html?file=${encodeURIComponent(pdfFileUrl)}`
- 方案B（直接打开）：`pdfFileUrl`（部分浏览器支持内嵌 PDF）

**PDF.js 部署**：将 `pdfjs-dist` 构建产物复制到 `know-vue/public/pdfjs/`，确保 `viewer.html` 可访问。

### 4.2 know-uniapp（移动端）

**文件上传页（`file-upload/index.vue`）**
- `extension: ['.html','.htm','.md','.markdown','.pdf']`
- 文件大小校验 ≤ 10MB

**文件预览页（`file-preview/index.vue`）— 新增 PDF 分支**

```vue
<template>
  <!-- PDF -->
  <template v-else-if="isPdf">
    <!-- #ifdef H5 -->
    <iframe :src="pdfUrl" class="pdf-frame" />
    <!-- #endif -->
    <!-- #ifdef APP-PLUS -->
    <web-view :src="pdfRenderUrl || pdfUrl" />
    <!-- #endif -->
    <!-- #ifdef MP-WEIXIN -->
    <view class="pdf-tip">
      <text>小程序暂不支持内预览 PDF，可用外部应用打开</text>
      <button @click="openPdfInWx">外部打开</button>
    </view>
    <!-- #endif -->
  </template>
</template>
```

**计算属性：**
```ts
const isPdf = computed(() => fileExt.value === 'pdf')
const pdfUrl = computed(() => filePath.value ? (appConfig.baseUrl + filePath.value.replace(/^\.\/?/, '')) : '')
const pdfRenderUrl = computed(() => fileId.value ? (appConfig.baseUrl + `api/knowledge/file/${fileId.value}/render`) : '')
```

**小程序外部打开（可选）：**
```ts
const openPdfInWx = () => {
  wx.downloadFile({
    url: pdfUrl.value,
    success: (res) => {
      wx.openDocument({ filePath: res.tempFilePath, showMenu: true })
    }
  })
}
```

> 注意：微信 `wx.openDocument` 要求 URL 为 HTTPS 且可访问。

## 5. 校验与限制

| 项目 | 限制 | 说明 |
|---|---|---|
| 单文件大小 | ≤ 10MB | PDF 可略大于纯文本，建议 10MB |
| 批量上传 | ≤ 20 个 | 与现有一致 |
| 支持扩展名 | `.html,.htm,.md,.markdown,.pdf` | 大小写不敏感 |
| 小程序 PDF | 降级处理 | 推荐外部打开或引导到 App/H5 |

## 6. 风险与降级

| 风险 | 影响 | 降级方案 |
|---|---|---|
| PDF.js 体积较大（管理端） | 首屏加载略增 | 可改用直接 iframe 打开 PDF（现代浏览器原生支持） |
| App web-view 加载大 PDF 慢 | 首次打开延迟 | 优先用 `/render` 接口或提示用户等待 |
| 小程序无法内预览 | 用户体验受限 | `wx.openDocument` 外部打开（需 HTTPS）或文案提示“请在 App/H5 查看” |
| PDF 存入 LONGTEXT 导致编码问题 | 数据错乱 | **不将 PDF 存入 `fileContent`**，只存磁盘路径（按 3.2 处理） |

## 7. SQL 补丁文件

新增文件：`E:\Ai-Project\Ai-Design-V2\AI知识库菜单设计\kb_file_upload_pdf.sql`

```sql
-- ============================================================
-- AI 知识库 —— PDF 支持补丁 SQL
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. kb_uploaded_file.file_ext 注释扩展（说明支持 pdf）
-- （MySQL ALTER COMMENT 非必需，如需可手动更新表注释）

-- 2. 示例：校验现有数据（可选）
-- SELECT DISTINCT file_ext FROM kb_uploaded_file;

SET FOREIGN_KEY_CHECKS = 1;
```

> 实际落地时，后端校验、前端 accept、预览分支三端需同步更新。此设计文档为实施依据。

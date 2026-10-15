# 02 —— 后端 API 设计

## 一、技术落点

### 1.1 模块归属

所有新增代码放在 **know-boot-knowledge** 模块：

```
know-boot-knowledge/src/main/java/com/know/knowboot/
├── controller/knowledge/
│   └── KbFileUploadController.java        ← 新增
├── service/knowledge/
│   ├── IKbFileUploadService.java          ← 新增 接口
│   └── impl/
│       └── KbFileUploadServiceImpl.java   ← 新增 实现
├── mapper/knowledge/
│   └── KbUploadedFileMapper.java          ← 新增
├── entity/knowledge/
│   └── KbUploadedFile.java                ← 新增
└── resources/mapper/knowledge/
    └── KbUploadedFileMapper.xml           ← 新增 (如需自定义 SQL)
```

### 1.2 依赖

- 复用现有 MyBatis-Plus（`@TableName`、`@TableId`、`@TableLogic`）
- 复用现有 Sa-Token / JWT 鉴权拦截器
- 文件存储复用系统已有文件上传工具类（如 `FileUtils` / `StorageService`，若没有则用 `Files.write` 存到 `./upload/knowledge/` 目录）
- Markdown 解析：可选 `commonmark-java`（解析后生成 HTML 写入 `kb_document.content`）

### 1.3 Entity 示例

```java
package com.know.knowboot.entity.knowledge;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.io.Serializable;

/**
 * 知识库上传文件实体
 */
@Data
@TableName("kb_uploaded_file")
public class KbUploadedFile implements Serializable {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    private String originalName;
    private String fileName;
    private String filePath;
    private String fileExt;          // html / htm / md / markdown
    private String fileContent;      // 原始文本内容
    private Long fileSize;
    private String mimeType;
    private Long knowledgeBaseId;
    private Long documentId;         // 解析后生成的 kb_document.id
    private Integer parseStatus;     // 0待解析 1成功 2失败
    private String parseError;
    private String sourceType;       // upload
    private String uploadPlatform;   // vue / uniapp-h5 ...
    private Integer sort;
    private Integer status;          // 0禁用 1正常
    private Long createBy;
    private Long createTime;
    private Long updateTime;
    @TableLogic(value = "0", delval = "1")
    private Long deleteTime = 0L;
}
```

## 二、接口规范

### 2.1 统一响应格式（与现有项目一致）

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1704067200000
}
```

### 2.2 分页参数

```json
{ "pageNum": 1, "pageSize": 10, "keyword": "搜索", "parseStatus": 1 }
```

## 三、接口清单

### 3.1 文件上传（核心）

**POST** `/api/knowledge/file/upload`

- Content-Type: `multipart/form-data`
- 支持多文件
- 请求字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| files | MultipartFile[] | ✅ | 上传的文件列表 |
| knowledgeBaseId | Long | ❌ | 归属知识库 ID |
| uploadPlatform | String | ❌ | 调用端标识：vue / uniapp-h5 / uniapp-app |

- 处理逻辑：

```
1. 遍历 files，逐个校验扩展名（仅允许 html / htm / md / markdown）
2. 为每个文件生成 UUID 存储名，保存到磁盘 ./upload/knowledge/{yyyyMMdd}/
3. 读取文件内容为文本（HTML / MD 都是纯文本，注意 UTF-8 BOM 处理）
4. 写入 kb_uploaded_file，parse_status=0
5. 对每个文件执行"解析入库"（见 3.2）
6. 返回成功条数 + 失败明细
```

- 响应：

```json
{
  "code": 200,
  "data": {
    "successCount": 3,
    "failCount": 1,
    "items": [
      { "originalName": "guide.html", "parseStatus": 1, "documentId": 123 },
      { "originalName": "readme.md",  "parseStatus": 1, "documentId": 124 },
      { "originalName": "notes.htm",  "parseStatus": 1, "documentId": 125 },
      { "originalName": "image.png",  "parseStatus": 2, "parseError": "不支持的文件类型" }
    ]
  }
}
```

### 3.2 解析入库

**POST** `/api/knowledge/file/parse`

- 手动触发（一般 upload 内部已自动调用，此处用于重新解析）
- 请求：

```json
{ "fileId": 1001 }
```

- 处理逻辑：

```
1. 读取 kb_uploaded_file.file_content + file_ext
2. 根据扩展名决定 contentType 和 content 写入方式：
   - .html / .htm → contentType='richtext'  content=原始 HTML 文本
   - .md  / .markdown → contentType='markdown'  content=原始 Markdown 文本
     （可选：同时用 commonmark-java 转一份 HTML 备用，但建议只存 MD 原文，
      预览时前端 marked.js 解析即可，减少后端依赖）
3. 创建 kb_document：
   title = originalName 去扩展名
   knowledgeBaseId = 请求的 knowledgeBaseId（未指定则为 0/null，归属到"未分类"）
   content = 解析后的文本
   contentType = richtext / markdown
   status = 1（直接发布）
4. 回写 kb_uploaded_file.document_id + parse_status=1
5. 知识库 doc_count +1
```

### 3.3 分页查询（Vue 管理端列表 + UniApp 我的上传）

**GET** `/api/knowledge/file/page`

| 参数 | 类型 | 说明 |
|------|------|------|
| pageNum / pageSize | int | 分页 |
| knowledgeBaseId | Long | 按知识库过滤 |
| parseStatus | int | 0待解析 / 1成功 / 2失败 |
| keyword | String | 按文件名搜索 |
| createBy | Long | 按上传人过滤（UniApp 我的上传场景） |

响应：

```json
{
  "code": 200,
  "data": {
    "records": [
      {
        "id": 1001,
        "originalName": "guide.html",
        "fileExt": "html",
        "fileSize": 12345,
        "knowledgeBaseId": 1,
        "documentId": 123,
        "parseStatus": 1,
        "createTime": 1704067200000
      }
    ],
    "total": 50, "pageNum": 1, "pageSize": 10
  }
}
```

### 3.4 文件详情（预览前获取原文）

**GET** `/api/knowledge/file/{id}`

响应包含完整 `fileContent`（HTML 源码或 MD 源码）+ `documentId` 用于一键跳转到文档预览。

### 3.5 删除（软删）

**DELETE** `/api/knowledge/file/{id}`

- 同时删除关联的 `kb_document`（若已解析），或标记为 `delete_time=now`
- 知识库 doc_count -1

### 3.6 关联到知识库

**PUT** `/api/knowledge/file/{id}/bind-kb`

```json
{ "knowledgeBaseId": 5 }
```

## 四、Controller 骨架

```java
package com.know.knowboot.controller.knowledge;

import cn.dev33.satoken.annotation.SaCheckPermission;
import com.know.knowboot.common.R;
import com.know.knowboot.entity.knowledge.KbUploadedFile;
import com.know.knowboot.service.knowledge.IKbFileUploadService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Api(tags = "知识库-文件上传")
@RestController
@RequestMapping("/api/knowledge/file")
@RequiredArgsConstructor
public class KbFileUploadController {

    private final IKbFileUploadService fileUploadService;

    @ApiOperation("批量上传 HTML/MD 文件")
    @PostMapping("/upload")
    @SaCheckPermission("knowledge:file:upload")
    public R<?> upload(
            @RequestParam("files") MultipartFile[] files,
            @RequestParam(value = "knowledgeBaseId", required = false) Long knowledgeBaseId,
            @RequestParam(value = "uploadPlatform", required = false) String uploadPlatform) {
        return R.ok(fileUploadService.batchUpload(files, knowledgeBaseId, uploadPlatform));
    }

    @ApiOperation("手动重新解析")
    @PostMapping("/parse")
    @SaCheckPermission("knowledge:file:parse")
    public R<?> parse(@RequestBody java.util.Map<String, Long> body) {
        return R.ok(fileUploadService.parse(body.get("fileId")));
    }

    @ApiOperation("分页查询")
    @GetMapping("/page")
    @SaCheckPermission("knowledge:file:view")
    public R<?> page(KbUploadedFile query) {
        return R.ok(fileUploadService.page(query));
    }

    @ApiOperation("文件详情")
    @GetMapping("/{id}")
    @SaCheckPermission("knowledge:file:view")
    public R<?> detail(@PathVariable Long id) {
        return R.ok(fileUploadService.getById(id));
    }

    @ApiOperation("删除")
    @DeleteMapping("/{id}")
    @SaCheckPermission("knowledge:file:delete")
    public R<?> delete(@PathVariable Long id) {
        fileUploadService.removeWithDocument(id);
        return R.ok();
    }
}
```

## 五、Service 实现要点

```
batchUpload(files, knowledgeBaseId, uploadPlatform)
  │
  ├─ 遍历 files:
  │   ├─ 校验扩展名 (html/htm/md/markdown)，跳过不支持的 → item.fail
  │   ├─ 校验大小 ≤ 5MB
  │   ├─ 生成 UUID 文件名，计算存盘路径 ./upload/knowledge/{yyyyMMdd}/{uuid}.{ext}
  │   ├─ Files.write(bytes, path) —— 用 UTF-8
  │   ├─ 读取 fileContent 文本（注意处理 UTF-8 BOM: \uFEFF）
  │   ├─ INSERT kb_uploaded_file (parse_status=0)
  │   └─ 调用 parse 内部方法
  │
  └─ 返回 BatchUploadResult(successCount, failCount, items)

parse(fileId)
  │
  ├─ SELECT kb_uploaded_file
  ├─ 判断 file_ext → contentType 映射
  │   html/htm → richtext
  │   md/markdown → markdown
  ├─ INSERT kb_document (title, content, contentType, knowledgeBaseId, status=1)
  ├─ UPDATE kb_uploaded_file SET document_id=?, parse_status=1
  └─ UPDATE kb_knowledge_base SET doc_count = doc_count + 1 (若关联了 KB)
```

## 六、异常处理

| 场景 | 处理 |
|------|------|
| 上传文件为空 | `R.fail("未接收到文件")` |
| 扩展名不支持 | 批量中单项失败，标记 parse_status=2 |
| 文件过大 | `R.fail("单个文件不得超过 5MB")` |
| 存盘 IO 异常 | 标记 parse_status=2 + parse_error |
| 磁盘空间不足 | 同上 |
| 已上传再次点击解析 | 幂等：已 parse_status=1 时先删除旧 kb_document 再重新创建 |

## 七、文件存储路径

```
{项目根目录}/upload/knowledge/{yyyyMMdd}/{UUID}.{ext}
例：./upload/knowledge/20261013/550e8400-e29b-41d4-a716-446655440000.html
```

Spring Boot `application.yml` 建议配置：

```yaml
upload:
  path: ./upload
  knowledge-dir: knowledge
  max-file-size: 5MB
  max-request-size: 100MB
```

Nginx 若需静态访问：

```nginx
location /upload/ {
    alias /path/to/upload/;
    expires 7d;
}
```

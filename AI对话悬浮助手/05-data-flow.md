# 05 - 数据流程与实例化逻辑

## 5.1 流程总览

```
[管理员] 配置 opencode 地址
      │  PUT /api/ai/config  →  ai_opencode_config (+AES token)
      ▼
[用户] 打开任意页面 → 悬浮球
      │  GET /api/ai/config/status  →  {configured, reachable}
      ▼
[用户] 点击悬浮球 → 展开对话框
      │  GET /api/ai/models  →  后端代理 opencode /api/model，标注 isFree
      ▼
      │  选择免费模型（默认 isFree）
      ▼
[用户] 输入首条消息
      │  POST /api/ai/session（携带 providerId/modelId）
      │    → opencode POST /api/session → sessionKey
      │    → INSERT ai_chat_session
      │  POST /api/ai/chat/stream（sessionId, content）
      ▼
[后端] 流式管道
      │  1) INSERT ai_chat_message(role=user)
      │  2) opencode POST /api/session/{key}/prompt
      │  3) 轮询/事件流获取 assistant 增量 → SseEmitter 推 delta
      │  4) 完成 → INSERT ai_chat_message(role=assistant) → 推 done
      ▼
[用户] 看到流式回复；可继续追问（复用会话）
      ▼
[用户] 切换模型 / 新建会话 / 删除会话
```

---

## 5.2 场景一：首次配置

| 步骤 | 前端 | 后端 | opencode |
|------|------|------|----------|
| 1 | 打开「系统管理 → AI 助手设置」 | — | — |
| 2 | 填写访问地址，点「测试连接」 | `POST /api/ai/config/test` | `GET /api/info` |
| 3 | 展示可达 + 模型数 | 代理 `GET /api/model` 统计 | `GET /api/model` |
| 4 | 保存 | `PUT /api/ai/config` → 加密入库、清缓存 | — |

失败处理：

- 地址不可达 → 返回 `{reachable:false, message}`，前端标红但**允许保存**（先存后通）；
- 地址非法（非 http/https）→ 直接 400 拒绝。

---

## 5.3 场景二：列出免费模型

```
GET /api/ai/models
 → 读配置 → GET {base}/api/model  →  { data: Model.Info[] }
 → isFree = cost 为空 或 所有档位 input=0 && output=0
 → 排序：isFree 优先，其次 time.released 倒序
 → 返回 ModelVO[]
```

缓存：后端对模型清单做 **30 秒内存缓存**（Redis 可选），避免频繁打 opencode。

---

## 5.4 场景三：新建会话

```
POST /api/ai/session { providerId, modelId, title }
 → 若模型为空：GET {base}/api/model/default
 → POST {base}/api/session  body:{title, model:{providerID,id}}
 → 返回 Session.Info  → sessionKey
 → INSERT ai_chat_session(user_id, session_key, provider_id, model_id, model_name)
 → 返回 { id, sessionKey, providerId, modelId }
```

> 一个用户可拥有多个会话；前端弹层内"会话列表"按 `last_time` 倒序。

---

## 5.5 场景四：流式对话（核心）

**前端：**

```
1. 若 sessionId 为空 → 先 POST /api/ai/session
2. 追加本地用户气泡
3. streamChat({ sessionId, content, providerId, modelId })
   - onStart  → 创建助手占位气泡
   - onDelta  → 追加文本，滚动到底
   - onDone   → 结束 loading，标记完成
   - onError  → 气泡标红 + 重试
4. 用户可随时点「停止」→ AbortController + POST /api/ai/chat/{id}/stop
```

**后端（轮询兜底版）：**

```
SseEmitter e = new SseEmitter(readTimeoutMs)
new Thread(() -> {
    try {
        saveUserMessage();                                   // INSERT user
        AiChatMessage asst = saveAssistantPlaceholder();     // INSERT assistant(status=0)
        openCodeClient.prompt(cfg, key, content);            // 触发
        int last = 0;
        long deadline = now + readTimeoutMs;
        while (now < deadline) {
            JSONArray msgs = openCodeClient.listMessages(cfg, key);
            String text = extractAssistantText(msgs);        // content[].type=="text"
            if (text.length() > last) {
                e.send(sse("delta", {text: text.substring(last)}));
                last = text.length();
            }
            if (isCompleted(msgs)) {                          // time.completed 已置位
                updateAssistant(asst, text, finish, tokens, cost);
                e.send(sse("done", {content: text, finish: finish}));
                e.complete();
                return;
            }
            sleep(400);
        }
        e.send(sse("error", {message: "生成超时"}));
        e.complete();
    } catch (Exception ex) {
        markAssistantFailed(ex);
        e.send(sse("error", {message: ex.getMessage()}));
        e.completeWithError(ex);
    }
});
return e;
```

**聚合规则：**

```
assistant 文本 = concat( msg.content[] where type=="text" → .text )
已完成判定   = msg.time.completed != null
失败判定     = msg.error != null || msg.finish == "error"
```

---

## 5.6 场景五：切换模型 / 删除会话

```
切换：POST /api/ai/session/{id}/model { providerId, modelId }
      → UPDATE ai_chat_session
      → POST {base}/api/session/{key}/model { providerID, id }   (204)

删除：DELETE /api/ai/session/{id}
      → UPDATE ai_chat_session SET del_flag=1
      → 尽力 DELETE {base}/api/session/{key}（失败仅日志）
```

---

## 5.7 数据一致性

| 关注点 | 策略 |
|--------|------|
| opencode 不可达 | 本地消息保留；助手消息标 `status=2`；前端可重试 |
| 流式中断/超时 | 已输出文本落库为 `status=1`（部分），`finish=length`，前端提示可续问 |
| 重复消息 | `ai_chat_message.msg_id` 唯一性校验（可空），避免重试重复写 |
| 会话孤儿 | opencode 会话被外部删除 → 本地仍可看历史；新消息返回 404 时提示"会话已失效，新建会话" |
| 并发发送 | 前端同一会话禁用输入；后端对同会话加锁（Redis/本地锁） |
| token 过期 | 401 → 前端清 token 跳登录（复用 axios/request 既有拦截） |

---

## 5.8 时序图（对话）

```
用户        Vue/UniApp          know-boot-ai         opencode
 │  输入文本   │                     │                   │
 │───────────▶│  POST /ai/chat/stream│                   │
 │            │────────────────────▶│  INSERT user msg   │
 │            │                     │  POST /prompt ────▶│
 │            │                     │  poll /message ───▶│
 │            │   delta(text)       │◀── assistant 文本 ──│
 │            │◀────────────────────│                   │
 │  ...        │       ...           │       ...          │
 │            │   done(content)     │  INSERT assistant  │
 │            │◀────────────────────│                   │
 │ 看到完整回复 │                     │                   │
```

---

## 5.9 实例：一次完整交互的数据落库

```text
1. 配置：ai_opencode_config(id=1, base_url='http://127.0.0.1:4096', status=1)
2. 会话：POST /api/ai/session
   → ai_chat_session(id=100, user_id=1, session_key='ses_abc',
                     provider_id='opencode', model_id='big-pickle',
                     model_name='Big Pickle', message_count=0, last_time=...)
3. 用户消息：ai_chat_message(id=1001, session_id=100, role='user',
                     content='帮我写一段产品简介', status=1)
4. 助手消息：ai_chat_message(id=1002, session_id=100, role='assistant',
                     content='...生成内容...', tokens_out=128, cost=0,
                     finish='stop', status=1)
5. 回写：UPDATE ai_chat_session SET message_count=2, last_time=...
```

# 04 - App 端（uni-app）检测 → 下载 → 安装流程

> 目标文件：`E:\Ai-Project\Ai-Front\know-uniapp\src\App.vue`（onLaunch 钩子）
> 平台：仅 App 端生效（条件编译 `#ifdef APP-PLUS`），H5/小程序跳过
> 依赖：`plus.runtime`（HTML5+ Runtime，App 专用）

## 4.1 整体时序

```
onLaunch
   │
   ├─ #ifdef APP-PLUS ── checkAppUpdate()
   │      │
   │      ├─ 1. GET /api/system/app/version/latest?platform=android&versionCode=100
   │      │      ├─ hasUpdate=false → 结束
   │      │      └─ hasUpdate=true  → 弹窗
   │      │             ├─ forceUpdate=true  → 弹窗【不可取消】，立即下载安装
   │      │             └─ forceUpdate=false → 弹窗【可取消/稍后】，下载安装
   │      │
   │      ├─ 2. uni.downloadFile (wgt URL) → 本地临时文件
   │      │
   │      ├─ 3. plus.runtime.install(本地路径, {force:false}, onSuccess, onError)
   │      │
   │      └─ 4. onSuccess → plus.runtime.restart()   // 重启生效
   │
   └─ 其余初始化（getTheme/getConfig/loadMenuConfig...）
```

## 4.2 关键代码（实现阶段参考）

```ts
// App.vue 内新增
//#ifdef APP-PLUS
const checkAppUpdate = async () => {
    try {
        const systemInfo = uni.getSystemInfoSync()
        const platform = systemInfo.platform === 'ios' ? 'ios' : 'android'
        // manifest versionCode（构建时写入，运行时读取）
        const versionCode = Number(plus.runtime.version || 0)

        const res = await request<any>({
            url: '/api/system/app/version/latest',
            method: 'GET',
            data: { platform, versionCode },
        })
        const data = res?.data
        if (!data || !data.hasUpdate || !data.latest) return

        const { latest, forceUpdate } = data
        uni.showModal({
            title: '发现新版本 ' + latest.versionName,
            content: latest.updateDesc || '是否立即更新？',
            showCancel: !forceUpdate,
            cancelText: '稍后再说',
            confirmText: '立即更新',
            success: (r) => {
                if (r.confirm) downloadAndInstall(latest.downloadUrl, forceUpdate)
            },
        })
    } catch (e) {
        // 检测失败静默跳过，不阻塞启动
        console.warn('[App] 检查更新失败', e)
    }
}

const downloadAndInstall = (url: string, force: boolean) => {
    uni.showLoading({ title: '下载更新包...' })
    uni.downloadFile({
        url,
        success: (res) => {
            uni.hideLoading()
            if (res.statusCode !== 200) {
                if (force) uni.showToast({ title: '更新失败，请重试', icon: 'none' })
                return
            }
            plus.runtime.install(res.tempFilePath, { force: false }, () => {
                plus.runtime.restart()   // 安装完成重启生效
            }, (err) => {
                console.warn('[App] 安装失败', err)
                if (force) uni.showToast({ title: '安装失败，请重试', icon: 'none' })
            })
        },
        fail: () => {
            uni.hideLoading()
            if (force) uni.showToast({ title: '下载失败，请检查网络', icon: 'none' })
        },
    })
}
//#endif
```

## 4.3 关键 API 说明

| API | 说明 |
|-----|------|
| `plus.runtime.version` | 当前 App 的 versionCode（数字，与 manifest 对应） |
| `uni.downloadFile` | 下载 wgt 到临时目录，返回 `tempFilePath` |
| `plus.runtime.install(path, options, success, error)` | 安装 wgt 资源包；`force` 传 false（不强制覆盖，版本号低会拒绝） |
| `plus.runtime.restart()` | 重启 App，新资源生效 |
| `appId` | `__UNI__32EDE25`（manifest 已配置） |

## 4.4 补充建议

1. **检测时机**：`onLaunch` + App 从后台回前台（`onShow`，限 App 端）各一次；或低频（每日首次）
2. **强制更新拦截**：`forceUpdate=true` 时弹窗 `showCancel:false`，且可再加「应用内路由守卫」——未升级则反复弹（可选深化）
3. **网络依赖**：检测接口走后端 8082（Nginx 反代 `/api/` 已有），下载走 9191 静态代理
4. **MD5 校验（可选增强）**：下载完成后比对 `latest.md5`，不一致提示重新下载，防文件损坏
5. **iOS 说明**：功能一致，但若后续 App Store 审核被拒，iOS 侧降级为商店整包更新（仅改前端判断逻辑）

## 4.5 验收标准

- [ ] 安卓 App `1.0.0` 在服务器录入 `101` 版本后，冷启动弹出更新提示
- [ ] 点击「立即更新」→ 下载进度 → 安装完成自动重启 → `versionCode` 变为 `101`
- [ ] 强制更新场景：`showCancel=false`，取消按钮不可见
- [ ] 无更新场景：启动无弹窗，不影响正常使用
- [ ] iOS 同安卓流程验证（或不开启强制）
- [ ] 断网/接口失败：静默跳过，不白屏不崩溃
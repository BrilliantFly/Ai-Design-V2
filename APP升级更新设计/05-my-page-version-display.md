# 05 - 「我的」页面版本显示 + 更新提示设计

> 目标页面：`pages/user/user.vue`（tabBar 第 5 个 tab「我的」）
> 相关组件：`components/widgets/my-service.vue`（设置与支持菜单组，「关于我们」行）
> 联动页面：`pages/user_set/user_set.vue`（设置页「关于我们」行，现已显示 `appStore.config.version`）

## 5.1 现状与问题

| 位置 | 现状 | 问题 |
|------|------|------|
| 我的 → 关于我们 菜单项 | `ITEM_CONFIG['关于我们'].desc` **硬编码** `'版本 v2.4.0 · 检查更新'` | ① 版本号写死不随发布更新 ② 与真实版本（1.0.0 / versionCode 100）不符 ③ 「检查更新」无实际动作，仅文案 |
| 设置 → 关于我们 | `appStore.config.version`（后台配置拉取） | 配置静态值，非真实包版本；更新提示缺失 |

**结论**：需要在「我的」页展示**真实包版本**（`plus.runtime.version`），并在检测到新版本时给出**可见的更新提示**（badge + 点击弹窗，触发下载安装）。

## 5.2 设计目标

1. 「关于我们」行右侧（或 desc 文案）显示当前包版本号：`v1.0.0`（真实 manifest 版本，非硬编码/后台配置）
2. 检测到新版本时，该行显示红色角标/「有新版本」提示文字，**用户进入「我的」即可感知**
3. 点击该行：有新版本 → 弹更新确认框（走 04 文档下载安装流程）；无新版本 → 进入 `/pages/as_us/as_us`（关于我们页）
4. 检测动作：**进入「我的」页时**主动调一次 `/api/system/app/version/latest`，结果缓存到内存/本地，实时驱动 UI
5. 失败静默：接口异常不阻塞页面，只是不显示提示

## 5.3 UI 说明（我的页 关于我们 行）

```
┌─────────────────────────────────────────────┐
│ ℹ️ 关于我们                       v1.0.0  ›  │   ← 无更新：右侧显示当前版本
│   喵百科 · 点击查看版本信息与更新             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ ℹ️ 关于我们              [新版本 v1.0.1] ›   │   ← 有更新：右侧版本替换为绿色
│   喵百科 · 发现新版本，点击立即更新           │      badge + 主色文案，箭头上方
└─────────────────────────────────────────────┘     红点（可选）
```

- **无更新**：右侧灰色小字 `v1.0.0`，desc 显示 `喵百科 · 点击查看版本信息与更新`
- **有更新**：右侧主色（`var(--color-primary)`）小字 `新版本 v1.0.1`，desc 显示 `发现新版本，点击立即更新`；可选在行尾加红色圆点（延续现有 u-icon/arrow 布局，用 24rpx 红点绝对定位）
- `forceUpdate=true` 时文案强化：`重要更新 · 请升级至 v1.0.1`（红字）

## 5.4 数据流

```
pages/user/user.vue (onShow)
   │
   ├─ 1. 调 useAppVersion().check()      // 新 hook
   │       └─ GET /api/system/app/version/latest?platform=&versionCode=
   │             ├─ hasUpdate=true  → store 内存态: { hasUpdate, latest }
   │             └─ hasUpdate=false → 清空
   │
   └─ 2. 传 props 给 w-my-service（或组件内直接 useAppVersion()）
           └─ 渲染 关于我们 行：
                 当前版本 = plus.runtime.version（真实包版本）
                 更新提示 = store.hasUpdate ? badge : 无
                 点击行为 = hasUpdate ? 弹更新框 : 跳 about 页
```

组件内直接复用 hook 更简单（避免层层传 props）：`my-service.vue` 内 `useAppVersion()`，`onMounted/onShow` 时 check。

## 5.5 代码落位（实现阶段参考）

```
know-uniapp/src/
├── hooks/
│   └── useAppVersion.ts          # ★ 新增：版本检测共享 hook
├── components/widgets/
│   └── my-service/my-service.vue # 改：关于我们 行渲染真实版本 + 更新 badge + 点击分流
├── stores/
│   └── appVersion.ts             # ★ 新增(pinia)：{ hasUpdate, latest, forceUpdate, checking }
└── api/
    └── system.ts                 # + checkAppVersion(platform, versionCode)
```

### useAppVersion.ts 核心逻辑

```ts
// 获取真实当前版本（App 端用 plus.runtime，非 manifest 编译常量保证打包即准）
export function getCurrentVersion(): { name: string; code: number } {
    //#ifdef APP-PLUS
    return { name: plus.runtime.versionName || '1.0.0', code: Number(plus.runtime.version || 100) }
    //#endif
    //#ifndef APP-PLUS
    return { name: '1.0.0', code: 100 }   // H5/小程序兜底（不展示更新入口）
    //#endif
}

// 检测并在 store 记录结果
export function useAppVersion() {
    const store = useAppVersionStore()
    const check = async () => {
        const { code } = getCurrentVersion()
        const platform = uni.getSystemInfoSync().platform === 'ios' ? 'ios' : 'android'
        const res = await checkAppVersion({ platform, versionCode: code }).catch(() => null)
        store.set(res?.data)   // res.data: { hasUpdate, forceUpdate, latest }
    }
    return { check, hasUpdate: computed(() => store.hasUpdate), latest: computed(() => store.latest) }
}
```

### my-service.vue 改动点

1. `ITEM_CONFIG['关于我们']` 的 desc 改为动态：`computed`（`hasUpdate ? '发现新版本，点击立即更新' : '喵百科 · 点击查看版本信息与更新'`）
2. menu-item 渲染处：关于我们行右侧内容替换为
   - 无更新：`<view class="text-muted mr-[12rpx]">{{ currentVersion.name }}</view>`
   - 有更新：`<view class="text-primary mr-[12rpx] font-medium">新版本 {{ latest.versionName }}</view>` + 红点
3. `handleClick` 分支：`item.name === '关于我们'` → `hasUpdate ? showUpdateModal() : openLink('/pages/as_us/as_us')`
4. `showUpdateModal` 弹窗（`uni.showModal`）→ 确认后调用 04 文档的 `downloadAndInstall(latest.downloadUrl, latest.forceUpdate)` —— **将 04 的下载安装逻辑抽为独立工具** `utils/app-update.ts` 供 hook 与弹窗共用
5. `onShow`（页面可见）时调 `check()`，避免重复请求：`checking` 中跳过，结果 10 分钟内不重查（时间戳缓存，退出 App 后重置）

### user_set.vue 改动点（可选同步）

「关于我们」行右侧的 `appStore.config.version` 替换为 `getCurrentVersion().name`（真实版本），并同样接入 `hasUpdate` 红点 + 点击分流（复用同一 hook）。

## 5.6 验收标准

- [ ] 未登录也能看到「关于我们」行版本显示（检测接口免登录；无更新时不强制登录）
- [ ] 「我的」页显示 `v1.0.0`，与 `plus.runtime.versionName` 一致（非硬编码、非后台配置）
- [ ] 服务器录入 101 版本后，进入「我的」页出现 `新版本 v1.0.1` 提示 + 红点
- [ ] 点击该行弹出更新确认 → 确认后下载安装 → 重启后版本号变 `v1.0.1`，提示消失
- [ ] 无更新时点击该行跳转 `/pages/as_us/as_us`（关于我们页）
- [ ] 断网/接口失败：版本号照常显示，无更新提示、不阻塞页面
- [ ] 重复进入「我的」页不重复弹更新框（hasUpdate 已为 true 则不弹，仅保留 badge）
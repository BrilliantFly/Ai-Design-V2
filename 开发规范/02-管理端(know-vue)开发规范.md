# 管理端（know-vue）开发规范

> 项目路径：`E:\Ai-Project\Ai-Front\know-vue`  
> 技术栈：Vue 3 + TypeScript + Vite + ant-design-vue 4.x + Pinia + vue-router 4  
> 版本基线：依据实际代码库（`package.json`）梳理，不做臆测  
> 原则：**每一条规范必须有真实文件路径及简短代码片段佐证**，如存在不一致处须在文中标注「不一致」。

## 1. 技术栈与工程结构

### 1.1 核心依赖（package.json）

**真实文件**：[`src/../package.json`](../../Ai-Front/know-vue/package.json#L21-L58)

```json
{
  "type": "module",
  "scripts": {
    "serve": "vite",
    "build": "rimraf dist && vue-tsc --noEmit && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.6",
    "vue-router": "^4.2.5",
    "pinia": "^2.1.7",
    "pinia-plugin-persistedstate": "^3.2.1",
    "ant-design-vue": "^4.2.5",
    "@ant-design/icons-vue": "^7.0.1",
    "axios": "^1.6.5",
    "vue-i18n": "^9.9.0"
  },
  "devDependencies": {
    "typescript": "^5.3.3",
    "vite": "^5.4.10",
    "@vitejs/plugin-vue": "^5.0.2",
    "@vitejs/plugin-vue-jsx": "^3.1.0",
    "less": "^4.2.0",
    "unplugin-vue-components": "^0.27.4",
    "vite-plugin-svg-icons": "^2.0.1",
    "vite-plugin-mock": "2.9.8"
  }
}
```

**结论**：Vue 3（Composition API 优先）、TS、Vite 5、AntDV 4、Pinia（含持久化）、Vue Router 4。

### 1.2 Vite 配置

**真实文件**：[`vite.config.ts`](../../Ai-Front/know-vue/vite.config.ts)

- 别名：`@/` → `src/`（[`vite.config.ts#L83-L90`](../../Ai-Front/know-vue/vite.config.ts#L83-L90)）
- base：`./`（[`vite.config.ts#L46`](../../Ai-Front/know-vue/vite.config.ts#L46)）
- 代理：按 `.env` 的 `VITE_PROXY` + `VITE_API_MODE` 转换（[`vite.config.ts#L26-L44`](../../Ai-Front/know-vue/vite.config.ts#L26-L44)），代理构建函数 `createProxy` 位于 [`build/vite/proxy.ts`](../../Ai-Front/know-vue/build/vite/proxy.ts)
- 构建：`terser` 压缩、`drop_console` 受 `VITE_DROP_CONSOLE` 控制、`chunkSizeWarningLimit: 2000`、`target: es2015`（[`vite.config.ts#L59-L71`](../../Ai-Front/know-vue/vite.config.ts#L59-L71)）
- Less 全局变量：注入 `@import "${resolve('src/design/variable/index.less')}";`（[`vite.config.ts#L77`](../../Ai-Front/know-vue/vite.config.ts#L77)）

### 1.3 入口与全局配置

**真实文件**：
- [`index.html`](../../Ai-Front/know-vue/index.html#L1-L13)：`id="htmlRoot"`、`%VITE_APP_NAME%`、`/src/main.ts`
- [`src/main.ts`](../../Ai-Front/know-vue/src/main.ts)：注册 `virtual:svg-icons-register`、`setupStore`、`initAppConfigStore`、`setupRouter` + `setupRouterGuard`、`setupI18n`、`setupPlugins`、挂载 `#app`。关键：路由懒加载 Chunk 404 自动刷新机制（见 3.6 节）
- [`src/App.tsx`](../../Ai-Front/know-vue/src/App.tsx#L1-L41)：AntDV `ConfigProvider`（中文 `zhCN`）、`theme.token.colorPrimary` 绑定 `useBaseSetting().getThemeColor`、`algorithm` 绑定暗黑模式、`useTitle()`

### 1.4 环境变量

**真实文件**：
- [`.env`](../../Ai-Front/know-vue/.env)：`VITE_APP_NAME=喵百科`
- [`.env.development`](../../Ai-Front/know-vue/.env.development)：`VITE_PORT=5173`、`VITE_PROXY=[["/api","http://localhost:8082"]]`、`VITE_API_MODE=standalone`、`VITE_DROP_CONSOLE=false`

### 1.5 TypeScript

**真实文件**：[`tsconfig.json`](../../Ai-Front/know-vue/tsconfig.json)
- `moduleResolution: "node"`、`jsx: "preserve"`、`paths`: `@/* -> src/*`、`#/* -> types/*`（[`tsconfig.json#L26-L29`](../../Ai-Front/know-vue/tsconfig.json#L26-L29)）
- `strict: true`，但 `noImplicitAny: false`、`strictFunctionTypes: false`（[`tsconfig.json#L6-L11`](../../Ai-Front/know-vue/tsconfig.json#L6-L11)）
- 包含 `src/**/*.ts,tsx,vue`、`typings/**/*.ts,d.ts`、`build/**/*.ts,d.ts`、`mock/*.ts`、`vite.config.ts`（[`tsconfig.json#L35-L46`](../../Ai-Front/know-vue/tsconfig.json#L35-L46)）

## 2. 目录规范（src 下）

**真实目录**：[`src/`](../../Ai-Front/know-vue/src)（按实际列出）：

| 目录 | 用途 | 典型参考 |
|---|---|---|
| `api/` | 接口层（按业务域组织，含 `index.ts` 聚合） | [`api/system/`](../../Ai-Front/know-vue/src/api/system)、[`api/biz/`](../../Ai-Front/know-vue/src/api/biz)、[`api/knowledge/`](../../Ai-Front/know-vue/src/api/knowledge)、[`api/index.ts`](../../Ai-Front/know-vue/src/api/index.ts) |
| `assets/` | 静态资源（图标/图片） | [`src/assets/`](../../Ai-Front/know-vue/src/assets) |
| `components/` | 全局/通用组件 | [`components/BizFullscreenModal.vue`](../../Ai-Front/know-vue/src/components/BizFullscreenModal.vue)、[`components/`](../../Ai-Front/know-vue/src/components) |
| `design/` | 样式主题（Less、变量、暗黑、插件样式） | [`design/index.less`](../../Ai-Front/know-vue/src/design/index.less)、[`design/variable/`](../../Ai-Front/know-vue/src/design/variable) |
| `directives/` | 自定义指令（`permission`、`clickOutside`、`infiniteScroll`） | [`directives/permission.ts`](../../Ai-Front/know-vue/src/directives/permission.ts) |
| `enums/` | 枚举常量 | [`enums/appEnum.ts`](../../Ai-Front/know-vue/src/enums/appEnum.ts)、[`enums/cacheEnum.ts`](../../Ai-Front/know-vue/src/enums/cacheEnum.ts) |
| `hooks/` | 组合式函数（`web/setting/core/event`） | [`hooks/web/useTitle.ts`](../../Ai-Front/know-vue/src/hooks/web/useTitle.ts)、[`hooks/index.ts`](../../Ai-Front/know-vue/src/hooks/index.ts) |
| `layout/` | 布局（侧边栏/头部/标签页/内容） | [`layout/index.tsx`](../../Ai-Front/know-vue/src/layout/index.tsx)、[`layout/menu/`](../../Ai-Front/know-vue/src/layout/menu) |
| `locales/` | 国际化（`langs/*` + `helper.ts` + `index.ts`） | [`locales/index.ts`](../../Ai-Front/know-vue/src/locales/index.ts)、[`locales/helper.ts`](../../Ai-Front/know-vue/src/locales/helper.ts) |
| `logics/` | 业务逻辑（主题、mitt、App 配置初始化） | [`logics/initAppConfig.ts`](../../Ai-Front/know-vue/src/logics/initAppConfig.ts)、[`logics/theme/`](../../Ai-Front/know-vue/src/logics/theme) |
| `plugins/` | 插件注册（按模块动态导入） | [`plugins/index.ts`](../../Ai-Front/know-vue/src/plugins/index.ts)、[`plugins/modules/`](../../Ai-Front/know-vue/src/plugins/modules) |
| `router/` | 路由（routes/modules、guard、helper、menus） | 见第 3 节 |
| `settings/` | 全局配置（`appBaseSetting.ts`、设计/国际化/加密等） | [`settings/appBaseSetting.ts`](../../Ai-Front/know-vue/src/settings/appBaseSetting.ts) |
| `stores/` | Pinia Store（modules + plugin 持久化） | [`stores/index.ts`](../../Ai-Front/know-vue/src/stores/index.ts)、[`stores/modules/permission.ts`](../../Ai-Front/know-vue/src/stores/modules/permission.ts) |
| `types/` | TypeScript 类型定义 | [`types/index.ts`](../../Ai-Front/know-vue/src/types/index.ts)、[`types/config.ts`](../../Ai-Front/know-vue/src/types/config.ts) |
| `utils/` | 工具函数（axios、auth、cache、helper、cascadeDict 等） | [`utils/axios/index.ts`](../../Ai-Front/know-vue/src/utils/axios/index.ts)、[`utils/auth/index.ts`](../../Ai-Front/know-vue/src/utils/auth/index.ts) |
| `views/` | 页面视图（按业务域：`biz/`、`knowledge/`、`system/` 等） | [`views/biz/customer/`](../../Ai-Front/know-vue/src/views/biz/customer)、[`views/knowledge/`](../../Ai-Front/know-vue/src/views/knowledge) |
| `App.tsx` | 根组件（JSX） | [`App.tsx`](../../Ai-Front/know-vue/src/App.tsx) |
| `main.ts` | 应用入口 | [`main.ts`](../../Ai-Front/know-vue/src/main.ts) |

**约定**：业务页面按域划分（`biz/`、`knowledge/`、`system/`、`plan/`、`camera/` 等），通用组件放 `components/`，业务域内的复用组件可放在对应 `views/**/components/`（如 [`views/biz/components/`](../../Ai-Front/know-vue/src/views/biz/components)）。

## 3. 路由规范

### 3.1 路由类型定义

**真实文件**：[`src/router/types.ts`](../../Ai-Front/know-vue/src/router/types.ts)

```ts
export interface AppRoute extends Omit<RouteRecordRaw, 'children'> {
  name: string
  meta: RouteMeta
  component?: Component | string
  children?: AppRoute[]
  props?: Recordable
  fullPath?: string
}
```

```ts
export interface AppMenu {
  name: string
  path: string
  children?: AppMenu[]
  meta?: Partial<RouteMeta>
  icon?: string
  affix?: boolean
  orderNo?: number
  ignoreKeepAlive?: boolean
  hideMenu?: boolean
  hideChildrenInMenu?: boolean
}
```

**结论**：自定义 `AppRoute` 强制要求 `name` 和 `meta`，组件类型支持 `defineComponent` 返回值或 `() => Promise<import('*.vue')>` 懒加载。

### 3.2 路由模块定义（按业务拆分）

**路由注册入口**：[`src/router/routes/index.ts`](../../Ai-Front/know-vue/src/router/routes/index.ts#L99-L113)

```ts
const routeModules = import.meta.glob('./modules/*.ts', { eager: true }) as Object
// ...
Object.keys(routeModules).forEach(key => {
  const module = routeModules[key].default || {}
  const moduleList = Array.isArray(module) ? [...module] : [module]
  routeModulesList.push(...moduleList)
})
export const asyncRoutes = [PageNotFoundRoute, RedirectRoute, ...routeModulesList]
export const basicRoutes = [LoginRoute, RootRoute, RedirectRoute, NotAuthRoute, ...routeModulesList]
```

**模块示例**：[`modules/biz.ts`](../../Ai-Front/know-vue/src/router/routes/modules/biz.ts#L5-L81)

```ts
const BizCustomerRoute: AppRoute = {
  path: '/biz/customer',
  name: 'BizCustomer',
  component: Layout,
  redirect: '/biz/customer/list',
  meta: { title: '客户管理', icon: 'user', orderNo: 7 },
  children: [
    { path: 'list', name: 'BizCustomerList', component: () => import('@/views/biz/customer/list/index.vue'), meta: { title: '客户列表' } },
    { path: 'followup', name: 'BizCustomerFollowup', component: () => import('@/views/biz/customer/followup/index.vue'), meta: { title: '跟进记录' } }
  ]
}
export default [BizCustomerRoute, BizIndustryRoute]
```

**模块示例（单路由导出对象）**：[`modules/knowledge.ts`](../../Ai-Front/know-vue/src/router/routes/modules/knowledge.ts#L4-L58) `export default KnowledgeRoute`

**Home 示例**：[`modules/home.ts`](../../Ai-Front/know-vue/src/router/routes/modules/home.ts#L6-L32) 使用 `Layout` + `redirect` + 空路径子路由，`hideChildrenInMenu: true`、`affix: true`、`orderNo: 1`

**基础路由**：`RootRoute`（`/` → `/home`）、`LoginRoute`（`/login` 懒加载）、`PageNotFoundRoute`（`/:path(.*)*`、`component: Layout` + 子路由指向 `@/views/redirect`）、`RedirectRoute`（`/redirect/:path(.*)/:_redirect_type(.*)/:_origin_params(.*)?` → `@/views/redirect`）、`NotAuthRoute`（`/403` 指向异常页）

**推荐模板（路由模块）**：

```ts
import type { AppRoute } from '../../types'
import Layout from '@/layout'

const DemoRoute: AppRoute = {
  path: '/demo',
  name: 'Demo',
  component: Layout,
  redirect: '/demo/list',
  meta: {
    title: '示例管理',
    icon: 'appstore',
    orderNo: 10
  },
  children: [
    {
      path: 'list',
      name: 'DemoList',
      component: () => import('@/views/demo/list/index.vue'),
      meta: { title: '示例列表' }
    }
  ]
}

export default DemoRoute
```

### 3.3 路由守卫

**守卫装配**：[`src/router/guard/index.ts`](../../Ai-Front/know-vue/src/router/guard/index.ts#L8-L46)
- `createPageGuard(router)`：记录 `loadedPageMap`（`to.meta.loaded = !!loadedPageMap.get(to.path)`），`afterEach` 设置标记，`beforeEach` 调用 `setRouteChange(to)`（[`logics/mitt/routeChange`](../../Ai-Front/know-vue/src/logics/mitt/routeChange)）
- `createProgressGuard(router)`：基于 `useTransitionSetting().getOpenNProgress` 控制 `nProgress.start/done`（仅未加载过的页面）
- `createPermissionGuard(router)`：核心权限守卫

**权限守卫**：[`src/router/guard/permissionGuard.ts`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts)

关键逻辑（基于实际代码）：
- 白名单：`['/login']`（[`L8`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L8)）
- Token 获取：`const token = userStore.getToken`（优先 store getter，实际 getter 从 `getAuthCache(TOKEN_KEY)` 读取，见 [`stores/modules/user.ts#L31-L35`](../../Ai-Front/know-vue/src/stores/modules/user.ts#L31-L35)）
- 白名单内：若访问 `/login` 且有 token，尝试 `await userStore.afterLoginAction()`，非超时则 `next(redirect || '/')`（[`L22-L35`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L22-L35)）
- 无 token：`ignoreAuth` 元信息放行，否则重定向到 `/login` 并附带 `redirect` 查询参数（[`L37-L60`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L37-L60)）
- 登录后跳转 404 特殊处理：`from.path === '/login' && to.name === PageNotFoundRoute.name && to.fullPath !== (userStore.userInfo?.homePath || '/home')` 时跳转首页（[`L63-L70`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L63-L70)）
- 用户信息懒加载：`userStore.lastUpdateTime === 0` 时 `await userStore.getUserInfoAction()`（[`L73-L82`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L73-L82)）
- **构建路由**：`const routes = await permissionStore.buildRoutesAction()`，遍历 `router.addRoute(route)`，最后 `router.addRoute(PageNotFoundRoute)`，完成后若目标是 404 名称则 `next({ path: to.fullPath, replace: true, query: to.query })` 否则 `next()`（[`L84-L99`](../../Ai-Front/know-vue/src/router/guard/permissionGuard.ts#L84-L99)）

**注**：守卫内有 `console.log`（调试痕迹），属于实际现状（不强制清理，按规范建议生产环境去除，但本文记录现状）。

### 3.4 权限 Store 与菜单构建

**真实文件**：[`src/stores/modules/permission.ts`](../../Ai-Front/know-vue/src/stores/modules/permission.ts)

```ts
if (permissionMode === PermissionModeEnum.MAPPING) {
  routes = asyncRoutes
  // 优先从数据库动态获取菜单（sys_menu），失败时降级为静态菜单
  let menuList: AppMenu[] = []
  try {
    const res = await getMenuList({})
    if (res && res.code === 1 && Array.isArray(res.data)) {
      menuList = transformSysMenusToMenus(res.data)
    } else {
      console.warn('[permission] 动态菜单接口异常:', res?.msg || res)
    }
  } catch (e) {
    console.warn('[permission] 动态菜单获取失败，降级为静态菜单:', e)
  }
  if (!menuList.length) {
    menuList = transformRouteToMenu(routes)
  }
  menuList.sort((a,b)=>(a?.orderNo||menuList.length)-(b?.orderNo||menuList.length))
  this.setMenuList(menuList)
}
return routes
```

**结论**：
- 权限模式：`PermissionModeEnum.MAPPING`（[`appBaseSetting.ts#L63`](../../Ai-Front/know-vue/src/settings/appBaseSetting.ts#L63)）
- 路由注册来源：`asyncRoutes`（包含 `PageNotFoundRoute`、`RedirectRoute`、所有模块路由）
- 菜单数据来源：**优先后端动态菜单** `GET /system/menu/list`（[`api/system/menu.ts#L29-L36`](../../Ai-Front/know-vue/src/api/system/menu.ts#L29-L36)）→ 转换为 `AppMenu[]`（[`router/helper/sysMenuHelper.ts`](../../Ai-Front/know-vue/src/router/helper/sysMenuHelper.ts)）；失败或空列表时**降级为静态路由** `transformRouteToMenu(routes)`（[`router/helper/menuHelper.ts`](../../Ai-Front/know-vue/src/router/helper/menuHelper.ts)）

### 3.5 动态菜单转换（后端驱动侧边栏）

**后端菜单结构**：[`sysMenuHelper.ts#L6-L21`](../../Ai-Front/know-vue/src/router/helper/sysMenuHelper.ts#L6-L21)

```ts
export interface SysMenu {
  id: number; parentId: number; menuName: string; path: string; component: string | null;
  perms: string | null; icon: string | null; menuType: number; /* 1=目录 2=菜单 3=按钮 */
  sort: number; status: number; /* 1=显示 0=隐藏 */ tenantId: number | null; delFlag: number;
}
```

**转换规则**（[`transformSysMenusToMenus`](../../Ai-Front/know-vue/src/router/helper/sysMenuHelper.ts#L30-L98)）：
- 过滤：`status === 1 && menuType !== 3 && delFlag === 0`（按钮不渲染到侧边栏）
- 映射字段：`menuName → name/title`、`path`（空则 `/menu-${id}`）、`icon`、`sort → orderNo`、写入 `meta.title/icon/orderNo`
- 树形组装：`parentId === 0` 顶级，否则挂载到父节点；父节点不存在时**提升为顶级**（避免丢失）
- 排序：递归按 `orderNo` 升序
- 清理：`children` 为空数组时删除

**静态路由转菜单**：[`menuHelper.ts`](../../Ai-Front/know-vue/src/router/helper/menuHelper.ts)
- `transformRouteToMenu`：深拷贝路由，处理 `hideChildrenInMenu && redirect` 时将 `path = item.redirect`，再用 `treeMap` 转换（提取 `meta.title/hideMenu/...`，映射 `name = title`），最后 `joinParentPath` 处理相对路径（非 `/` 且非 URL 时拼接父路径）

### 3.6 路由懒加载 Chunk 404 自动刷新机制（部署缓存问题）

**文件**：[`src/main.ts#L16-L40`](../../Ai-Front/know-vue/src/main.ts#L16-L40)

```ts
const CHUNK_RELOAD_KEY = '__know_chunk_reload__'
function reloadForMissingChunk() {
  try {
    const last = Number(sessionStorage.getItem(CHUNK_RELOAD_KEY) || 0)
    if (Date.now() - last < 10000) return  // 10秒内只刷新一次
    sessionStorage.setItem(CHUNK_RELOAD_KEY, String(Date.now()))
  } catch {}
  window.location.reload()
}
// Vite 动态 import/modulepreload 失败
window.addEventListener('vite:preloadError', (event: Event) => {
  event.preventDefault()
  reloadForMissingChunk()
})
// 路由组件 import 失败兜底
router.onError(error => {
  const msg = String((error as Error)?.message || error || '')
  if (/dynamically imported module|Loading chunk|Importing a module script failed/i.test(msg)) {
    reloadForMissingChunk()
  }
})
```

**经验说明**：构建产物按内容哈希拆分 chunk。若某次发布替换了静态资源，而浏览器标签页仍停留在旧版本，则懒加载的路由 chunk 会请求已不存在的旧文件而 404。Vue Router 会中断导航，表现为「只切换了 tab 页签，内容区空白」。此处捕获错误并在 10 秒内最多自动刷新一次，加载最新资源后恢复。

## 4. API 层规范

### 4.1 Axios 封装

**真实文件**：[`src/utils/axios/index.ts`](../../Ai-Front/know-vue/src/utils/axios/index.ts)

```ts
const isProduction = import.meta.env.PROD
const serviceConfig = {
  baseURL: isProduction ? (import.meta.env.VITE_API_BASE_URL || '') : '',
  serviceMap: { java: '', python: '/python' },
  timeout: 10 * 1000
}
const service = axios.create({ baseURL: serviceConfig.baseURL, timeout: serviceConfig.timeout })
```

**请求拦截器**（[`L43-L61`](../../Ai-Front/know-vue/src/utils/axios/index.ts#L43-L61)）：
- Token：优先 `localStorage.getItem('token')`，否则 `getToken()`（[`utils/auth/index.ts#L8-L10`](../../Ai-Front/know-vue/src/utils/auth/index.ts#L8-L10) 基于 `Persistent.getLocal/getSession` 按 `permissionCacheType` 选择）
- Header：`token: ${token}`（注意：key 是 `token`，不是 `Authorization`）
- 租户：`X-Tenant-Id` 从 `getAuthCache(TENANT_KEY)`（[`enums/cacheEnum.ts#L9`](../../Ai-Front/know-vue/src/enums/cacheEnum.ts#L9)：`TENANT_KEY='TENANT_INFO'`）
- `Content-Type: application/json`

**响应拦截器**（[`L64-L78`](../../Ai-Front/know-vue/src/utils/axios/index.ts#L64-L78)）：
- 业务成功码判定：`data.code === 0 || data.code === 1 || data.code === 2 || data.code === 200`（**不一致点**：同时接受 0/1/2/200，属于实际项目的容错处理）
- 成功：直接返回 `data`（响应体整体），调用方通常取 `res.data` 或 `res`
- 失败：`message.error(data.msg || data.message || '操作失败')`，`return Promise.reject('error')`
- 错误处理（`handleError`）：`status === 401 || 504` 时 `clearAuthCache()` 并 `router.push({ path: '/login' })`，其他统一 `message.error(error.message || 'error')`

**结论**：API 调用约定是**返回整个响应对象**（`{code,msg,data,...}`），调用方需按业务取 `res.data`。这是项目中多处（如 [`stores/modules/user.ts#L73-L76`](../../Ai-Front/know-vue/src/stores/modules/user.ts#L73-L76)、[`views/system/user.vue#L297-L301`](../../Ai-Front/know-vue/src/views/system/user.vue#L297-L301)）实际用法的依据。

### 4.2 API 目录组织与写法

**组织方式**：按业务域拆分，`src/api/**`，根目录 [`api/index.ts`](../../Ai-Front/know-vue/src/api/index.ts) 聚合通用接口（登录/登出/用户信息/示例表格）。

**典型示例**：
- 系统：[`api/system/menu.ts`](../../Ai-Front/know-vue/src/api/system/menu.ts)（CRUD + 树形）、[`api/system/cascadeDict.ts`](../../Ai-Front/know-vue/src/api/system/cascadeDict.ts)（类型+数据，含便捷方法 `getIndustryTypeTree()`、`getPlanTypeTree()`）
- 业务：[`api/biz/customer.ts`](../../Ai-Front/know-vue/src/api/biz/customer.ts)（分页/详情/增删改/状态/行业关联/统计，接口路径包含 `/api/biz/...`）
- 知识库：[`api/knowledge/index.ts`](../../Ai-Front/know-vue/src/api/knowledge/index.ts)（大模块聚合导出，包含文件上传 `multipart/form-data`）

**推荐模板（API 模块，RESTful 风格）**：

```ts
import { service } from '@/utils/axios'

export interface DemoQuery extends Pagination {
  name?: string
  status?: number
}

export interface DemoItem {
  id?: number
  name?: string
  status?: number
  createTime?: string
}

export function getDemoPage(params: DemoQuery): Promise<any> {
  return service({
    url: '/api/demo/page',
    method: 'get',
    params
  })
}

export function getDemo(id: number): Promise<any> {
  return service({
    url: `/api/demo/${id}`,
    method: 'get'
  })
}

export function addDemo(data: DemoItem): Promise<any> {
  return service({
    url: '/api/demo',
    method: 'post',
    data
  })
}

export function updateDemo(data: DemoItem): Promise<any> {
  return service({
    url: '/api/demo',
    method: 'put',
    data
  })
}

export function deleteDemo(id: number): Promise<any> {
  return service({
    url: `/api/demo/${id}`,
    method: 'delete'
  })
}
```

**注意**：部分接口使用 `/api/...` 前缀（biz/customer、knowledge），系统接口使用 `/system/...`（menu/list）——这是与代理/后端映射实际情况一致（见 [`build/vite/proxy.ts`](../../Ai-Front/know-vue/build/vite/proxy.ts) 对 `/system`、`/api`、`/adminapi/*` 的重写规则）。

## 5. 视图开发规范（CRUD 页面模式）

项目中大量采用**字段配置驱动（sections + MatrixTable + FieldItem）**的 CRUD 模式，典型样例：[`views/biz/customer/list/index.vue`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue)、[`views/biz/industry/list/index.vue`](../../Ai-Front/know-vue/src/views/biz/industry/list/index.vue)。

### 5.1 CRUD 列表页通用骨架

**推荐模板（列表页）**：

```vue
<template>
  <div>
    <a-card title="示例管理" :bordered="false">
      <template #extra>
        <a-button type="primary" @click="handleAdd">
          <template #icon><plus-outlined /></template>
          新增
        </a-button>
      </template>

      <!-- 搜索区 -->
      <a-form layout="inline" :model="queryParams" class="mb-4">
        <a-form-item label="名称">
          <a-input v-model:value="queryParams.name" placeholder="请输入名称" allow-clear style="width: 160px" />
        </a-form-item>
        <a-form-item label="状态">
          <a-select v-model:value="queryParams.status" placeholder="全部" allow-clear style="width: 120px">
            <a-select-option :value="1">启用</a-select-option>
            <a-select-option :value="0">禁用</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item>
          <a-button type="primary" @click="handleQuery">
            <template #icon><search-outlined /></template>
            查询
          </a-button>
          <a-button style="margin-left: 8px" @click="handleReset">
            <template #icon><redo-outlined /></template>
            重置
          </a-button>
        </a-form-item>
      </a-form>

      <!-- 表格 -->
      <a-table
        :data-source="list"
        :columns="columns"
        :loading="loading"
        :pagination="pagination"
        :row-key="(record: any) => record.id!"
        @change="handleTableChange"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'action'">
            <a-space style="white-space: nowrap">
              <a @click="handleEdit(record)">编辑</a>
              <a-divider type="vertical" />
              <a-popconfirm title="确定删除吗？" @confirm="handleDelete(record)">
                <a style="color: red">删除</a>
              </a-popconfirm>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <!-- 新增/编辑 -->
    <BizFullscreenModal v-model:open="modalVisible" :title="modalTitle" :confirm-loading="confirmLoading" @ok="handleSubmit" @cancel="handleCancel">
      <a-form ref="formRef" :model="formData" :rules="rules" layout="vertical">
        <!-- 字段配置驱动：也可直接写表单项 -->
      </a-form>
    </BizFullscreenModal>

    <!-- 详情 -->
    <BizFullscreenModal v-model:open="detailVisible" :title="detailTitle" :footer="null" scrolling>
      <!-- 详情渲染 -->
    </BizFullscreenModal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import type { PaginationProps, FormInstance } from 'ant-design-vue'
import { PlusOutlined, SearchOutlined, RedoOutlined } from '@ant-design/icons-vue'
import BizFullscreenModal from '@/components/BizFullscreenModal.vue'

const queryParams = reactive<any>({ name: undefined, status: undefined })
const list = ref<any[]>([])
const loading = ref(false)
const pagination = reactive({ current: 1, pageSize: 10, total: 0, showSizeChanger: true, showTotal: (t:number)=>`共 ${t} 条` })

const modalVisible = ref(false)
const modalTitle = ref('新增')
const confirmLoading = ref(false)
const isEdit = ref(false)
const editId = ref<number>()
const formRef = ref<FormInstance>()
const formData = reactive<any>({})
const rules = reactive<any>({ name: [{ required: true, message: '请输入名称', trigger: 'blur' }] })

async function loadData() { /* 调用 API */ }
function handleQuery(){ pagination.current=1; loadData() }
function handleReset(){ /* 清空 */ pagination.current=1; loadData() }
function handleTableChange(p:PaginationProps){ pagination.current=p.current??1; pagination.pageSize=p.pageSize??10; loadData() }
function handleAdd(){ isEdit.value=false; modalTitle.value='新增'; /* reset */ modalVisible.value=true }
function handleEdit(r:any){ isEdit.value=true; editId.value=r.id; modalTitle.value='编辑'; Object.assign(formData,r); modalVisible.value=true }
async function handleSubmit(){ await formRef.value?.validate(); confirmLoading.value=true; try{/* save */ message.success('保存成功'); modalVisible.value=false; loadData()} finally{confirmLoading.value=false} }
function handleCancel(){ modalVisible.value=false }
async function handleDelete(r:any){ /* delete */ message.success('删除成功'); loadData() }

onMounted(loadData)
</script>

<style scoped>
.mb-4 { margin-bottom: 16px; }
</style>
```

**实践要点（源自实际代码）**：
- 查询参数用 `reactive<BizCustomerQuery>`，分页用 `ant-design-vue` `PaginationProps` 处理
- 编辑时优先拉取**详情接口**回填（避免列表字段不全），如 [`customer/list/index.vue#L532-L607`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L532-L607)：`handleEdit` 打开弹窗后调用 `getCustomerDetail(id)` 回填 `formData`
- 状态切换直接在表格内操作（行内 Select + `updateCustomerStatus`），失败时恢复原值或提示（[`L690-L701`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L690-L701)）
- 详情弹窗也优先用列表数据，打开后再异步拉取详情补全（[`L663-L674`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L663-L674)）
- 多选/逗号分隔字符串的双向转换：提交时 `earningWay`/`socialClass` 数组 → `join(',')`，回填时 `split(',').filter(Boolean)`（[`L619-L624`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L619-L624)、[`L558-L568`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L558-L568)）
- 行业关联：更新客户基本信息后，额外调用 `setCustomerIndustries(id, relations)` 设置多对多关联（[`L628-L636`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L628-L636)）

## 6. 字段配置驱动（sections + FieldItem + MatrixTable）

### 6.1 类型定义

**真实文件**：[`views/biz/components/types.ts`](../../Ai-Front/know-vue/src/views/biz/components/types.ts)

```ts
export interface FieldDef {
  label: string
  key: string  // 支持点路径 company.name / profile.dynamicInfo
  type?: 'input' | 'textarea' | 'select' | 'selectMultiple' | 'number' | 'date' | 'cascader'
  placeholder?: string
  options?: { label: string; value: any; children?: any[] }[]
  span?: number  // 24 整行，默认 12
  rows?: number
  required?: boolean
}
export interface SectionDef {
  title: string
  defaultOpen?: boolean
  fields?: FieldDef[]
  subSections?: SectionDef[]
}
export interface RenderContext {
  model: Record<string, any>
  mode?: 'form' | 'detail'
  optionsMap?: Record<string, { label: string; value: any }[]>
}
```

### 6.2 FieldItem 组件

**真实文件**：[`views/biz/components/FieldItem.vue`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue)

**核心特性**（基于代码注释及实现）：
- 支持 `mode: 'form' | 'detail'`
- **点路径取值/赋值**：`resolvePath`/`setPath` 支持 `company.name`、`profile.dynamicInfo`（[`L94-L118`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L94-L118)）
- **AntDV Form name 适配**：对于包含 `.` 的 key，将 `formFieldName` 转换为数组 `key.split('.')`，避免嵌套字段校验取值失败（[`L84-L88`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L84-L88)）
- **级联（cascader）**：仅回写**末级节点值**（字符串），通过 `findCascaderPath` 反推路径数组用于控件显示，详情模式展示完整路径 `path.map(n=>n.label).join(' / ')`（[`L124-L168`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L124-L168)）
- **多选（selectMultiple）详情展示**：兼容后端逗号分隔字符串存储（[`L179-L189`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L179-L189)）
- **Label 清理**：`stripLabel` 去掉括号内容（[`L91`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L91)）

**支持控件**：`input`、`textarea`、`select`、`selectMultiple`、`number`、`date`、`cascader`（默认 `input`）

### 6.3 MatrixTable 组件（矩阵表渲染）

**真实文件**：[`views/biz/components/MatrixTable.vue`](../../Ai-Front/know-vue/src/views/biz/components/MatrixTable.vue)

**设计要点**：
- 一级区域可折叠（`CaretRightOutlined`，`defaultOpen` 控制初始展开）
- 字段按 `span` 打包：`span >= 24` 独占一块，否则两字段并排（[`L72-L92`](../../Ai-Front/know-vue/src/views/biz/components/MatrixTable.vue#L72-L92)）
- 递归收集路径生成层级表头（最多支持多级子区域），自动计算 `rowspan` 合并单元格，空层级用占位格保持网格对齐（[`L109-L169`](../../Ai-Front/know-vue/src/views/biz/components/MatrixTable.vue#L109-L169)）
- 字段选项优先级：`optionsMap[f.key] || f.options`（动态注入优先）

### 6.4 sections 配置示例

**客户 sections**：[`views/biz/customer/sections.ts`](../../Ai-Front/know-vue/src/views/biz/customer/sections.ts)（多层级嵌套：个人资料 → 基础认识/详细认识 → 子标题 → 字段组）
- 嵌套字段示例：`profile.dynamicInfo`、`profile.valueLevel` 等（点路径）
- 多选示例：`earningWay`、`socialClass` 类型 `selectMultiple`，选项静态定义
- 级联占位：行业相关字段在页面通过 `optionsMap` 动态注入

**行业 sections**：[`views/biz/industry/sections.ts`](../../Ai-Front/know-vue/src/views/biz/industry/sections.ts) 含 `industryType` 类型 `cascader`，配合 [`api/system/cascadeDict.ts#getIndustryTypeTree()`](../../Ai-Front/know-vue/src/api/system/cascadeDict.ts#L130-L132) 注入 `optionsMap.industryType`

**推荐模板（sections.ts）**：

```ts
import type { SectionDef } from '../components/types'

export const demoSections: SectionDef[] = [
  {
    title: '基础信息',
    defaultOpen: true,
    subSections: [
      {
        title: '基本信息',
        fields: [
          { label: '名称', key: 'name', span: 12, required: true },
          { label: '状态', key: 'status', type: 'select', options: [{ label: '启用', value: 1 }, { label: '禁用', value: 0 }], span: 12 },
          { label: '备注', key: 'remark', type: 'textarea', span: 24, rows: 2 }
        ]
      }
    ]
  }
]
```

### 6.5 级联字典（cascader 数据源）

**API**：[`api/system/cascadeDict.ts`](../../Ai-Front/know-vue/src/api/system/cascadeDict.ts)
- 类型管理：`getCascadeDictTypeList/add/update/delete/get`
- 数据管理：`getCascadeDictTree(typeCode?, typeId?, status?)` 返回树形 `CascadeDictNode[]`（含 `children`）
- 便捷方法：`getPlanTypeTree()`（`typeCode: 'plan_type'`）、`getIndustryTypeTree()`（`typeCode: 'industry_type'`）

**前端使用（行业列表页）**：[`views/biz/industry/list/index.vue#L236-L245`](../../Ai-Front/know-vue/src/views/biz/industry/list/index.vue#L236-L245) 加载树形并转换为 cascader 选项（`name → label`、`value` 原样），注入到 `formOptionsMap.industryType` 和 `detailOptionsMap.industryType`，传递给 `MatrixTable` 的 `options-map`。

## 7. 弹窗/全屏 Modal 规范

**组件**：[`src/components/BizFullscreenModal.vue`](../../Ai-Front/know-vue/src/components/BizFullscreenModal.vue)

**特性**：
- 基于 `a-modal`，透传大部分属性（`inheritAttrs: false`，剥离 `title` 自定义渲染）
- 标题栏含**全屏切换按钮**（`FullscreenOutlined`/`FullscreenExitOutlined`）
- `fullscreen` 状态控制 `wrap-class-name`：`biz-modal-fullscreen` + 可选 `biz-modal-scroll`
- `scrolling` 属性（非全屏时）：限制弹窗高度（`max-height: calc(100vh - 64px)`），`body` 内部滚动（便于详情长表单）
- 关闭时自动重置 `fullscreen = false`

**使用示例**（来源于实际页面）：
- 表单弹窗：[`customer/list/index.vue#L124-L142`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L124-L142) `width="960px"`，含 `@ok`/`@cancel`、`confirm-loading`
- 详情弹窗（可滚动）：[`customer/list/index.vue#L145-L154`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue#L145-L154) `scrolling`、`:footer="null"`
- 行业详情含 Tabs + 嵌套子详情：[`industry/list/index.vue#L88-L173`](../../Ai-Front/know-vue/src/views/biz/industry/list/index.vue#L88-L173)

## 8. 组件/枚举/类型/Hooks/国际化/主题

### 8.1 组件

- 全局组件自动注册：[`build/vite/plugin/components.ts`](../../Ai-Front/know-vue/build/vite/plugin/components.ts) 使用 `unplugin-vue-components` + `AntDesignVueResolver(importStyle: false)`（按需导入样式由项目 Less 管理）
- SVG 图标：[`build/vite/plugin/svgIcons.ts`](../../Ai-Front/know-vue/build/vite/plugin/svgIcons.ts) + `virtual:svg-icons-register`（[`main.ts#L2`](../../Ai-Front/know-vue/src/main.ts#L2)）
- 业务组件：`BizFullscreenModal`、`views/biz/components/*`（FieldItem、MatrixTable、SectionCard、SubSection、types）

### 8.2 枚举（enums）

**关键枚举**：
- [`enums/appEnum.ts`](../../Ai-Front/know-vue/src/enums/appEnum.ts)：`PermissionModeEnum`（`MAPPING='MAPPING'`、`BACKEND='BACKEND'`）、`AppModeEnum`、`ThemeEnum`、`LocaleEnum`、`PageTransitionEnum`
- [`enums/cacheEnum.ts`](../../Ai-Front/know-vue/src/enums/cacheEnum.ts)：`TOKEN_KEY='TOKEN_KEY'`、`USER_INFO_KEY='USER_INFO_KEY'`、`TENANT_KEY='TENANT_INFO'`、`LOCALE_KEY`、`APP_CONFIG_KEY`、`CacheTypeEnum`
- [`enums/menuEnum.ts`](../../Ai-Front/know-vue/src/enums/menuEnum.ts)、[`enums/roleEnum.ts`](../../Ai-Front/know-vue/src/enums/roleEnum.ts)、[`enums/exceptionEnum.ts`](../../Ai-Front/know-vue/src/enums/exceptionEnum.ts)

### 8.3 类型（types）

- [`types/index.ts`](../../Ai-Front/know-vue/src/types/index.ts)：通用类型（`ThemeMode`、`LocaleType`、`LoginFormState`、`UserInfo`、`LockInfo`）
- [`types/config.ts`](../../Ai-Front/know-vue/src/types/config.ts)：应用配置类型（`AppConfig`、`HeaderSetting`、`MenuSetting`、`TransitionSetting`）
- 业务类型：API 层定义接口（Query/Item），页面内按需定义

### 8.4 Hooks

- `web/`：[`useTitle.ts`](../../Ai-Front/know-vue/src/hooks/web/useTitle.ts)、[`useMessage.tsx`](../../Ai-Front/know-vue/src/hooks/web/useMessage.tsx)、[`usePage.ts`](../../Ai-Front/know-vue/src/hooks/web/usePage.ts)、[`useTags.ts`](../../Ai-Front/know-vue/src/hooks/web/useTags.ts)、[`useLockPage.ts`](../../Ai-Front/know-vue/src/hooks/web/useLockPage.ts)、[`useECharts.ts`](../../Ai-Front/know-vue/src/hooks/web/useECharts.ts)、[`useCopyToClipboard.ts`](../../Ai-Front/know-vue/src/hooks/web/useCopyToClipboard.ts)
- `setting/`：[`useBaseSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useBaseSetting.ts)、[`useMenuSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useMenuSetting.ts)、[`useHeaderSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useHeaderSetting.ts)、[`useTransitionSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useTransitionSetting.ts)、[`useLocaleSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useLocaleSetting.ts)、[`useDarkModeSetting.ts`](../../Ai-Front/know-vue/src/hooks/setting/useDarkModeSetting.ts)
- `event/`、`core/`：事件与核心 hooks

### 8.5 国际化

- [`locales/index.ts`](../../Ai-Front/know-vue/src/locales/index.ts)：`createI18n`（legacy:false、`sync:true`、`fallbackLocale: LocaleEnum.ZH_CN`、`silentTranslationWarn: true`），`setupI18n(app)`
- [`locales/helper.ts`](../../Ai-Front/know-vue/src/locales/helper.ts)：`genMessage`（按文件路径嵌套对象）、`getBrowserLang`（映射 zh_CN/zh_TW/en_US）、`setHtmlPageLang`、`t(key: string)=key`（路由专用占位）
- 语言包按模块：[`locales/langs/index.ts`](../../Ai-Front/know-vue/src/locales/langs/index.ts) 使用 `import.meta.glob('./*/**/*.json', { eager: true })` 动态加载

### 8.6 主题与样式

- 入口样式：[`design/index.less`](../../Ai-Front/know-vue/src/design/index.less) 引入 antd/transition/variable/public/plugin/scroll-bar/dark-mode
- Less 全局变量注入：[`vite.config.ts#L77`](../../Ai-Front/know-vue/vite.config.ts#L77) `@import "${resolve('src/design/variable/index.less')};"`
- 主题色：[`App.tsx`](../../Ai-Front/know-vue/src/App.tsx#L30-L36) 绑定 `colorPrimary`，`useBaseSetting` + `setThemColor` 动态更新（[`L17-L22`](../../Ai-Front/know-vue/src/App.tsx#L17-L22)）
- 暗黑模式：`getModeAlgorithm`（[`useDarkModeSetting`](../../Ai-Front/know-vue/src/hooks/setting/useDarkModeSetting.ts)）传入 `ConfigProvider.theme.algorithm`

## 9. 编码风格

| 维度 | 规范（基于实际代码观察） | 参考 |
|---|---|---|
| **组件命名** | SFC 使用 PascalCase（`FieldItem.vue`、`BizFullscreenModal.vue`、`MatrixTable.vue`），路由 name 使用 PascalCase（`BizCustomerList`、`KnowledgeBase`） | 路由模块、组件文件 |
| **文件组织** | 页面按业务域文件夹，列表页 `list/index.vue`，复用组件 `components/` 下 | [`views/biz/customer/list/index.vue`](../../Ai-Front/know-vue/src/views/biz/customer/list/index.vue) |
| **API 命名** | 动词+资源：`getCustomerPage`、`addCustomer`、`updateCustomer`、`deleteCustomer`、`updateCustomerStatus`、`setCustomerIndustries` | [`api/biz/customer.ts`](../../Ai-Front/know-vue/src/api/biz/customer.ts) |
| **类型命名** | 接口 PascalCase：`BizCustomer`、`BizCustomerQuery`、`FieldDef`、`SectionDef`、`SysMenu` | 多个 API/组件文件 |
| **变量/函数** | camelCase（`queryParams`、`handleSubmit`、`loadData`、`resetFormData`） | 页面组件普遍采用 |
| **TS 使用** | 优先类型注解（Props/Emits/接口），`defineProps`/`defineEmits` 使用泛型，`withDefaults` 设置默认值 | [`FieldItem.vue#L68-L76`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L68-L76) |
| **注释** | 关键逻辑有中文注释（点路径适配、级联回写、Chunk 刷新原因等），保持简短清晰 | [`main.ts#L16-L21`](../../Ai-Front/know-vue/src/main.ts#L16-L21)、[`FieldItem.vue#L78-L88`](../../Ai-Front/know-vue/src/views/biz/components/FieldItem.vue#L78-L88) |
| **样式** | 使用 Less，作用域样式 `scoped`，BEM 思路不强制，类名语义化（`.biz-matrix-*`、`.biz-field-*`） | 业务组件样式 |
| **代码风格工具** | ESLint + Prettier + commitlint + lint-staged（[`package.json#L15-L19`](../../Ai-Front/know-vue/package.json#L15-L19)、[`eslint.config.js`](../../Ai-Front/know-vue/eslint.config.js)、[`prettier.config.js`](../../Ai-Front/know-vue/prettier.config.js)、[`commitlint.config.js`](../../Ai-Front/know-vue/commitlint.config.js)） | 工程配置 |

**不一致点备注**：`tsconfig.json` 中 `noImplicitAny: false`、`strictFunctionTypes: false`（项目历史配置，现有代码未完全强制严格 any）。

## 10. 构建与部署

### 10.1 构建命令

**package.json**：[`"build": "rimraf dist && vue-tsc --noEmit && vite build"`](../../Ai-Front/know-vue/package.json#L12)

- 先 `vue-tsc --noEmit` 类型检查，再 Vite 构建
- 本地构建脚本示例：[`fe-build2.bat`](../../Ai-Project/.tmp/fe-build2.bat) 设置 `NODE_OPTIONS=--max-old-space-size=6144` 并将日志输出到 `.tmp/fe-build2.log`

**构建产物**：`dist/`（静态资源，包含 hash）

### 10.2 部署路径与 Nginx

**部署路径（服务器）**：
- 管理端（know-vue）：`/opt/ai-agent/apps/know-vue/`（[`standalone/deploy.js#L42`](../../Ai-Project/Ai-Service/know-boot/standalone/deploy.js#L42)、[`microservice/deploy.sh#L77`](../../Ai-Project/Ai-Service/know-boot/microservice/deploy.sh#L77)）
- 移动端 H5（know-mobile）：`/opt/ai-agent/apps/know-mobile/`
- 升级包（wgt）：`/opt/ai-agent/upgrade/wgt/`（[`standalone/deploy.js#L220-L222`](../../Ai-Project/Ai-Service/know-boot/standalone/deploy.js#L220-L222)）

**Nginx 配置要点（单体部署示例）**：[`standalone/deploy.js#L153-L228`](../../Ai-Project/Ai-Service/know-boot/standalone/deploy.js#L153-L228)
```nginx
location / {
    root /opt/ai-agent/apps/know-vue;
    index index.html;
    try_files $uri $uri/ /index.html;  # SPA history/hash fallback
}
location /api/ { proxy_pass http://127.0.0.1:8082/api/; ... }
location /upgrade/wgt/ { alias /opt/ai-agent/upgrade/wgt/; }
location /mobile/ { alias /opt/ai-agent/apps/know-mobile/; try_files $uri $uri/ /mobile/index.html; }
```

**微服务部署**：[`microservice/deploy.sh`](../../Ai-Project/Ai-Service/know-boot/microservice/deploy.sh) 按服务端口（8086 knowledge、8083 plan、8082 system 等）做路径转发。

### 10.3 静态资源缓存与 chunk 替换

**问题**：Vite 构建按内容哈希拆分（见 [`main.ts#L17-L21`](../../Ai-Front/know-vue/src/main.ts#L17-L21) 注释）。发布替换旧资源时，旧标签页可能请求已不存在的旧 hash chunk，导致 404 → Vue Router 中断导航（表现「只切 tab 不显示页面」）。

**规避方案（已实现）**：
- `vite:preloadError` 事件监听 + `router.onError` 兜底，识别动态 import 失败消息，10 秒内最多自动刷新一次（[`main.ts#L22-L62`](../../Ai-Front/know-vue/src/main.ts#L22-L62)）
- **推荐部署实践**：发布时采用非覆盖式替换（备份旧目录再解压新 dist，如 [`deploy.js#L264`](../../Ai-Project/Ai-Service/know-boot/standalone/deploy.js#L264)：`rm -rf ${remoteDir} && mkdir -p ${remoteDir} && tar -xzf ... -C ${remoteDir}`）配合 Nginx `try_files` + 前端自动刷新兜底，能有效降低缓存冲突影响。

**其他注意**：`index.html` 使用相对 `./` base（[`vite.config.ts#L46`](../../Ai-Front/know-vue/vite.config.ts#L46)），便于部署在子路径或不同域名路径下。

## 11. 推荐模板汇总

### (1) Route Module 模板
见 3.2 节「推荐模板（路由模块）」

### (2) API Module 模板
见 4.2 节「推荐模板（API 模块，RESTful 风格）」

### (3) CRUD List Page Skeleton 模板
见 5.1 节「推荐模板（列表页）」

### (4) sections.ts Entry 模板
见 6.4 节「推荐模板（sections.ts）」

### (5) FieldItem Branch（按类型选用）
FieldItem 内置类型：`input/textarea/select/selectMultiple/number/date/cascader`。典型用法：
```ts
{ label: '名称', key: 'name', span: 12, required: true }
{ label: '描述', key: 'desc', type: 'textarea', rows: 3, span: 24 }
{ label: '状态', key: 'status', type: 'select', options: [{label:'启用',value:1},{label:'禁用',value:0}], span: 12 }
{ label: '标签', key: 'tags', type: 'selectMultiple', options: opts, span: 24 }
{ label: '排序', key: 'sort', type: 'number', span: 12 }
{ label: '日期', key: 'date', type: 'date', span: 12 }
{ label: '行业类型', key: 'industryType', type: 'cascader', span: 12 }  // optionsMap 注入树形
```

## 结语

本文档基于对 `know-vue` 实际代码的全面阅读整理，优先列出**可验证的文件路径与代码片段**。文中已标注的「不一致点」（如响应码判定 0/1/2/200、Token header 为 `token`、`tsconfig` 严格性放宽等）均为项目现状记录，**不做臆造**。开发时请优先遵循本规范，并与周边代码（命名、结构、模式）保持一致。

---

**文件路径**：`E:\Ai-Project\Ai-Design-V2\开发规范\02-管理端(know-vue)开发规范.md`  
**主要覆盖**：技术栈与工程结构、目录规范、路由规范（含动态菜单与 Chunk 404 自动刷新机制）、API 层规范、CRUD/字段配置驱动视图规范（sections+FieldItem+MatrixTable+BizFullscreenModal）、编码风格、构建与部署  
**已识别的不一致/注意事项**：Axios 响应成功码包含 0/1/2/200、Token 请求头使用 `token` 而非 `Authorization`、`tsconfig` 部分严格选项关闭、守卫中存在调试 `console.log`、动态菜单降级逻辑明确。
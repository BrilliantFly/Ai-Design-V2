# know-uniapp 移动端（uni-app + Vue 3 + TypeScript）开发规范

> 本规范基于项目实际代码产出，**每条规则均需可溯源到真实文件**（路径均相对于 `know-uniapp/`）。文中标注了已发现的**不一致点（Inconsistencies）**，请在变更时重点关注。

**最后更新**：2025-10-14  
**项目根**：`know-uniapp/`  
**目标平台**：H5、App（APP-PLUS）、各类小程序（mp-*）  
**框架**：uni-app 3.0.0-3070920230324001 + Vue 3.2.45 + TypeScript 4.7.4 + Pinia 2.0.20

---

## 目录

- [1. 技术栈与工程结构](#1-技术栈与工程结构)
- [2. 目录规范](#2-目录规范)
- [3. pages.json 配置规范](#3-pagesjson-配置规范)
- [4. 页面开发规范](#4-页面开发规范)
- [5. 组件规范](#5-组件规范)
- [6. 表单与弹层规范（小记风格）](#6-表单与弹层规范小记风格)
- [7. 主题/多风格/皮肤系统（重点：首页标语的多风格实现）](#7-主题多风格皮肤系统重点首页标语的多风格实现)
- [8. 网络请求规范](#8-网络请求规范)
- [9. 状态管理、hooks、mixins、enums、types](#9-状态管理hooksmixinsenumstypes)
- [10. 代码风格](#10-代码风格)
- [11. 构建与运行](#11-构建与运行)
- [附录：不一致点清单](#附录不一致点清单)
- [附录：推荐模板/示例（最小可用）](#附录推荐模板示例最小可用)

---

## 1. 技术栈与工程结构

### 1.1 技术栈（溯源：`package.json`）

| 类别 | 版本/库 | 说明 | 溯源 |
|---|---|---|---|
| 核心框架 | `@dcloudio/uni-app@3.0.0-3070920230324001`、`vue@3.2.45`、`@dcloudio/types@3.3.2`、`typescript@4.7.4` | uni-app Vue3 + TS 基座 | [`package.json:38-63, 65`](know-uniapp/package.json#L38-L66) |
| 状态管理 | `pinia@2.0.20` | 全局状态（user/app/dict/theme/appVersion） | [`package.json:56`](know-uniapp/package.json#L56) |
| 路由 | `uniapp-router-next@1.2.7`、`unplugin-uni-router@1.2.7` | 声明式路由、路由守卫、权限校验 | [`package.json:57,88`](know-uniapp/package.json#L57-L88) |
| UI/组件 | `vk-uview-ui`（通过 `uni_modules` 引入）、`z-paging@2.7.6` | uView 生态 + 上拉加载分页 | [`package.json:62`](know-uniapp/package.json#L62)、[`src/plugins/modules/uview.ts`](know-uniapp/src/plugins/modules/uview.ts)、[`pages.json:89-96`](know-uniapp/pages.json#L89-L96) |
| 样式 | `tailwindcss@3.3.2`、`postcss@8.4.16`、`postcss-rem-to-responsive-pixel@5.1.3`、`autoprefixer@10.4.8`、`sass@1.54.5` | 原子类 + rem→rpx（仅非 H5）+ SCSS | [`package.json:76,81-87`](know-uniapp/package.json#L76-L87)、[`postcss.config.js`](know-uniapp/postcss.config.js)、[`tailwind.config.js`](know-uniapp/tailwind.config.js) |
| 工具库 | `lodash-es@4.17.21`、`css-color-function@1.3.3`、`vconsole@3.14.6`、`weixin-js-sdk@1.6.0`、`highlight.js@^11.11.1`、`@highlightjs/vue-plugin@^2.1.0`、`prismjs@^1.30.0` | 工具函数、主题色计算、调试、微信 JS-SDK、代码高亮 | [`package.json:52-63,73,84,91`](know-uniapp/package.json#L52-L63) |
| 构建 | `vite@4.1.4`、`@dcloudio/vite-plugin-uni@3.0.0-3070920230324001` | Vite 构建 | [`package.json:69-70,89`](know-uniapp/package.json#L69-L89) |

### 1.2 入口与全局配置（溯源）

| 文件 | 要点 | 溯源 |
|---|---|---|
| `src/main.ts` | `createSSRApp(App)` → `setupMixin(app)` → `app.use(plugins)` → `app.use(router)`，全局样式 `./styles/index.scss` | [`src/main.ts`](know-uniapp/src/main.ts) |
| `src/App.vue` | `onLaunch` 初始化（主题、配置、菜单、用户、字典、版本更新、提醒）。H5 首次渲染前设置 `document.documentElement.setAttribute('data-theme', saved\|\|'white')`。**非 H5** 通过 `v-bind('themeStore.themeInlineVars[...]')` 将主题变量注入 `page` | [`src/App.vue:1-162`](know-uniapp/src/App.vue) |
| `src/manifest.json` | 应用名「喵百科」、`appid: __UNI__32EDE25`、`versionName: 1.0.3`、H5 路由 history `base: /mobile/`、mp-weixin `appid` 存在 | [`src/manifest.json`](know-uniapp/src/manifest.json) |
| `src/pages.json` | 页面、subPackages（`packages/*`）、`globalStyle`、条件编译 `tabBar`（`#ifndef APP-PLUS` 且 `custom: true`）、`easycom` 自定义组件映射 | [`src/pages.json:1-96`](know-uniapp/pages.json) |
| `vite.config.ts` | 端口 `8991`；代理：`/api/plan→8082`、`/api/knowledge→8086`、`/api/python→5000`、`/adminapi→8082`（rewrite 去前缀）、`/api→8082`；PostCSS：`tailwindcss` + `postcss-rem-to-wx`（**仅非 H5** 生效，`$1rem=32rpx`）；插件 `uniRouter()`；H5 base `/mobile/`，开发时 301 `/mobile`→`/mobile/` | [`vite.config.ts`](know-uniapp/vite.config.ts) |
| `tsconfig.json` | `strict: true`，路径别名 `@/* → ./src/*`，类型 `@dcloudio/types` | [`tsconfig.json`](know-uniapp/tsconfig.json) |
| `src/uni.scss` | uView 变量映射到 Tailwind 风格的颜色（`$u-type-primary: theme("colors.primary.500")` 等） | [`src/uni.scss`](know-uniapp/src/uni.scss) |

**不一致点（溯源）**：
- [`var.css`](know-uniapp/src/styles/var.css) **文件为空（0 字节）**，但项目实际主题变量定义在 [`themes.scss`](know-uniapp/src/styles/themes.scss) 和 [`variables.scss`](know-uniapp/src/styles/variables.scss)。**不要**再依赖 `var.css`。
- `App.vue` 同时存在 **H5 用 `html[data-theme]`（由 `themes.scss` 驱动 CSS 变量）** 与 **非 H5 用 `page { ... v-bind(themeStore.themeInlineVars) }`** 两套注入方式，且 [`stores/theme.ts`](know-uniapp/src/stores/theme.ts) 中 `THEME_COLORS` 也需与主题定义保持同步（人工维护风险）。

---

## 2. 目录规范

基于实际 `src/` 结构（溯源：[`src/`](know-uniapp/src) 目录清单）：

| 目录 | 用途 | 规范要点 |
|---|---|---|
| `src/api/` | 后端接口模块，按业务域划分 | `plan/*`、`system/*`、`biz/industry/*`、`python/*`，以及扁平 `auth.ts/user.ts/...`。统一使用 `@/utils/request`。方法命名 `getXxxPage/getXxxList/addXxx/updateXxx/deleteXxx` 等。详见 §8。 | 
| `src/components/` | 全局/业务组件 | 单文件平铺（如 [`PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue)）或**目录包裹**（kebab-case 目录名，内部主文件同目录名 `.vue` 或 `index.vue`）。组件名推荐 PascalCase，使用 `setup` + `<script setup lang="ts">`。 | 
| `src/config/` | 配置驱动定义 | `industry-sections.ts`、`customer-sections.ts`、`product-sections.ts`、`market-sections.ts`、`enterprise-sections.ts` 等 `UniSectionDef/UniFieldDef` 定义（用于表单页配置化渲染）。 | 
| `src/data/` | 静态数据 | 如 [`holiday-schedules.js`](know-uniapp/src/data/holiday-schedules.js)。 | 
| `src/enums/` | 枚举常量 | `requestEnums.ts`、`appEnums.ts`、`constantEnums.ts`、`agreementEnums.ts`。统一大写常量或 `enum`，集中维护。 | 
| `src/hooks/` | Composables | `useLockFn.ts`、`useHoverEffect.ts`、`useCopy.ts`、`useAppVersion.ts`。命名 `useXxx`。 | 
| `src/mixins/` | 混入（全局注入） | `index.ts` 通过 `setupMixin` 安装，`theme.ts` 注入 `$theme` 计算属性（[`src/mixins/theme.ts`](know-uniapp/src/mixins/theme.ts)）。新逻辑优先用 composables 而非 mixin。 | 
| `src/packages/` | 分包根目录 | 对应 `pages.json` 的 `subPackages`（根 `packages`，含 `404/recharge/recharge_record/user_wallet` 等子模块）。分包页面路径遵循 `packages/<module>/<name>`。 | 
| `src/pages/` | 主包页面 | 路径 `pages/<module>/<name>`。首页相关：[`pages/index/index.vue`](know-uniapp/src/pages/index/index.vue)（主）、[`pages/index/index-v1.vue`](know-uniapp/src/pages/index/index-v1.vue)（**遗留**）、标语页 [`pages/plan/slogan/index.vue`](know-uniapp/src/pages/plan/slogan/index.vue)。 | 
| `src/plugins/` | 插件注册 | `index.ts` 使用 `import.meta.globEager('./modules/**/*.ts')` 批量安装。模块：`pinia.ts`、`uview.ts`、`vconsole.ts`（H5 条件启用：`/?vconsole=<md5>`）。 | 
| `src/router/` | 路由配置 | [`src/router/index.ts`](know-uniapp/src/router/index.ts) 基于 `uniapp-router-next`，含登录守卫（`to.meta.auth/white`）、重定向（`/pages/plan/home→/index`）、H5 微信 OA 场景处理。 | 
| `src/static/` | 静态资源 | 图片、字体等。 | 
| `src/stores/` | Pinia stores | `user.ts`、`app.ts`、`dict.ts`、`theme.ts`、`appVersion.ts`。统一 `useXxxStore` 命名。 | 
| `src/styles/` | 全局样式 | `index.scss` 顺序：`tailwind.css` → `variables.scss` → `themes.scss` → `keyframes.scss` → `public.scss` → `premium.scss` → `page-header.scss` → `vk-uview-ui/index.scss`。详见 §7。 | 
| `src/types/` | 类型声明 | 全局类型、补充声明（如 [`shims-prism.d.ts`](know-uniapp/src/types/shims-prism.d.ts)）。 | 
| `src/uni_modules/` | uni_modules 组件 | 项目依赖的 uni_modules（含 vk-uview-ui 等）。 | 
| `src/utils/` | 工具函数 | `request/`（核心请求封装）、`theme.ts`、`util.ts`、`app-update.ts`、`reminder.ts` 等。 |

**不一致点**：[`src/pages/index/index-v1.vue`](know-uniapp/src/pages/index/index-v1.vue) 为**旧版首页（商铺风格）**，当前线上/主逻辑使用 [`src/pages/index/index.vue`](know-uniapp/src/pages/index/index.vue)。在维护时需明确是否仍在引用，避免误改旧文件。

---

## 3. pages.json 配置规范

溯源：[`pages.json`](know-uniapp/pages.json)

| 项 | 规范 | 实际体现 |
|---|---|---|
| `pages` | 主包页面数组。路径统一 `pages/<module>/<name>`。大多数自定义导航的页面设置 `style.navigationStyle: custom`。可用 `meta: { auth: true }` 或 `{ white: true }`。 | 例如：[`pages/plan/slogan/index`](know-uniapp/pages.json#L7-L22)（`navigationStyle: custom`）。 |
| `subPackages` | 分包，`root: "packages"`，子项 `pages: [...]`。 | 含 `404`、`recharge`、`recharge_record`、`user_wallet` 等模块。 |
| `globalStyle` | 全局样式。H5 场景下 `navigationStyle: custom`。 | [`pages.json:77-88`](know-uniapp/pages.json#L77-L88) |
| `tabBar` | **条件编译**：仅 `#ifndef APP-PLUS` 启用，且 `custom: true`（自定义 tabbar）。items 共 5 个：工作台、小记、新建、知识库、我的，对应路径见表。 | [`pages.json:57-76`](know-uniapp/pages.json#L57-L76)。实际渲染由自定义组件完成（见 §5.2）。 |
| `easycom` | 自动注册组件。规则：`router-navigate` → `@/components/router-navigate/router-navigate.vue`；`z-paging*` 白名单排除刷新/加载更多子组件后映射 `z-paging(.*)` → `@/uni_modules/z-paging/components/z-paging/z-paging.vue`；`^w-(.*)` → `@/components/widgets/$1/$1.vue`。 | [`pages.json:89-96`](know-uniapp/pages.json#L89-L96) |

**tabBar 实际路径（溯源）**：

| label | path（pages.json） | 对应自定义底栏逻辑 |
|---|---|---|
| 工作台 | `/pages/knowledge/home/index` | [`PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue) fallback/remote 映射 `workspace` |
| 小记 | `/pages/knowledge/memo/index` | `memo` |
| 新建 | `/pages/index/index` | `home`（中间） |
| 知识库 | `/pages/knowledge/list/index` | `knowledge` |
| 我的 | `/pages/user/user` | `profile` |

**注意**：`pages.json` 中 `tabBar.custom: true` 意味**原生 uni-app tabBar 不渲染**，由自定义实现接管（[`PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue)、[`custom-tab-bar/index.vue`](know-uniapp/src/components/custom-tab-bar/index.vue)、[`tabbar/tabbar.vue`](know-uniapp/src/components/tabbar/tabbar.vue)、[`tab/tab.vue`](know-uniapp/src/components/tab/tab.vue)、[`tabs/tabs.vue`](know-uniapp/src/components/tabs/tabs.vue)）。

**不一致点**：`easycom` 将 `^w-(.*)` 映射到 `widgets/$1/$1.vue`，这要求**每个 widget 目录下必须有同名 `.vue` 主文件**。实际 [`widgets/ThemeSwitcher.vue`](know-uniapp/src/components/widgets/ThemeSwitcher.vue) 为**平铺文件**而非目录包裹。若按当前映射规则直接使用 `w-themeswitcher` 将找不到目录式主文件。建议统一 widget 组织方式（目录+同名文件）或调整 easycom 映射。

---

## 4. 页面开发规范

### 4.1 基本约定

- 页面文件放置于 `src/pages/<module>/<name>.vue`，主包。分包放 `src/packages/<module>/<name>.vue`。
- 使用 `<script setup lang="ts">`（Composition API + setup）。
- 遵循 uni-app 页面生命周期（`onLoad/onShow/onReady/onHide/onUnload` 等）和条件编译（`#ifdef H5/#ifndef H5/#ifdef APP-PLUS`）。
- 页面级样式用 `scoped`，全局样式通过 `styles/` 注入。
- 权限：路由守卫基于 `to.meta.auth` 判断是否需要登录（[`router/index.ts`](know-uniapp/src/router/index.ts)）。工具 `requireLogin(path)` 也可在组件内校验（[`PremiumBottomNav.vue:320`](know-uniapp/src/components/PremiumBottomNav.vue#L320)）。

### 4.2 首页（slogan 标语）重点

**页面**：[`src/pages/plan/slogan/index.vue`](know-uniapp/src/pages/plan/slogan/index.vue)

- 功能：标语列表（CRUD）、左滑删除/编辑、底部弹窗新增/编辑、表单字段：`content`、`emoji`、`sort`、`status`（启用/停用）、**快捷 emoji** `['✨','🚀','💡','🌟','🔥','🎯','💪','⚡']`。
- 接口：[`src/api/plan/slogan.ts`](know-uniapp/src/api/plan/slogan.ts) 提供 `getSloganPage(params)`、`getSloganList(params)`、`addSlogan(data)`、`updateSlogan(data)`、`deleteSlogan(id)`，均请求 `/plan/slogan*`。
- **展示端**：[`src/pages/index/index.vue`](know-uniapp/src/pages/index/index.vue) 的 hero 子标题（`heroSubline`，约 L529-538）展示 `slogan.emoji + slogan.content`，通过 `sloganIndex` 定时轮播（`SLOGAN_ROTATE_INTERVAL = 5000`），`onShow` 启动轮播、`onHide` 清理，数据来源 `loadSlogan()` 调用 `getSloganList({ status: 1 })`。

**“多风格/多套样式”实现说明（本项目实际情况）**：

- 项目中**并未**发现标语实体本身携带 `style/variant/themeKey/class` 等“多风格”字段。标语数据结构仅包含 `id/content/emoji/sort/status` 等（见接口用法：[`slogan/index.vue`](know-uniapp/src/pages/plan/slogan/index.vue) 表单与列表渲染）。
- **真正的“多风格”是全局皮肤系统**（20 套视觉主题）通过 CSS 变量作用于首页 hero 及整站：hero 区域使用 `linear-gradient(135deg, var(--color-primary), var(--color-minor))`、`var(--color-text)`、`var(--color-border-light)` 等（见 [`index.vue`](know-uniapp/src/pages/index/index.vue) 样式中主题变量引用）。
- 因此，所谓“首页标语的多风格实现”在本仓库的**代码实证**上应表述为：**标语内容（文本+emoji）由后端/本地列表决定展示，不区分样式变体；样式由全局主题（§7）控制**。

**不一致点（重要）**：
- 根目录快照 [`slogan-page-snapshot.md`](know-uniapp/../slogan-page-snapshot.md)（位于 `E:\Ai-Project\slogan-page-snapshot.md`）描述标语页时提及“支持设置生效时间窗”（如 `startTime/endTime/validTimeRange` 等字段）。**当前代码中完全不存在**此类时间窗字段：表单无时间选择器，列表无时间列，接口参数也未包含时间范围。此为**快照过时**，不得照抄入规范，应明确标注“当前实现未支持生效时间窗”。
- 首页存在 [`index-v1.vue`](know-uniapp/src/pages/index/index-v1.vue) 旧版实现。当前主文件为 [`index.vue`](know-uniapp/src/pages/index/index.vue)。规范中应避免将 v1 视作活跃规范。

### 4.3 页面模板（推荐）

参见[附录：页面最小模板](#推荐页面模板pagesplanxindexvue)（基于实际风格：`setup` + 类型、路由守卫注意、列表页常用 `z-paging` 思路）。

---

## 5. 组件规范

### 5.1 命名与组织

- 组件文件：**单文件**（PascalCase 或 kebab-case.vue）或**目录**（kebab-case 目录，主文件 `目录名.vue` 或 `index.vue`）。
- 全局自动注册：通过 `easycom`（§3）实现。业务内按需导入。
- 推荐使用 `<script setup lang="ts">`，显式 `defineProps<...>()`/`defineEmits<...>()` 或运行时 `defineProps({...})`。类型优先用 `interface`/`type` 定义于组件内或 `@/types`。
- 样式：`<style scoped lang="scss">`。跨平台注意 rpx 单位（PostCSS rem→rpx 规则见 §1.2）。

### 5.2 底部导航（自定义 tabbar）

实际项目存在多套自定义底栏实现，需按用途区分：

| 组件 | 路径 | 说明 |
|---|---|---|
| `PremiumBottomNav.vue` | [`src/components/PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue) | **主力自定义底栏**。远程菜单（`getTabbarMenu`/`getTabbarMenuByUser`）+ 本地 `fallbackItems`（5 项：工作台/小记/新建/知识库/我的）。支持图片/emoji/SVG 图标、`switchTab`/`navigateTo` 智能判断、路径归一化、登录校验（`requireLogin`）、`useHoverEffect` 交互。样式使用 CSS 变量（`var(--color-primary)` 等）。 |
| `custom-tab-bar/index.vue` | [`src/components/custom-tab-bar/index.vue`](know-uniapp/src/components/custom-tab-bar/index.vue) | 另一套自定义 tabbar（基于 `appStore.getTabbarConfig`、`switchTab` 跳转）。 |
| `tabbar/tabbar.vue`、`tab/tab.vue`、`tabs/tabs.vue` | [`src/components/tabbar/tabbar.vue`](know-uniapp/src/components/tabbar/tabbar.vue)、[`src/components/tab/tab.vue`](know-uniapp/src/components/tab/tab.vue)、[`src/components/tabs/tabs.vue`](know-uniapp/src/components/tabs/tabs.vue) | 通用选项卡/底栏组件（含 hooks：[`tabs/hooks/useTabList.ts`](know-uniapp/src/components/tabs/hooks/useTabList.ts)）。 |

**规范建议**：页面若使用自定义 tabbar，应统一采用 `PremiumBottomNav.vue` 的远程菜单策略（权限感知），避免同时渲染两套底栏。注意 `pages.json` 已将原生 tabBar 设为 `custom: true` 且仅非 APP-PLUS 生效。

### 5.3 业务组件（表单/弹层相关）

表单与弹层大量采用“sheet”（底部弹窗）风格，见 §6。关键组件：

| 组件 | 用途 | 溯源 |
|---|---|---|
| `industry/IndustryFormSheet.vue` | 产业链表单 Sheet | [`src/components/industry/IndustryFormSheet.vue`](know-uniapp/src/components/industry/IndustryFormSheet.vue) |
| `industry/ProductFormSheet.vue`、`MarketFormSheet.vue`、`EnterpriseFormSheet.vue`、`IndustryDetailSheet.vue`、`ChainView.vue`、`BusinessModelGrid.vue`、`StatBar.vue`、`FinancePanel.vue`、`CustomerDistPanel.vue`、`IndustryTabs.vue` | 产业链相关 UI | [`src/components/industry/*`](know-uniapp/src/components/industry) |
| `customer/CustomerFormSheet.vue`、`FieldItem.vue`、`SectionCard.vue`、`SubSection.vue`、`MultiSelectChips.vue`、`IndustryPicker.vue`、`EnterprisePicker.vue` | 客户表单配置化渲染 | [`src/components/customer/*`](know-uniapp/src/components/customer) |
| `cascade/CascadePicker.vue` | 级联选择器 | [`src/components/cascade/CascadePicker.vue`](know-uniapp/src/components/cascade/CascadePicker.vue) |
| `empty-state/EmptyState.vue`、`page-status/page-status.vue` | 空态/页面状态 | [`src/components/empty-state/EmptyState.vue`](know-uniapp/src/components/empty-state/EmptyState.vue)、[`src/components/page-status/page-status.vue`](know-uniapp/src/components/page-status/page-status.vue) |
| `widgets/*` | 首页/我的等区块组件（easycom `w-*` 映射） | [`src/components/widgets/*`](know-uniapp/src/components/widgets)（注意 ThemeSwitcher 平铺） |

### 5.4 组件模板（推荐）

参见[附录：组件最小模板](#推荐组件模板srccomponentsmycomptvue)。

---

## 6. 表单与弹层规范（小记风格）

项目表单弹层普遍采用“**小记风格（journal style）**”Sheet：

- **结构**：顶部拖拽把手（drag handle）、居中标题、全屏或接近全屏的底部弹窗、圆角、白色背景字段区。
- **字段项**：由 `FieldItem.vue` + `SectionCard.vue` + `SubSection.vue` 组合渲染，基于**配置驱动**（`src/config/*-sections.ts` 中 `UniFieldDef/UniSectionDef`）。
- **类型支持**：`'text'|'number'|'textarea'|'select'|'selectMultiple'|'industryPicker'|'industryParent'|'date'|'cascade'` 等（见 [`industry-sections.ts`](know-uniapp/src/config/industry-sections.ts) 字段定义）。
- **占位符约定**：`placeholder` **必须包含括号说明**“选填/必填”（实证：[`industry-sections.ts`](know-uniapp/src/config/industry-sections.ts) 多处使用如 `请输入（选填）`、`请输入（必填）`）。
- **交互**：滚动穿透处理、底部安全区适配、键盘避让（uni-app 常用实践），保存/取消按钮固定底部。
- **示例**：[`IndustryFormSheet.vue`](know-uniapp/src/components/industry/IndustryFormSheet.vue)、[`CustomerFormSheet.vue`](know-uniapp/src/components/customer/CustomerFormSheet.vue)。

**section-config 推荐结构（溯源）**：

参见 [`industry-sections.ts`](know-uniapp/src/config/industry-sections.ts) 定义：

```ts
// 溯源：src/config/industry-sections.ts（节选）
export interface UniFieldDef {
  label: string
  key: string
  type: 'text'|'number'|'textarea'|'select'|'selectMultiple'|'industryPicker'|'industryParent'|'date'|'cascade'
  options?: Array<{label:string,value:any}>
  placeholder?: string
  required?: boolean
  [k:string]: any
}
export interface UniSectionDef {
  title: string
  defaultOpen?: boolean
  fields?: UniFieldDef[]
  subSections?: UniSectionDef[]
}
```

**规范**：新增业务表单时优先**配置化**定义 sections，而非逐个页面硬编码大量输入项。确保 `placeholder` 遵循“（选填）/（必填）”约定。

---

## 7. 主题/多风格/皮肤系统（重点：首页标语的多风格实现）

本项目主题系统是**全局 CSS 变量驱动的多套视觉风格（20 套）**，而**标语本身无样式变体字段**（见 §4.2）。

### 7.1 样式入口与变量

| 文件 | 说明 | 溯源 |
|---|---|---|
| `src/styles/index.scss` | 全局样式导入顺序（严格保持此顺序）：`tailwind.css` → `variables.scss` → `themes.scss` → `keyframes.scss` → `public.scss` → `premium.scss` → `page-header.scss` → `vk-uview-ui/index.scss` | [`src/styles/index.scss`](know-uniapp/src/styles/index.scss) |
| `src/styles/variables.scss` | `:root` 默认变量：`--color-primary`、`--color-minor`、`--radius-*`、`--shadow-*`、`--gradient-primary`、`--duration`、`--ease` 等 | [`src/styles/variables.scss`](know-uniapp/src/styles/variables.scss) |
| `src/styles/themes.scss` | **核心**：按 `html[data-theme='<key>']` 定义 20 套完整 CSS 变量集。主题键：`white,dark,warm,aurora,purple,glass,orangold,macaron,mint,lavender,milky,matcha,berry,ocean,cream,chocolate,neon,sakura,forest,sunset`。每套覆盖背景、文本、边框、主色、渐变等全量变量。 | [`src/styles/themes.scss`](know-uniapp/src/styles/themes.scss) |
| `src/styles/var.css` | **空文件（0 字节）**。项目未使用。 | [`src/styles/var.css`](know-uniapp/src/styles/var.css) |
| `src/styles/public.scss` | `page` 基础、H5 隐藏框架 tabbar、通用类 | [`src/styles/public.scss`](know-uniapp/src/styles/public.scss) |
| `src/styles/premium.scss` | 高级视觉类：`.premium-card`、`.premium-btn*`、`.premium-icon-g1..g10/gw`、`.premium-fade-in/.premium-d1..d7`、悬停系统 | [`src/styles/premium.scss`](know-uniapp/src/styles/premium.scss) |
| `src/styles/page-header.scss` | 页头类：`.page-title`（48rpx/700）、`.page-subtitle`（26rpx） | [`src/styles/page-header.scss`](know-uniapp/src/styles/page-header.scss) |
| `src/styles/keyframes.scss` | 动画关键帧（fade/slide/scale/spin/pulse/shimmer/skeleton） | [`src/styles/keyframes.scss`](know-uniapp/src/styles/keyframes.scss) |
| `src/styles/tailwind.css` | `@tailwind base`（仅 H5 生效上下文）+ 工具类预置 | [`src/styles/tailwind.css`](know-uniapp/src/styles/tailwind.css) |
| `src/styles/icon.css` | cuIcon 图标（alicdn CDN） | [`src/styles/icon.css`](know-uniapp/src/styles/icon.css) |

### 7.2 主题状态与逻辑

| 文件 | 说明 | 溯源 |
|---|---|---|
| `src/stores/theme.ts` | Store：`useThemeStore`。状态：`primaryColor/minorColor/btnColor/navColor/navBgColor/vars/currentVisualTheme: 'white'`。常量：`VISUAL_THEMES`（20 项 `{key,name,icon}`）、`THEME_COLORS`（**非 H5** 用于 `themeInlineVars` 的每主题色值映射）。持久化：`uni.setStorageSync('THEME_STORAGE_KEY='know-theme', key)`。动作：`getTheme()`（恢复本地→拉取服务端 decorate id5）、`setVisualTheme(key)`（存储+应用）、`applyVisualTheme()`（H5 设置 `data-theme`）、`setTheme`。Getter：`currentThemeConfig`、`themeInlineVars`（合并 `THEME_COLORS[currentVisualTheme]` + `mergeServerColors`）。 | [`src/stores/theme.ts`](know-uniapp/src/stores/theme.ts) |
| `src/utils/theme.ts` | 工具：`generateVars`、`mergeServerColors`、`hexToRgb`、css-color-function（tint/shade）相关计算。 | [`src/utils/theme.ts`](know-uniapp/src/utils/theme.ts) |
| `src/mixins/theme.ts` | 全局 mixin 注入 `$theme`：`{ primaryColor, pageStyle, navColor, navBgColor, title }`。 | [`src/mixins/theme.ts`](know-uniapp/src/mixins/theme.ts) |
| `src/App.vue` | H5：应用启动时读取 `know-theme` 并设置 `document.documentElement.setAttribute('data-theme', ...)`。非 H5：通过 `page { --var: v-bind(themeStore.themeInlineVars[...]) }` 注入全量变量（见 L140-161）。同时 `onLaunch` 调用 `themeStore.getTheme()`。 | [`src/App.vue:22-29,82,140-161`](know-uniapp/src/App.vue) |

### 7.3 主题选择 UI

| 文件 | 说明 | 溯源 |
|---|---|---|
| `src/components/widgets/ThemeSwitcher.vue` | 主题切换器，调用 `useThemeStore().setVisualTheme(key)`。 | [`src/components/widgets/ThemeSwitcher.vue`](know-uniapp/src/components/widgets/ThemeSwitcher.vue) |
| `src/pages/theme/index.vue` | 20 套主题网格选择页。 | [`src/pages/theme/index.vue`](know-uniapp/src/pages/theme/index.vue) |
| `src/pages/user_set/user_set.vue` | 个人设置页中的主题入口/切换区（约 L207-242）。 | [`src/pages/user_set/user_set.vue`](know-uniapp/src/pages/user_set/user_set.vue) |

### 7.4 首页标语的“多风格”实证结论

- **标语数据模型无样式字段**：[`slogan.ts`](know-uniapp/src/api/plan/slogan.ts) 定义的增删改查仅操作 `content/emoji/sort/status`（从页面用法推断）。标语展示纯文本+emoji（[`index.vue`](know-uniapp/src/pages/index/index.vue): `heroSubline` 显示 `emoji + content`）。
- **样式来自全局主题**：hero 区使用 `var(--color-primary)`、`var(--color-minor)`、`var(--color-text-secondary)`、`var(--color-border-light)` 等 CSS 变量（[`index.vue`](know-uniapp/src/pages/index/index.vue) 样式）。切换主题（ThemeSwitcher）即切换整套 CSS 变量，**间接**改变标语及整个首页视觉风格。
- **因此“多风格实现”定义**：本项目的“多风格”指**应用级皮肤（20 套主题）**，而非“标语多样式变体”。若业务要支持“同一标语按场景套不同样式”，需**新增样式字段**（如 `styleKey/class`）并在渲染处应用对应类/内联变量。

**不一致点**：
- [`slogan-page-snapshot.md`](know-uniapp/../slogan-page-snapshot.md) 将标语页描述为支持“多风格设置”等，**与现代码不符**。
- **双轨主题注入**：H5 用 `data-theme` + `themes.scss`，非 H5 用 `v-bind(themeInlineVars)` 注入到 `page`。`THEME_COLORS`（store）与 `themes.scss` 两处维护同一套色值，**必须保持严格一致**，否则平台间主题不一致。
- [`var.css`](know-uniapp/src/styles/var.css) 为空却可能被误引用。

### 7.5 Themed style 示例（推荐）

参见[附录：themed style 最小示例](#推荐themed-style-示例)。

---

## 8. 网络请求规范

### 8.1 核心封装

封装位于 [`src/utils/request/`](know-uniapp/src/utils/request)：

| 文件 | 说明 | 溯源 |
|---|---|---|
| `index.ts` | 对外 `createRequest()`，默认配置：`baseUrl: config.baseUrl`、`urlPrefix: 'api'`、`withToken: true`、`isAuth: false`、`retryCount: 2`、`timeout: 60s`。请求拦截：自动拼接 `urlPrefix`（跳过 `/python/`、`/customer/`）、设置 `baseUrl`、header 注入 `token`（`getToken()`）、`header.version`。响应拦截：`code===1` 成功返回 `data`（可 `uni.$u.toast`）；`code===0` 失败处理；`code===-1` 或 `TOKEN_INVALID` 执行 `handleTokenTimeout`（清空 token 并 `reLaunch` 登录页）。 | [`src/utils/request/index.ts`](know-uniapp/src/utils/request/index.ts) |
| `http.ts` | `HttpRequest` 类：`get/post/put/delete/uploadFile/request`，超时重试，支持 `cancel`（去重映射）。 | [`src/utils/request/http.ts`](know-uniapp/src/utils/request/http.ts) |
| `cancel.ts` | 请求取消/去重逻辑。 | [`src/utils/request/cancel.ts`](know-uniapp/src/utils/request/cancel.ts) |
| `type.d.ts` | `RequestConfig` 类型定义。 | [`src/utils/request/type.d.ts`](know-uniapp/src/utils/request/type.d.ts) |

### 8.2 基础配置

[`src/config/index.ts`](know-uniapp/src/config/index.ts)：

```ts
// 溯源：src/config/index.ts（要点）
version: '1.9.0',
baseUrl: import.meta.env.VITE_APP_BASE_URL || 'http://101.37.83.88:9191',
customerBaseUrl: import.meta.env.VITE_APP_CUSTOMER_BASE_URL || 'http://101.37.83.88:9191',
serviceMap: { java: '/plan', python: '/python', customer: '/customer' },
timeout: 60000
```

- 环境变量前缀 `VITE_APP_*`（Vite）。
- 请求拦截会根据 URL 前缀决定是否追加 `urlPrefix: 'api'`（`/python/`、`/customer/` 跳过）。

### 8.3 API 模块组织与命名

- 按业务域划分：`api/plan/*.ts`（schedule/habit/slogan/home/template/focus/habit-template/event-template）、`api/system/*`（menu/cascade/appversion...）、`api/biz/industry/*`、`api/python/*`，扁平模块如 `auth.ts/user.ts/camera.ts/customer.ts/shop.ts/pay.ts/recharge.ts/news.ts/account.ts/app.ts/wifi.ts`。
- 导入：`import request from '@/utils/request'`
- 命名：动词+实体，分页用 `getXxxPage`，列表用 `getXxxList`，详情 `getXxxDetail`，新增 `addXxx`，修改 `updateXxx`，删除 `deleteXxx`。
- 使用对象参数：`request.get({ url: '/plan/event/list', data: params })`。
- 中文注释常见（JSDoc 风格）。

**示例（溯源）**：[`src/api/plan/slogan.ts`](know-uniapp/src/api/plan/slogan.ts)

```ts
import request from '@/utils/request'

export function getSloganPage(params: any) {
  return request.get({ url: '/plan/slogan/page', data: params })
}
export function getSloganList(params?: any) {
  return request.get({ url: '/plan/slogan/list', data: params })
}
export function addSlogan(data: any) {
  return request.post({ url: '/plan/slogan/add', data })
}
export function updateSlogan(data: any) {
  return request.post({ url: '/plan/slogan/edit', data })
}
export function deleteSlogan(id: string | number) {
  return request.post({ url: '/plan/slogan/delete', data: { id } })
}
```

### 8.4 规范要点

- 统一使用封装的 `request`，不要直接 `uni.request`。
- 鉴权：`withToken: true` 默认，登录超时/失效走 `handleTokenTimeout`（清空并跳转登录）。需登录页路径与路由守卫保持一致（[`router/index.ts`](know-uniapp/src/router/index.ts)）。
- 重试：默认 `retryCount: 2`，超时触发重试（见 `http.ts`）。
- 去重/取消：使用 `request` 的取消能力避免重复请求（`cancel.ts`）。
- Python 接口走 `/python/*` 前缀（拦截器不追加 `api` 前缀）。

参见[附录：API 模块最小示例](#推荐api-模块示例srcapiplansamplets)。

---

## 9. 状态管理、hooks、mixins、enums、types

### 9.1 Pinia Stores

| Store | 用途 | 溯源 |
|---|---|---|
| `user.ts` | 用户信息、token、登录态、权限相关 | [`src/stores/user.ts`](know-uniapp/src/stores/user.ts) |
| `app.ts` | 应用配置、菜单（公共/用户菜单）、tabbar、网站配置、H5 配置等 | [`src/stores/app.ts`](know-uniapp/src/stores/app.ts) |
| `dict.ts` | 字典数据加载与缓存 | [`src/stores/dict.ts`](know-uniapp/src/stores/dict.ts) |
| `theme.ts` | 主题状态（§7.2） | [`src/stores/theme.ts`](know-uniapp/src/stores/theme.ts) |
| `appVersion.ts` | 版本检测相关 | [`src/stores/appVersion.ts`](know-uniapp/src/stores/appVersion.ts) |

**规范**：store 文件 `useXxxStore` 导出，state/ getters/actions 明确。持久化用 `uni.setStorageSync/getStorageSync`（如 theme、token 相关由 `auth.ts`/store 共同处理）。

### 9.2 Hooks（Composables）

| Hook | 用途 | 溯源 |
|---|---|---|
| `useLockFn` | 防抖/锁定异步函数（避免重复点击） | [`src/hooks/useLockFn.ts`](know-uniapp/src/hooks/useLockFn.ts) |
| `useHoverEffect` | H5 悬停动效（底栏等使用） | [`src/hooks/useHoverEffect.ts`](know-uniapp/src/hooks/useHoverEffect.ts)（[`PremiumBottomNav.vue:333`](know-uniapp/src/components/PremiumBottomNav.vue#L333) 调用） |
| `useCopy` | 复制文本 | [`src/hooks/useCopy.ts`](know-uniapp/src/hooks/useCopy.ts) |
| `useAppVersion` | APP 版本检查（强制/可选更新） | [`src/hooks/useAppVersion.ts`](know-uniapp/src/hooks/useAppVersion.ts)、[`App.vue:74-79,106-109`](know-uniapp/src/App.vue#L74-L79) |

### 9.3 Mixins

| 文件 | 说明 | 溯源 |
|---|---|---|
| `mixins/index.ts` | `setupMixin(app)` 注册全局 mixin | [`src/mixins/index.ts`](know-uniapp/src/mixins/index.ts) |
| `mixins/theme.ts` | 注入 `$theme` 计算属性 | [`src/mixins/theme.ts`](know-uniapp/src/mixins/theme.ts) |

**建议**：新功能优先使用 `hooks/`（Composition API）替代传统 mixin。

### 9.4 Enums

集中维护常量枚举：

| 文件 | 说明 | 溯源 |
|---|---|---|
| `enums/requestEnums.ts` | `ContentTypeEnum`、`RequestMethodsEnum`、`RequestCodeEnum`（`SUCCESS=1`、`FAILED=0`、`TOKEN_INVALID=-1`）、`RequestErrMsgEnum`（`ABORT/TIMEOUT`） | [`src/enums/requestEnums.ts`](know-uniapp/src/enums/requestEnums.ts) |
| `enums/appEnums.ts` | `ThemeEnum`、`ClientEnum`、`SMSEnum`、`SearchTypeEnum`、`FieldType`、`PayStatusEnum`、`PageStatusEnum` | [`src/enums/appEnums.ts`](know-uniapp/src/enums/appEnums.ts) |
| `enums/constantEnums.ts` | `TOKEN_KEY='token'`、`TOKEN_NAME`、`HISTORY`、`BACK_URL`、`PAY_STATUS_EVENT` | [`src/enums/constantEnums.ts`](know-uniapp/src/enums/constantEnums.ts) |
| `enums/agreementEnums.ts` | 协议相关枚举 | [`src/enums/agreementEnums.ts`](know-uniapp/src/enums/agreementEnums.ts) |

### 9.5 Types

- 组件内类型用 `interface/type`。
- 跨模块复用类型放置 `src/types/`。
- 补充声明：[`src/types/shims-prism.d.ts`](know-uniapp/src/types/shims-prism.d.ts)。
- 请求配置类型：[`src/utils/request/type.d.ts`](know-uniapp/src/utils/request/type.d.ts)。

---

## 10. 代码风格

### 10.1 工具配置

| 配置文件 | 说明 | 溯源 |
|---|---|---|
| `.eslintrc.js` | ESLint 配置（Vue 3 + TS）。脚本：`eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix --ignore-path .gitignore` | [`know-uniapp/.eslintrc.js`](know-uniapp/.eslintrc.js)、[`package.json:35`](know-uniapp/package.json#L35) |
| `.prettierrc` | Prettier 格式化配置 | [`know-uniapp/.prettierrc`](know-uniapp/.prettierrc) |
| `.editorconfig`（如存在） | 编辑器统一风格 | 检查根目录：[`know-uniapp/.editorconfig`](know-uniapp/.editorconfig)（如有） |

### 10.2 语言与语法

- **TypeScript 严格模式**：`tsconfig.json` 启用 `strict`，优先使用类型而非 `any`。确有必要时标注原因。
- **Vue SFC**：`<script setup lang="ts">`，组件名、prop/emits 明确。
- **条件编译**：跨平台差异用 `#ifdef/#ifndef/#endif`（H5、APP-PLUS、小程序等），如 [`App.vue:22-29,140-161`](know-uniapp/src/App.vue)、[`pages.json:57-76`](know-uniapp/pages.json)。
- **路径别名**：统一 `@/` 引入（`tsconfig.json` + Vite）。
- **ESM**：模块统一 `import/export`。

### 10.3 命名约定

| 范围 | 约定 | 示例 |
|---|---|---|
| 组件文件 | PascalCase 或 kebab-case，目录式时主文件同名 | `PremiumBottomNav.vue`、`cascade/CascadePicker.vue` |
| 页面文件 | kebab-case 路径：`pages/<module>/<name>.vue` | `pages/plan/slogan/index.vue` |
| API 函数 | `get/add/update/delete + 实体` | `getSloganList`、`addSlogan` |
| Store | `useXxxStore` | `useThemeStore`、`useUserStore` |
| Composables | `useXxx` | `useLockFn`、`useHoverEffect` |
| 常量/枚举 | 大写或 PascalCase 枚举 | `TOKEN_KEY`、`RequestCodeEnum.SUCCESS` |
| CSS 类名 | kebab-case（业务类常用 `premium-*`、`page-*`） | `.premium-card`、`.page-title` |
| 变量/函数 | camelCase | `heroSubline`、`loadSlogan` |

### 10.4 样式约定

- 单位：小程序/rpx 体系，PostCSS 将 `rem` 转 `rpx`（**仅非 H5**，比例 `$1rem=32rpx`，见 [`postcss.config.js`](know-uniapp/postcss.config.js)）。H5 端保留 rem 语义。
- 主题：严禁硬编码色值，优先使用 CSS 变量（`var(--color-*)`）或 Tailwind 映射（`tailwind.config.js` 将颜色映射到 CSS 变量）。
- scoped：页面/组件样式加 `scoped`。
- 全局类：复用类定义在 `styles/` 对应文件（`premium.scss`、`public.scss` 等）。

### 10.5 注释与可维护性

- 复杂逻辑添加必要注释（中文注释在项目中较常见，如 [`request/index.ts`](know-uniapp/src/utils/request/index.ts)、[`PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue)）。
- 避免直接修改遗留文件（如 `index-v1.vue`）除非明确影响范围。
- **保持主题双轨一致**：修改 `themes.scss` 时同步检查 `stores/theme.ts` 的 `THEME_COLORS` 映射。

---

## 11. 构建与运行

### 11.1 NPM Scripts（溯源：`package.json`）

| 脚本 | 用途 | 说明 |
|---|---|---|
| `dev` | 通用开发（脚本驱动） | `node scripts/develop.js` |
| `dev:h5` | H5 开发 | `uni`（Vite） |
| `dev:mp-weixin` 等 | 各小程序开发 | `uni -p mp-*` |
| `dev:app` | App 开发（云打包/本地） | `uni -p app` |
| `build` | 通用构建（脚本驱动） | `node scripts/publish.js` |
| `build:h5` | H5 构建 | `uni build && node scripts/release.mjs` |
| `build:mp-*` | 小程序构建 | `uni build -p mp-*` |
| `build:app` | App 构建 | `uni build -p app --mode app` |
| `lint` | 代码检查修复 | `eslint . --ext ... --fix` |

### 11.2 构建脚本

| 脚本文件 | 说明 | 溯源 |
|---|---|---|
| `scripts/develop.js` | 开发环境启动脚本 | [`know-uniapp/scripts/develop.js`](know-uniapp/scripts/develop.js) |
| `scripts/publish.js` | 发布构建脚本 | [`know-uniapp/scripts/publish.js`](know-uniapp/scripts/publish.js) |
| `scripts/release.mjs` | H5 发布后处理（`build:h5` 后执行） | [`know-uniapp/scripts/release.mjs`](know-uniapp/scripts/release.mjs) |

### 11.3 环境配置

- Vite 环境变量：`VITE_APP_BASE_URL`、`VITE_APP_CUSTOMER_BASE_URL` 等（见 `config/index.ts`）。
- `.env*` 文件：项目根含 `.env.app` 等（[`know-uniapp/.env.app`](know-uniapp/.env.app)），按 uni-app/Vite 规范使用。
- H5 基路径：`/mobile/`（`vite.config.ts` base + `manifest.json` history base）。

### 11.4 开发建议

- 本地开发推荐 `pnpm/npm/yarn` 安装依赖（根目录含 [`package-lock.json`](know-uniapp/../package-lock.json) 等）。
- H5 开发端口 `8991`，代理已配置（§1.2）。
- 变更样式时注意 PostCSS rem→rpx 仅非 H5 生效。
- 构建前建议运行 `lint` 保持风格一致。

---

## 附录：不一致点清单

基于实证整理，**强烈建议在规范中明确并处理**：

| 编号 | 不一致点 | 影响 | 建议处理 |
|---|---|---|---|
| INC-01 | [`var.css`](know-uniapp/src/styles/var.css) **为空（0 字节）**，实际变量在 [`themes.scss`](know-uniapp/src/styles/themes.scss)+[`variables.scss`](know-uniapp/src/styles/variables.scss)。 | 容易误导新同学引用空文件。 | 在规范中**禁止**引用 `var.css`，统一使用 `themes.scss` 体系。可考虑删除或补充说明。 |
| INC-02 | 主题双轨注入：H5 用 `html[data-theme]`（`themes.scss`），非 H5 用 `page { v-bind(themeInlineVars) }`（[`App.vue:140-161`](know-uniapp/src/App.vue)），且 [`stores/theme.ts`](know-uniapp/src/stores/theme.ts) 的 `THEME_COLORS` 需与 `themes.scss` 同步。 | 平台间主题可能漂移（色值不一致）。维护成本高。 | 建立**单一事实源**（首推 `themes.scss`），由构建/脚本生成 `THEME_COLORS` 或增加校验（比对键名/关键色值）。变更主题时必须两处同步。 |
| INC-03 | [`index-v1.vue`](know-uniapp/src/pages/index/index-v1.vue) 为**遗留旧版首页**，当前主逻辑用 [`index.vue`](know-uniapp/src/pages/index/index.vue)。 | 容易误改旧文件、产生混淆。 | 规范中标注“遗留文件，不参与当前首页规范”，明确弃用状态。必要时移除或加 `@deprecated` 注释。 |
| INC-04 | `easycom` 映射 `^w-(.*)` → `@/components/widgets/$1/$1.vue`，但 [`widgets/ThemeSwitcher.vue`](know-uniapp/src/components/widgets/ThemeSwitcher.vue) 为**平铺文件**而非目录包裹。 | 按此映射使用 `w-themeswitcher` 将找不到主文件。 | 统一 widget 结构：**每个 widget 建立 kebab-case 目录，主文件 `目录名.vue`**（或调整 easycom 为同时支持平铺）。当前项目中实际使用方式需核对。 |
| INC-05 | 标语快照 [`slogan-page-snapshot.md`](know-uniapp/../slogan-page-snapshot.md) 描述“支持设置生效时间窗”（startTime/endTime），**现代码无此字段**（表单仅 content/emoji/sort/status）。 | 若按快照撰写规范会引入虚假规则。 | **严禁照抄**，明确“当前实现未支持生效时间窗，仅支持 content/emoji/sort/status”。 |
| INC-06 | 自定义 tabbar 多套实现并存：[`PremiumBottomNav.vue`](know-uniapp/src/components/PremiumBottomNav.vue)、[`custom-tab-bar/index.vue`](know-uniapp/src/components/custom-tab-bar/index.vue)、[`tabbar/*`](know-uniapp/src/components/tabbar) 等。 | 容易选型混乱、样式不一致。 | 规范推荐统一使用 **PremiumBottomNav.vue**（远程菜单+权限+路径归一化+登录校验），新页面不要引入其他实现。 |

---

## 附录：推荐模板/示例（最小可用）

> 以下模板基于项目实际风格（`<script setup lang="ts">`、`@/` 别名、请求封装、CSS 变量）编写。路径均相对于 `know-uniapp/`。

### 推荐页面模板：`src/pages/plan/x/index.vue`

```vue
<template>
  <view class="page-slogan">
    <!-- 顶部导航（自定义） -->
    <u-navbar :title="title" :autoBack="true" bgColor="transparent" />
    <view class="container">
      <!-- 列表渲染（z-paging 用法按项目实际调整） -->
      <view class="list" v-for="item in list" :key="item.id">
        <view class="item">
          <text class="emoji">{{ item.emoji }}</text>
          <text class="content">{{ item.content }}</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, onShow } from '@dcloudio/uni-app'
import { getXxxList } from '@/api/plan/sample'

const title = ref('示例页面')
const list = ref<any[]>([])

const loadData = async () => {
  try {
    const res = await getXxxList({ status: 1 })
    list.value = res?.rows || res?.data || []
  } catch (e) {
    console.error(e)
  }
}

onShow(() => {
  loadData()
})
</script>

<style scoped lang="scss">
.page-slogan {
  min-height: 100vh;
  background: var(--color-bg-app);
  color: var(--color-text);
}
.container {
  padding: 24rpx;
}
</style>
```

### 推荐组件模板：`src/components/my-comp/my-comp.vue`

```vue
<template>
  <view class="my-comp" :class="{ active }">
    <text class="label">{{ label }}</text>
    <slot />
  </view>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  active?: boolean
}>()
</script>

<style scoped lang="scss">
.my-comp {
  display: flex;
  align-items: center;
  gap: 12rpx;
  color: var(--color-text-secondary);
  transition: color var(--duration) var(--ease);
  &.active {
    color: var(--color-primary);
  }
}
</style>
```

> **注意**：若组件要通过 `easycom` 的 `w-*` 方式使用，建议改为**目录包裹**：`src/components/widgets/my-comp/my-comp.vue`，方可用 `<w-my-comp>`（映射规则见 §3）。

### 推荐 API 模块示例：`src/api/plan/sample.ts`

```ts
import request from '@/utils/request'

export function getXxxPage(params: any) {
  return request.get({ url: '/plan/xxx/page', data: params })
}
export function getXxxList(params?: any) {
  return request.get({ url: '/plan/xxx/list', data: params })
}
export function addXxx(data: any) {
  return request.post({ url: '/plan/xxx/add', data })
}
export function updateXxx(data: any) {
  return request.post({ url: '/plan/xxx/edit', data })
}
export function deleteXxx(id: string | number) {
  return request.post({ url: '/plan/xxx/delete', data: { id } })
}
```

### 推荐 section-config 条目示例：`src/config/sample-sections.ts`

```ts
import type { UniFieldDef, UniSectionDef } from './industry-sections' // 复用类型

export const sampleSections: UniSectionDef[] = [
  {
    title: '基础信息',
    defaultOpen: true,
    fields: [
      { label: '名称', key: 'name', type: 'text', required: true, placeholder: '请输入（必填）' },
      { label: '备注', key: 'remark', type: 'textarea', required: false, placeholder: '请输入（选填）' }
    ]
  }
]
```

> 约定：`placeholder` **必须**包含“（选填）”或“（必填）”说明（溯源：[`industry-sections.ts`](know-uniapp/src/config/industry-sections.ts)）。

### 推荐 themed style 示例

基于全局主题变量（不硬编码色值）：

```scss
.hero-subline {
  font-size: 26rpx;
  color: var(--color-text-secondary);
  background: linear-gradient(135deg, var(--color-primary), var(--color-minor));
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
.card {
  background: var(--color-surface);
  border: 1rpx solid var(--color-border-light);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}
```

> 切换主题时上述样式随 CSS 变量自动更新（H5 依赖 `html[data-theme]`，非 H5 依赖 `page` 内联变量）。

---

**结语**：本规范严格遵循“**实证优先**”原则——所有规则、路径、代码片段均来自仓库真实文件。变更代码前请先查阅对应溯源文件，避免引入与现状不符的约定。
# 12 · Design System / Component Spec

> 组件**职责表**。实现细节与 token 表：`Design/Platform*.swift`、历史 `DESIGN_SYSTEM.md`。

---

## 1. 组件分层

| 层 | 例子 | 谁调用 |
|----|------|--------|
| 系统 | `Button`、`Form`、`List`、`Label`、`ContentUnavailableView` | Features 直接 |
| Platform chrome | `platformTabRoot*`、`platformSheet*`、`platformFeedback*` | Features |
| 货架 / 媒体 | `HeroMediaCard`、`PlatformCatalog*`、`DiscoverBrowse*` | 发现 Features |
| 活动 CTA | `activityPrimaryCTA` / Secondary、`ActivityPrimaryAction` | 活动 Features |
| Zoom | `ActivityZoomNavigationLink` 等 | 发现 / 列表 |
| 凭证 | `ActivityJourneyCredentialFace`、PassKit 按钮 | Profile / 行程 |

Features **优先调组件**，不复制卡片内边距魔法数。

---

## 2. 核心组件职责

| 组件 / Helper | 职责 | 非职责 |
|---------------|------|--------|
| `platformTabRootScrollChrome` / `ListChrome` | 五 Tab 根：`navigationTitle` + `.inlineLarge` + soft edge + 栏材质自动显隐 | 手绘顶栏；滚动页眉；`navigationSubtitle`；scroll-away；回顶令牌 |
| `platformTabRootToolbar` | Trailing 工具项；与 `ToolbarItemGroup` / `ToolbarSpacer` / `.badge` 组合 | 空 principal 压制 compact title |
| `platformNavigationBarItemChrome` | 导航栏图标系统 `.primary`，隔离页面品牌 tint | 内容区 CTA / Tab tint |
| `platformTabRootTitleMenu` | 活动分类 / 搭子模式 `toolbarTitleMenu` | 其它 Tab 强行加菜单 |
| `discoverBrowseContentInset` / `DiscoverHorizontalRail` | 发现唯一水平 gutter（= `contentInset`） | Features 再叠一层水平 padding |
| `platformConversationListChrome` / `communityFeedChrome` | 消息/广场 plain List 页边与行密度 | 手写 `EdgeInsets(8,16,…)` |
| `PlatformFormControlListRow` / `PlatformGroupedPromoListRow` | Form 控件行 / grouped 全宽宣传行 insets（备用） | 「我的」会员入口用服务区列表行，勿再加顶栏促销条 |
| `PlatformMetrics` | 系统读不到的几何 token | Features 随手 padding 词典 |
| `PlatformSurface` | 语义填充色 | 业务状态色逻辑 |
| `platformFullBleedMediaFormRow` | Form 内清 inset 全宽媒体 | 普通文本行 |
| `platformFormRelatedRailRow` | 负 inset 横滑轨 | 垂直列表 |
| `platformOverlayMaterialFill` | 浮层列表底（地图搜索） | 整页背景 |
| `platformMediaInfoBarChrome(_:)` | 封面底栏完整构建（inset + 角色 Material） | 旁路手写 Material；搭子人像发现卡 |
| `PlatformMediaInfoBarStyle` | `.hero` / `.standard` / `.compact` | Features 内自选厚度魔法 |
| `BuddyPersonBrowseChrome` | 人像发现卡共用内容槽；`density`：`.hero` / `.grid`；行数走 `DiscoverAccessibility`；陪玩主动词「预约」 | 卡比例与轨框 |
| `BuddyPersonBrowseContextMenu` | 长按：联系 / 预约 / 分享 | 卡内按钮墙 |
| `BuddyBrowseFilterMenuContent` / `BuddiesModeSwitchToolbar` | 三模式分流 L1 筛选 Menu；无系统搜索框 | 三模式共用同一套条件；Sheet 搜 + Trailing 放大镜双入口 |
| `BuddyPickCard` / `BuddyGridCard` / `BuddyPaidTopCard` | 辅卡：浏览密度；无卡内强 CTA；进 Zoom 再约 | 精选 Hero / 卡内报名按钮 |
| `BuddyFeaturedCard` / `BuddyFeaturedSpotlightSection` | 精选 Hero：`.hero` + 主 CTA；无障碍竖排 | 活动 Material 底栏叠字 |
| `BuddyPaidLeaderboard` | Top3 + 查看全部 + 快捷条；不同池复述完整榜 | Top3 与同池榜行并陈 |
| `ActivityCardStatus` | 发现/详情动作词表 | 长文案段落 |

---

## 3. CTA 规则

- 每屏**一个** prominent 主操作。  
- 已参加 / 已候补：disabled secondary chip（`ActivityStatusChip`）。  
- 满员：主按钮变为候补，不禁用误导。  
- 支付主按钮受 `CommercePaymentPolicy.checkoutMethods` 约束。

---

## 4. 新增组件清单

新增 Platform 组件前：

1. 系统控件是否已够用？  
2. 是否属于发现几何（进 Metrics）还是 Form（别封装）？  
3. Reduce Transparency / Dynamic Type 是否处理？  
4. 是否写入本表与 `05` 反模式不冲突？  

---

## 5. 组件 API 约定

| 约定 | 说明 |
|------|------|
| 命名 | `platform*` modifier / `Platform*` 类型；业务组件用域前缀（`Activity*`） |
| 入参 | 尽量值类型 + 明确闭包；避免组件内偷偷读全局单例 |
| 样式 | 颜色走 `PlatformSurface` / `PlatformStatus` / 系统 `AccentColor`；禁止组件私有色板 |
| 几何 | 系统读不到的数进 `PlatformMetrics`；组件外禁止复制魔法数 |
| 可访问性 | 装饰性 `accessibilityHidden`；交互控件必有 label |
| 预览 | 复杂 Platform 组件提供 `#Preview`；业务态用假数据勿依赖 Keychain |

---

## 6. Token 变更治理

1. 改 token → 同步调用方与 `05` 原则（若改语义）  
2. 不在 Feature 用「临时让我过」的本地色/间距绕过 token  
3. `DESIGN_SYSTEM.md` 为附录：冲突时改代码 + `05`/`12`，再回写附录  

---

## 7. 与旧 DESIGN_SYSTEM.md

`DESIGN_SYSTEM.md` 仍可作为**详尽视觉附录**。  
**规范裁决**：`Project/05` + `Project/12`；实现冲突时改代码与这两份，再回写附录。

---

*下一篇：[13_ACCESSIBILITY_SPEC.md](13_ACCESSIBILITY_SPEC.md)*

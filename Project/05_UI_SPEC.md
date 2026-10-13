# 05 · UI / 视觉规范（UI Spec）

> 气质与反模式。Token 实现见 `Design/Platform*.swift`；组件职责见 `12`。

---

## 1. 视觉气质

| 灵感 | 落点 |
|------|------|
| App Store Today | 发现分区、横滑轨、Hero |
| Photos | 顶栏 glass、Zoom |
| Settings | 详情 Form |
| Apple Music | 留白、少装饰 |
| PassKit | 行程凭证 / Wallet |

**一句话**：系统语义色 + 系统 AccentColor；发现沉浸、详情克制。

---

## 2. 颜色

| 用途 | 规则 |
|------|------|
| 强调色 | 系统 `Color.accentColor` / 环境 tint（`PlatformAction.brandAccent` 仅为别名） |
| 表面 | `PlatformSurface.*`（grouped / canvas / elevated / tertiaryFill / accentSoftFill） |
| 状态 | `PlatformStatus`（success / warning / danger / accent） |
| 禁止 | 自定义 HSB 紫挂 `.tint`；紫系装饰风、奶油纸质风、报纸排版风 |

登录微信绿等**渠道品牌色**属刻意例外，不得扩散到活动 Form。

---

## 3.1 Tab 根顶栏

五 Tab 共用 `platformTabRootScrollChrome` / `ListChrome` + `platformTabRootToolbar`（见 `11` / `12`）：

- `.inlineLarge` + soft edge + 系统导航栏材质联动  
- Trailing：`ToolbarItemGroup` + `ToolbarSpacer` 分组；筛选生效换顶栏 SF Symbol（当前主条件图标，无角标）；好友请求等计数仍可用 `.badge`；图标 `.platformNavigationBarItemChrome()`（系统 `.primary`）  
- **不**挂自定义 clover `.tint`；主按钮跟随系统 AccentColor  
- **不**手绘 NavigationBar；**不**用空 principal 压制 compact title；**不**提供 scroll-away / `navigationSubtitle` / 回顶令牌  
- 活动：额外 `toolbarTitleMenu`（系统 leading 标题菜单）；搭子：模式切换在 Trailing Menu（筛选右侧）  

## 3. 字体

- 只用系统 Text Style（`.largeTitle` … `.caption2`），跟随 Dynamic Type。  
- 禁止项目自定义字阶枚举、固定 pt。  
- 数字时间可用 `monospacedDigit()`。

---

## 4. 布局节奏

| 页面类型 | 谁管间距 |
|----------|----------|
| Form / List / Sheet 设置感 | 系统行距、`controlSize`、`listSectionSpacing`；默认不手写整页 padding |
| 发现货架 | Design 组件 + `PlatformMetrics`（比例、轨、分区节奏） |
| 全宽媒体 Form 行 | `platformFullBleedMediaFormRow()` |
| 相关横滑 Form 行 | `platformFormRelatedRailRow()` |

### 4.1 五 Tab 根 · 间距骨架（HIG）

水平页边**同源**：`PlatformMetrics.contentInset`（系统 subtitleCell leading）。  
**不**追求五 Tab 同一套 row spacing；按容器分型。

| Tab | 容器 | 水平页边 | 垂直节奏 | Features 禁止 |
|-----|------|----------|----------|---------------|
| 活动 | Scroll 货架 | 仅 `discoverBrowseContentInset` / Rail `contentMargins`；标题 `DiscoverSectionTitleRow` 一条 gutter | 外层 `VStack(spacing: 0)` 锚点 + 内层 `LazyVStack(spacing: sectionSpacing)`（**发现专用**） | 再手写水平魔法 padding；标题+内容双重页边；锚点与首块同处 `sectionSpacing` 栈；把 List 行距套进货架 |
| 搭子 | 同上 | 同上 | 同上（与活动同构） | 同上 |
| 消息 | plain List | `platformConversationListChrome` contentMargins；行距 subtitleCell；Features **只用** `PlatformMessagesChrome` / `PlatformConversationListRow`；空态 `ContentUnavailableView` 裸 Button | 旁路 `listRowInsets(…contentInset…)`；发现 `railCardSpacing`；空态再叠业务 CTA 皮 / `emptyStateVerticalPadding` |
| 广场 | plain List / Detail Scroll | `communityFeedChrome` / `communityDetailScrollChrome` → `PlatformConversationListRow.horizontalInset` | Feed：`listSectionSpacing` + 卡内 `communityRowToContentSpacing` / `communityInlineSpacing`；行栈禁止默认 `VStack`/`HStack` spacing；Leading 走系统 Dynamic Type，**不**设 `.lineSpacing` | 旁路魔法 inset；行与 List `contentMargins` 双重水平缩进；embedded 评论再叠 `contentInset` |
| 我的 | 根 = Scroll 货架（与活动/搭子同构）；二级 insetGrouped | 根：`discoverBrowseContentInset` / `discoverBrowsePageColumn`；二级 Settings 同族 `profileSecondaryListChrome`（默认**非** compact）；库页 `profileLibraryBrowseChrome` | 根：外层 `VStack(spacing: 0)` + 内层 `VStack(sectionSpacing)`（**勿**再套 Lazy；四档内才 `LazyVGrid`/`LazyVStack`）+ `scrollBounceBehavior(.basedOnSize)`；二级 `platformTabRootListChrome` 仅非根 | 根嵌套双 Lazy 滑动卡死；根再叠手写分节距；二级强制 `.compact`；营销头双重水平页边 |

品牌色：系统 AccentColor；**禁止**内容区挂自定义 clover `.tint`。

刻意边距必须有 token：`mediaChromeInset`、`heroStackedTextInset` / `captionBadgeInset`（卡内，系统列表 margin 推导）、`mementoShareExportWidth` / `mementoShareCornerRadius`、`avatarStackSpacing`、`successIllustration*` 等。

**浏览卡点按（活动 / 搭子 / 广场统一）：** 活动·搭子封面 Zoom 进详情。广场：正文 `NavigationLink`→帖详情；**媒体**用系统 `TabView` `.page` 左右滑，**双击点赞**（反馈落到互动栏 `symbolEffect(.bounce)`），**禁止**点图 / 计数芯片进全屏预览（详情头图同规，仅分页滑动）。作者行：副文 `conversationListTime`（消息列表同桶）；关注 = 系统 glass CTA（未关注 prominent / 已关注 secondary，`controlSize: .mini`）。筛选 chip：List 首 Section 随滚（对齐通知中心），不钉第二顶栏。

发现卡比例（不得混用）：

| 品类 | Token | 比例 |
|------|-------|------|
| 活动焦点 / 跟进横卡 | `editorialCardAspectRatio` | 16:9 |
| 活动精选 Hero | `featuredCardAspectRatio` | 4:5 全宽；`ActivityFeaturedCard` + Material 底栏 |
| 广场帖媒体 | `communityMediaAspectRatio`（= `featuredCardAspectRatio`） | Feed / 详情 4:5；圆角 `mediaShape` |
| 搭子精选 Hero | `personFeaturedCardAspectRatio`（= 活动 4:5） | 全宽单卡；图下文案；`.hero`；常规字阶文案+CTA 横排；**无障碍字阶 CTA 全宽竖排**；主动词「预约」 |
| 搭子货架 editorial / 网格 / 榜 Top / 榜行 | `personGridCardAspectRatio` / `posterCardAspectRatio` | 3:4 或列表行；`.grid`；无卡内强 CTA；点封面/行进 Zoom；**每模式辅轨 ≤1**；陪玩榜仅 Top3+查看全部 |

活动 / 场景横卡可用 `platformMediaInfoBarChrome()`。  
**搭子人像发现卡禁止**封面底栏叠字（Material 或自绘 scrim）；角标可保留在封面上。  
图下文案时**只对封面** `clipShape`，勿裁切整卡（避免圆角吃掉系统 Text）。  
圆角走 `cardShape`（`radiusCard` ← body 网格）。  
搭子发现页滚动：`contentMargins` / `scrollTargetBehavior(.viewAligned)`（横滑轨）、`scrollBounceBehavior(.basedOnSize)`、`scrollEdgeEffectStyle(.soft)`、系统 `.refreshable`。  
搭子发现：**禁止**外层「找搭子/约陪玩/俱乐部」再包一层分区标题（空态除外）；货架标题只保留一层。  
搭子筛选：三模式均有 Trailing Menu（即时 L1）+「更多筛选…」，条件分流——**找搭子**排序/性别 + 深筛地区·距离·兴趣；**约陪玩**排序/仅可约/服务类型/性别 + 深筛地区·距离；**俱乐部**排序/主题 + 深筛城市。**不**挂 Tab 根 `.searchable`；生效时 Toolbar a11y value 按模式摘要。

---

## 5. 材质与阴影

- 媒体信息栏：`platformMediaInfoBarChrome(_ style:)`（见下表）；降透 → `secondarySystemBackground`。  
- 工具栏：`.bar` / glass 系统样式。  
- **默认无自定义多层阴影 / glow**。  
- Reduce Transparency：退化为不透明系统底。

| `PlatformMediaInfoBarStyle` | Material | 场景 |
|-----------------------------|----------|------|
| `.hero` | `.ultraThinMaterial` | Featured、Editorial |
| `.standard` | `.thinMaterial` | 发现流大卡、Continue / Event 横卡 |
| `.compact` | `.bar` | Poster 榜单 |

---

## 6. UI 反模式（禁止）

- 手写 toast  
- 自定义 disclosure chevron  
- 业务魔法数 padding  
- 详情穿状态栏全幅沉浸（精选发现除外）  
- 「消灭 Metrics」导致货架退回裸数字  

---

*下一篇：[06_PLATFORM_SPEC.md](06_PLATFORM_SPEC.md)*

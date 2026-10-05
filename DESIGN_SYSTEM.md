# 坐标系 Design System（视觉附录）

> **裁决**：原则与组件职责以 [`Project/05_UI_SPEC.md`](Project/05_UI_SPEC.md) + [`Project/12_COMPONENT_SPEC.md`](Project/12_COMPONENT_SPEC.md) 为准；冲突时改代码与这两份，再回写本文。  
> **本文角色**：像素级 token / 组件长文的**实现附录**，不是现行总规范。  
> 原则：**Apple 原生 · SwiftUI First · HIG · App Store Today 编排 · Apple TV 沉浸 · Apple Music 留白**。  
> 系统级：**业务少决策、多交给系统容器**；命名间距留给 Design 与系统读不到的几何，不是追求零 Metrics。  
> 实现源码锚点：`Design/PlatformSemantics.swift`（语义色）、`Design/PlatformMetrics.swift`、`Design/PlatformChromeMeasurements.swift`（运行时控件边长）、`Design/PlatformListAvatar.swift`、`Design/PlatformToolbarChrome.swift`、`Design/PlatformConversationListChrome.swift`、`Design/PlatformActivityChrome.swift` / `PlatformActivityChipsBadges.swift`、`Design/PlatformMessagesChrome.swift`、`Design/PlatformCatalogCardChrome.swift` / `ContinueCards` / `PosterCard` / `EditorialCard`、`Design/PlatformMediaLegibility.swift`、`Design/ActivityZoomNavigation.swift`、`Design/WalletPassFace.swift` / `WalletPassFaceChrome.swift` / `WalletPassFaceContent.swift` / `WalletPassFaceFactory.swift`、`Design/WalletPaymentCardFace.swift`、`Design/CredentialArt/**`、`Features/Activities/**`、`Features/Profile/Credential/**`、`Features/Profile/ProfileCredentialCards.swift`、`Features/Profile/ProfileCredentialFolderViews.swift`、`Features/Profile/ActivityCredentialExpandedView.swift`、`Services/PassKit/**`。

---

# 1 Design Philosophy

## 1.1 一句话

用系统组件与系统语义，把「发现一场局 → 读懂 → 参加」做成 iPhone 上最自然的路径。

**系统级定义：** 业务少决策、多交给系统容器；不是删掉所有命名间距。

## 1.2 产品气质

| 灵感来源 | 在坐标系中的落点 |
|---------|------------------|
| **App Store Today** | 发现页分区货架、横滑轨、榜单海报、焦点大卡 |
| **Apple TV** | 精选全宽沉浸、媒体穿顶、玻璃顶栏浮在内容上 |
| **Apple Music** | 大留白、少装饰、分区节奏疏朗、转化区信息克制 |
| **Photos** | 两侧圆形 glass + 中间双行胶囊顶栏；Zoom 进详情 |
| **Settings / Form** | 详情用系统 Form；「钱包」为首屏 ID-1 数字卡（`WalletCardArt` 卡面 + 轻遮罩）+ 最近交易；不挂假支付网络标 |
| **PassKit（内部）** | App 内凭证 / 票面；**不**提供「加入 Apple Wallet」；DEBUG 可导出未签名包 |

## 1.3 硬性约束

1. **SwiftUI First**：布局、导航、材质、动效优先系统 API。  
2. **官方组件优先**：`NavigationStack`、`TabView`、`Form`/`List`、`Label`、`ButtonStyle.glass`、`ContentUnavailableView`、SF Symbols。  
3. **系统强调色**：`Color.accentColor`（`PlatformAction.brandAccent` 仅为别名）。Tab / 主 CTA / 选中态跟随系统 tint，**不**挂自定义四叶草紫。其余用系统语义色（`primary` / `secondary` / `PlatformStatus`）。  
4. **不自算沉浸**：顶栏显隐、scroll edge、Tab 折叠交给系统。  
5. **转化优先**：详情首屏只保留决策信息；长说明下沉；禁止冗杂脚注干扰参加。  
6. **一套节奏两套页面**：发现 = 媒体货架；详情 = Form 副标题行。  
7. **分层管间距**：Form/List 页交给系统行距与 `controlSize`；命名间距只服务系统读不到的几何（见 1.5）。

## 1.4 反模式（禁止）

- 自定义 HSB 色板挂 `.tint` / 奶油纸质风 / 报纸排版风  
- 手写 toast 浮层（用系统 `.alert` / `.confirmationDialog`）
- 详情页穿状态栏的全幅沉浸（精选发现页除外）  
- 固定 pt 字号、忽略 Dynamic Type  
- 自定义 disclosure chevron（应用 `NavigationLink` 系统箭头）  
- 多阴影叠层、glow、圆角药丸堆叠作装饰  
- 业务里散落魔法数（`padding(..., 4)` / `spacing: 12`）  
- Form/List 页为「对齐像素」手写整页自定义间距表，绕开系统行距  
- 把「消灭 `PlatformMetrics`」当成目标，导致发现货架退回裸数字或滥用 Form 做媒体编排  

## 1.5 系统级分层（谁决定间距）

目标不是零封装，而是 **Features 少做布局决策**。

| 页面 / 职责 | 间距与尺寸由谁管 | Features 允许做什么 |
|-------------|------------------|---------------------|
| **转化 / 设置感**（详情、主办管理、支付、资料、多数 Sheet） | `Form` / `List` / `Section` / `LabeledContent` / `.listSectionSpacing` / `controlSize` | 只组内容与文案；**默认不写**自定义 `padding` / `spacing`，也不为对齐去调 Metrics |
| **发现货架**（Hero、竖大卡、横滑轨、海报、焦点卡） | Design 组件 + `PlatformMetrics` 中系统读不到的几何（宽高比、轨可见比、货架节奏） | 调用 `HeroMediaCard` / `PlatformCatalog*` / `DiscoverBrowseLayout` 等；**不**在业务里写裸 `0.88`、`16/9`、卡片 padding |
| **控件**（CTA、筛选 chip、顶栏 glass） | 系统 `ButtonStyle` + `controlSize` + `buttonBorderShape` | 选风格与尺寸档，不自算芯片内外边距 |
| **消息** | 系统 `List` / glass + `PlatformMessagesChrome` | 顶栏：**左**通讯录；**右**加号菜单（发起聊天等）。好友与群聊同一列表；好友请求在通讯录右上角。发起聊天：选 1 人私聊、多人建群。**禁止**品牌皮肤 |
| **搭子** | 找人玩：免费 / 预约 | 人优先；搜索即意图；Discover 分区节奏；方案 `Docs/BuddiesProductPlan.md` |

**`PlatformMetrics` 的正确角色：**

- **静态 token**：`grid`、`contentInset`、圆角、构图比、列表节奏等——由系统字体 / `UIListContentConfiguration` 推导，**不**在运行时实例化 UIKit 控件。
- **运行时控件边长**（顶栏 glass 圆钮、输入栏「+」高度）→ **`PlatformChromeMeasurements`**（`PlatformChromeRoot` @ `坐标系App` + background 探针 + `PreferenceKey`）；View 内 `@Environment(\.platformChromeMeasurements)` 读取。工程细则见 [DevelopmentGuide §7](Docs/DevelopmentGuide.md#7-并发mainactor-与-ui)。

- 保留：系统字体 / 列表边距推导出的共享几何，以及构图比、轨可见比例。  
- 消费方优先是 **Design 组件**，不是 Features 随手引用。  
- Features 若必须引用，仅限货架编排已有 token（如 `sectionSpacing`），且不得再发明局部魔法数。

---

# 2 Visual Language

## 2.1 颜色（系统语义 + 品牌强调）

实现：`PlatformSurface` / `PlatformStatus` / `PlatformAction`。

| Token | API | 用途 |
|-------|-----|------|
| `brandAccent` | `PlatformAction.brandAccent`（= `Color.accentColor`） | **系统强调色**别名；主 CTA / 选中态跟随环境 tint |
| `groupedPage` | `Color(.systemGroupedBackground)` | 发现页、列表底 |
| `canvas` | `Color(.systemBackground)` | 内容流、部分详情正文场景 |
| `elevated` | `Color(.secondarySystemGroupedBackground)` | 分组上的卡片面 |
| `groupedBlock` | `Color(.secondarySystemBackground)` | canvas 上的信息块 |
| `primary` / `secondary` / `tertiary` | SwiftUI 语义 | 主文 / 副文 / 更弱元信息 |
| `tint` | `.tint` / `.accentColor` | 认证标、主操作强调 |
| `success` / `warning` / `danger` | `.green` / `.orange` / `.red` | 名额、状态、破坏性操作 |
| Fill 占位 | `tertiarySystemFill` → `secondarySystemFill` | 无图封面渐变 |

**深色模式**：不另建色板。语义色与 Material 自动适配。媒体信息栏：`platformMediaInfoBarChrome(_ style:)`（`PlatformMediaInfoBarStyle`：hero / standard / compact → ultraThin / thin / bar）；统一 `mediaChromeInset`；**不**强制 dark；文案 `.primary` / `.secondary`；CTA glass。大字号切图下堆叠，不叠字。

## 2.2 圆角（Continuous，由 grid 推导）

| Token | 推导 | Shape | 用途 |
|-------|------|-------|------|
| `radiusMedia` | ≈ 1.5×grid | `mediaShape` | 缩略图、地图预览、小媒体 |
| `radiusPoster` | ≈ 1.75×grid | `posterShape` | 跟进/热场横卡、榜单海报 |
| `radiusCard` | ≈ 2.5×grid | `cardShape` | 发现大卡、处理遮罩 |
| `radiusEditorial` | ≈ 3×grid | `editorialShape` | 焦点大卡 |
| `fullBleed` | 0 | `fullBleedShape` | 全宽贴边媒体 |

一律 `RoundedRectangle(..., style: .continuous)`。

## 2.3 间距（系统容器优先 + 命名几何兜底）

**原则：** 能交给 `Form` / `List` / `controlSize` 的，不进 Metrics；Metrics 只补系统 API 管不到的几何。

`PlatformMetrics` **不写死品牌 pt 表**。需要命名时，由系统运算得出：

1. **grid** = `UIFont.preferredFont(.body).pointSize × 0.5`（Dynamic Type 联动）  
2. **contentInset** = 消息/列表 **页边**（系统 Layout Margins，≥16）；气泡内边距用 `bubbleContentPadding`，勿混用  
3. 其余货架 / 媒体 token = `grid × n`（圆角、轨距、空状态、底栏等）

构图比（`16/9`、`3/4`）与轨可见比例（`0.88` 等）保留为无量纲分数，不是 pt。

| 场景 | 正确做法 | 错误做法 |
|------|----------|----------|
| Form 行、Section 间距 | 系统默认 + `.listSectionSpacing(.compact)` | Features 里 `.padding(.vertical, formRowVerticalPadding)` 微调整页 |
| 按钮 / chip 高度 | `.controlSize(.large/.regular/.small)`；须与顶栏圆钮对齐时读 `PlatformChromeMeasurements` | 手写 padding 或静态 `UIButton` 探测 |
| 发现分区节奏、卡圆角、轨宽 | Design 组件内部用 Metrics | 业务文件复制一组 `spacing: 14` |
| 任意业务 UI | 零魔法数 | `padding(4)` / `spacing: 12` 散落 |

## 2.4 阴影

**默认：无自定义阴影。**  
深度来自：

- Grouped 背景 vs elevated 分组卡  
- 系统 glass / material  
- Form/List 系统分隔与 insetGrouped 面  

禁止多层级 `shadow(radius:)` 装饰。

## 2.5 模糊与透明材质

| API | 用途 |
|-----|------|
| `.thinMaterial` | 轻容器、chip 等 |
| `.bar` | 需要系统栏带材质时 |
| `buttonStyle(.glass)` | 顶栏圆钮、胶囊、底栏 CTA、详情 glass icon |
| 渐变 mask + material | 不单独做装饰雾面 |

浓度与模糊半径**交给系统**，不手写 blur radius。

---

# 3 Typography

## 3.1 原则

- 字体：**SF Pro（系统）**，经 Dynamic Type 缩放。  
- **禁止**写死 pt。  
- **禁止**项目自定义字阶枚举（已移除 `DiscoverType`）。  
- 一律直接使用 SwiftUI 语义 Text Style：`.largeTitle` / `.title2` / `.title3` / `.headline` / `.body` / `.subheadline` / `.caption` / `.caption2`，需要时再加 `.weight(...)`。

## 3.2 常用映射（角色 → Text Style）

| 角色 | SwiftUI Font | 使用场景 |
|------|--------------|----------|
| Large Title | `.largeTitle.bold()` | 少用；搭子选人不用问候大标题 |
| Title 2 | `.title2.weight(.bold)` | 分区头、详情标题、费用强调、榜序号 |
| Title 3 | `.title3.weight(.bold)` | 发现大卡标题 |
| Headline 档 | `.subheadline.weight(.bold/.semibold)` | 轨卡标题、清单人名 |
| Body | `.body` | Form 主文、行程/须知、发起人姓名 |
| Body Emphasis | `.body.weight(.semibold)` | CTA（大） |
| Subheadline | `.subheadline` / `.weight(.medium)` | 副标题、细则、时间 meta |
| Caption | `.caption` / `.weight(.semibold)` | 更弱 meta、角标强调 |
| Caption 2 | `.caption2` / `.weight(.semibold)` | 轨上微文、顶栏副行、角标 |
| CTA Compact | `.subheadline.weight(.semibold)` | 卡上小参加钮 |

## 3.3 详情页字阶纪律（Form）

| 层级 | 样式 |
|------|------|
| 主文（标题、清单项、须知、时间地点主行） | `.body` + `.primary` |
| 副文（倒计时、距离、细则、发起人指标、讨论正文） | `.subheadline` + `.secondary` |
| 更弱（日期戳等） | `.subheadline` + `.tertiary` |
| 分区 Section header | 系统 `Text` header（Form 默认） |

## 3.4 数字

需要对齐的数值（费用、名额、时间）：`.monospacedDigit()`。

---

# 4 Layout

## 4.1 布局决策顺序

写 UI 时按此顺序，**先停在能停的一层**：

1. **系统容器** — `Form` / `List` / `Section` / `LabeledContent` / `controlSize` / 系统 toolbar  
2. **Design 组件** — 货架卡、横滑轨、Zoom、Sheet chrome（内部可持 Metrics）  
3. **`PlatformMetrics` token** — 仅当 1、2 仍缺几何（比例、轨可见、货架节奏）  
4. **禁止** — Features 内裸数字间距 / 圆角 / 字号 pt  

命名间距的存在，是为了把决策从业务收拢到 Design，不是为了让 Features 处处 `PlatformMetrics.xxx`。

## 4.2 Safe Area

| 场景 | 规则 |
|------|------|
| 发现 · 有精选 | `.ignoresSafeArea(edges: .top)`，玻璃顶栏浮在媒体上 |
| 发现 · 无精选 | 遵守顶部安全区 |
| 详情 | **遵守**顶栏安全区；头图 `detailHeroTopInset = 0`；`.contentMargins(.top, 0)` 去掉 Form 多余顶距 |
| 底栏参加区 | iOS 26 `.safeAreaBar(edge: .bottom)`，可随 Tab 下滑收纳；按钮自行 padding，无整条自定义 `.bar` |

## 4.3 页面边距

- 水平内容边距：`contentInset`（= 系统列表 leading）  
- 横滑轨：`contentMargins(.horizontal, contentInset, for: .scrollContent)`（见 `DiscoverBrowseLayout`）  
- 封面角标：距媒体边缘 `captionBadgeInset`  

## 4.4 宽度与轨可见比例

| 轨 | `*VisibleFraction` | 意图 |
|----|-------------------|------|
| 焦点大卡 | 0.88 | 一卡主导 + 露邻 |
| 跟进/热场 | 0.86 | 同左 |
| 榜单海报 | 0.36 | 约两张半/屏 + 露边；配合 3:4 控轨高 |
| 我的 Wallet 票面轨 | 0.29 | 约三张竖向通行证 + 露出第 4 张 |
| 我的竖海报内容轨 | 0.29 | 约三张 2:3 俱乐部海报 + 露出第 4 张 |

## 4.5 Section 间距

| 上下文 | 由谁管 |
|--------|--------|
| 发现大分区 | `PlatformMetrics.sectionSpacing` ← 系统 `UITableView.sectionHeaderTopPadding` |
| 我的内容库分区 | 同上；一级标题单行，不叠重复说明；空态再解释 |
| 分区标题↔内容 | `sectionHeaderSpacing` ← 系统 subtitleCell 垂直 margin |
| 标题↔副标题 / chevron | `sectionSubtitleSpacing` / `sectionChevronSpacing` ← 系统 `textToSecondaryTextVerticalPadding` |
| 标题簇水平 | `sectionTitleClusterSpacing` ← 系统 `imageToTextPadding` |
| 详情 Form 分区间 | **系统** `.listSectionSpacing(.compact)` |
| 详情行内主/副文 | **系统** Form 行；字阶见第 3.3 节，不另堆行距 token |
| Sheet 短确认栈 | 尽量系统栈；仅 Design 确认壳可持少量 Metrics |

---

# 5 Navigation Pattern

## 5.1 根结构

- `TabView(selection:)` + `Tab(_:systemImage:value:)`：活动 / 搭子 / **广场** / 消息 / 我的  
- `.tabBarMinimizeBehavior(.onScrollDown)`（一级页下滑收纳，WWDC25）  
- 各 Tab 内 `NavigationStack`  
- Tab Bar 显隐（官方 `toolbarVisibility`）：只在被推入页 `.toolbarVisibility(.hidden, for: .tabBar)`。根页不写显隐。不要写在 Sheet 上，不要在根页按 path 开关

## 5.2 Title 模式

| 页面 | 标题方案 |
|------|----------|
| Tab 根（五 Tab） | `platformTabRootScrollChrome` / `ListChrome`：`navigationTitle` + `.inlineLarge` + soft 顶边 + 栏材质联动；`platformTabRootToolbar`；Trailing 分组 + Badge；**无** `navigationSubtitle` / 回顶 / 空 principal / scroll-away |
| 活动分类 | 另加 `platformTabRootTitleMenu`；`.inlineLarge` 下标题多为 leading（系统）；搭子模式改 Trailing Menu |
| 活动详情 | `.inline`（滚动后顶栏显示活动名；工具栏 glass 操作） |
| Sheet / 二级列表 | `.inline` |

## 5.3 Toolbar

**五 Tab 根顶栏（统一契约）**

- 标题：系统 `navigationTitle` + `.inlineLarge`
- 材质 / 边缘：`toolbarBackground(.automatic)` + `scrollEdgeEffectStyle(.soft, for: .top)`
- Trailing：各 Tab 自有，经 `platformTabRootToolbar`；`ToolbarItemGroup` + `ToolbarSpacer` 分组；筛选生效换顶栏 SF Symbol；**生效时角标 = 当前筛选下列表会话条数**（与下方 List 同源）；全部时筛选钮无角标；陌生人计数挂在 Menu「陌生人信箱」行；好友申请角标在通讯录钮；图标 `.platformNavigationBarItemChrome()`（系统原色）
- 强调色：系统 AccentColor；**禁止**挂自定义 clover `.tint`
- 下拉刷新：发现 / 搭子 / 广场 / 消息 / 我的根页 `.refreshable`
- 标题菜单：仅活动分类（`toolbarTitleMenu`）；搭子模式在 Trailing
- **禁止**：手绘 NavigationBar；临时导航栏预览入口；空 principal；scroll-away；`navigationSubtitle`；回顶令牌；导航栏品牌紫 tint

实现：`platformTabRootScrollChrome` +（可选）`platformTabRootTitleMenu` + `platformTabRootToolbar` + `platformNavigationBarItemChrome`。

**五 Tab 间距骨架（摘要；细则见 `Project/05` §4.1）**

| Tab | 骨架 |
|-----|------|
| 活动 / 搭子 | 发现货架：`contentInset` 单 gutter；外层 `VStack(spacing: 0)` 放锚点 + 内层 `LazyVStack(sectionSpacing)`（与活动同构，避免大标题下双间距） |
| 消息 / 广场 | plain List：subtitleCell 行距 + 系统 `listSectionSpacing`；广场内容页一律经 `CommunityLayout` helpers（`communityFeedChrome` / `communityRowToContentSpacing` / `communityInlineSpacing`），禁止 Features 手写 EdgeInsets / 默认栈 spacing / `.lineSpacing` |
| 我的 | insetGrouped 系统页边与**默认**分节距；会员入口在服务区列表行；最近浏览不在此页（活动标题菜单 / 搭子 Trailing 模式 Menu） |

**活动发现（统一顶栏 + 分类菜单）**

- `toolbarTitleMenu` 切换分类；Trailing：筛选 Menu + 发起
- 首页无 Chip 条；分类切换后滚动回顶
- 「最近看过」：竖列 `ActivityDiscoverCard`（与 list 货架同构），禁止纯文字行；Trailing 文本「返回」退出临时表面（保留进入前分类，非 push 返回）

**搭子发现（统一顶栏 + Trailing 模式 Menu）**

- 标题只显示当前表面；模式切换在 Trailing **模式 Menu**（筛选右侧；含最近浏览；**不是** `toolbarTitleMenu` / segmented principal）
- Trailing：`创建?`（俱乐部）→ L1 筛选 + 深筛选 Sheet → 模式 Menu；**无** Tab 根 `.searchable`
- 货架：单模式单 Hero；辅轨 ≤1；陪玩榜 Top3+查看全部
- 「最近浏览」：人=`BuddyPersonGrid`、俱乐部=海报双列网格，禁止纯文字行；Trailing「返回」退出并回到进入前模式

**我的（统一顶栏）**

- Trailing：通知 + 设置
- 身份区：头像 | 昵称列（`@账号`、认证/会员胶囊与昵称左齐、社交四列：获赞数/互关/关注/粉丝数）→ 编辑资料；徽章点进「我的认证」
- **照片墙**（身份下、服务上）：Ins 式三列方格 + 官方 `PhotosPicker` / `LazyVGrid`；选完即写本机 `galleryLocalNames`；**不**进个人资料 Form
- 服务：开通会员 / 会员中心 · 钱包（无独立「我的订单」；催办走通知；支付/履约在行程与陪玩凭证展开页；无顶栏促销条；无根上待办 Form）
- 会员中心：无后端时用 StoreKit Configuration；未开通 `SubscriptionStoreView`；已开通 Form（方案/到期/来源）+ `manageSubscriptionsSheet` / 恢复购买；商品失败诚实空态；禁止自绘第二套付费墙
- 我的内容 Form 三行：我的活动（Menu 文案分类 + 横卡；角标与 `ActivityCardStatus` 看齐；报名→活动行程）/ 我的陪玩（搭子式筛选图标 Menu + 双列人像小卡；角标用 `BookingOrderStatus`；点进预约凭证展开）/ 我的发帖（系统 List + searchable + 筛选 Menu/发帖；Notes·Music Library 气质）；活动行程下一步 **LazyVGrid 双列** 四件套（约陪玩可选 + 群聊 + 导航 + 签到；合适类目扩展装备/须知；无障碍单列）；履约 checklist 只在单场行程
- 成为陪玩：设置 → 账号与安全
- **钱包**：顶部银行卡面主卡；下方 Form 为支付设置与交易流水。活动票 / 陪玩凭证不堆在钱包里。
- **我的内容库**：活动 / 陪玩二级均为 **发现竖列横卡**（非票面 Hub）；点进展开页用 **Form**（活动行程票面 / 陪玩 `BookingCredentialExpandedView`）。活动履约态含条码，结束后切换 **memento**（无条码）。主 CTA **分享纪念票**；**无**「加入 Apple Wallet」。陪玩展开页含联系 / 订单操作 / 补发等。无中间履约预览页。

### PassKit 凭证链路（App 内票面 · DEBUG 导出）

产品主路径是 App 内凭证 / 纪念票，**不**加入系统 Wallet。DEBUG 可导出未签名包：

```
Source(PassSourceFactory)
  → Record(PassStore / PassRecord)
  → pass.json + assets(PassPackageBuilder)
  → Channels(PassDistribution: 导出 / Unsigned 落盘 / .pkpasses)
  → Update(PassUpdateWebService: 本机模拟)
```

| 层 | 源码 | 说明 |
|----|------|------|
| 配置 | `PassConfiguration` | Pass Type ID、Team、webServiceURL、落盘目录 |
| 源 | `PassSourceFactory` | 活动订单 / 参加 / 预约 / 会员 → `PassDraft` |
| 定义 | `PassRecord` | serial + authenticationToken 不变；`lastUpdated` / `voided` / 分发状态 |
| 构建 | `PassPackageBuilder` | pass.json（含更新键）+ icon/logo + manifest + 未签名 zip |
| 存储 | `PassStore` | issue / update / void；退款作废而非仅删除 |
| 分发 | `PassDistribution` | 导出、Unsigned 落盘、多票 `.pkpasses` |
| 更新 | `PassUpdateWebService` | 本机模拟官方契约（非真 HTTPS/APNs） |

签名证书与 Pass Builder **不进 App**；产品不暴露 `AddPassToWalletButton`。

- 一级内容库 Form：我的活动 / 我的陪玩 / 我的发帖（各一行进二级）；**不含收藏聚合**；「我的活动」二级横卡、「我的陪玩」二级双列小卡、「我的发帖」二级系统 List，均非票面 Hub；广场收藏/赞过等库项走广场栈 `CommunityLibraryDestination`（根上不挂 Hub）
- 收藏分域：广场分享 → 广场栈内容库目的地；活动 → **详情右上「更多」**（收藏活动；举报下方分隔 →「我的收藏」库）；发现主页不挂收藏入口
- 栈内 push 目的地用 `.toolbarVisibility(.hidden, for: .tabBar)`。根页不写显隐。Sheet 不要改 Tab 显隐
- Accessibility Dynamic Type：圈子海报卡可切图下堆叠；活动 / 陪玩 / 发布凭证以票面叠字为主（`ProfileCredentialCards`）

**详情顶栏**

- `.toolbarBackground(.hidden, for: .navigationBar)`  
- Trailing：`GlassIconMenu`（分享/更多）；搭子详情为系统 `Menu`（不感兴趣 / 举报 / 拉黑）  
- Zoom cover 预览态可有关闭钮  
- Tab Bar：一级页可见（根页不写显隐）；栈内 push 目的地 `.toolbarVisibility(.hidden, for: .tabBar)`。不要写在 Sheet 上，不要在根页按 path 开关

## 5.4 Back Button

- 栈内详情：系统返回  
- `presentation == .zoomCover`：可隐藏返回，改用关闭  

## 5.5 打开详情

唯一推荐路径：

`NavigationLink(value:)` + `matchedTransitionSource` + `navigationTransition(.zoom)`  

封装：`ActivityZoomNavigationLink` / `activityZoomNavigationDestination`；搭子选人：`BuddyZoomNavigationLink` / `buddyZoomNavigationDestination`；圈子：`TabNavigationState` + `circleBrowseNavigationDestination` + `CircleMemberNavigationLink`。

同一栈内同类型 `navigationDestination` 只保留栈根一份（Environment `hasCircleBrowseDestination` 等判断已注册则跳过）。Sheet 用 `independentNavigationSheetChrome` 清掉继承标记（见 `.cursor/rules/navigation-destination.mdc`）。

活动 Zoom 源 id 用 `ActivityZoomSource`（`activityID` + `slot` + `intent`），同一活动在多货架中不得撞号；用 `activityZoomSlot(_:)` 分槽。`intent`：`.browseDetail`（默认）→ 完整详情；`.participantPass`（「我的」长条凭证）→ `ActivityCredentialExpandedView` 展开完整票面。

Zoom 性能：转场期间不改源列表（浏览埋点延后）；详情相关卡不挂同 namespace Zoom；精选源 clip 与详情头图 `cardShape` 对齐；评论 / 相关轨首帧后再挂。

---

# 6 Card System

## 6.1 总表

| 类型 | 用途 | 比例 | 圆角 | 布局要点 |
|------|------|------|------|----------|
| **Featured Hero** | 发现顶栏精选 | 4:5 | card | 底栏 Material 信息 + 参加；Zoom source |
| **Discover 竖大卡** | 兴趣/品类流 | 16:9 | 20 | 封面叠字或 a11y 图下堆叠 |
| **Continue / Hot 横卡** | 跟进、热场轨 | 16:9 | 14 | 轨宽 ~0.86；底栏同 Hero 结构 |
| **Poster 榜单** | 排名轨 | 3:4 | 14 | 轨宽 ~0.36；序号角标 |
| **Wallet Pass Stack** | 长条凭证堆（「我的」夹预览） | 露条 = `walletPassStackHeaderPeek`（字阶）；堆高 = 条高+min((n−1)×peek, maxExtra) | strip | 叠放预览；Zoom → 展开行程页 |
| **Activity Journey Credential** | 活动行程展开票面 | 3:4 头图区 | poster | `ActivityJourneyCredentialFace` + CredentialArt；fulfillment / memento 双模式 |
| **Wallet Pass Face** | 夹内长条预览卡 | 条带比例 | strip | `WalletPassRecordFace`；非展开页主票面 |
| **Editorial 焦点** | 精选轨焦点大卡 | 16:9 | 24 | 一屏 1 卡全宽；与 Continue / Hot 同高 |
| **Person 找人** | 双列照片卡 + 精选 Hero | 3:4 / 4:5 | people | `BuddyGridCard` / `BuddyPickCard` / `BuddyFeaturedCard`；图下文案 |
| **Booking 预约** | 市场货架 + 排行 | 轨 / Top3 | service | `BuddyPaidLeaderboard`、`BuddyPosterShelfCard` |
| **Browse 顶栏** | 五 Tab 同套 `platformTabRoot*`；搭子另加模式 title menu + 找人筛选 | — | browse | 无 searchable；无 segmented principal；无导航栏预览入口 |
| **Circle 俱乐部** | 免费末幕 | 3:4 | poster | 次于选人 |
| **Voice 语音厅** | 预约列表后 | 横卡 | continue | 试水再预约 |
| **Detail Hero** | 详情头图 | 4:5 | card（圆角卡） | 安全区下；天气胶囊；相册控件 |
| **Detail Related** | 相关活动推荐 | 16:9 横卡 | rail | Form header + 横滑轨；`PlatformEventCard`；footer 说明推荐逻辑 |
| **Compose Cover** | 发起活动媒体 | `galleryEditorThumb` | media | 单页 Form：最多 6 张照片/视频，首张为封面 |

活动紧凑横卡统一使用 `PlatformEventCard`（发现页「快被约满」同构）：16:9 媒体、状态角标、标题/时间/meta 与右下角参加 CTA；导航、Zoom 和轨宽由调用层负责。详情相关活动见 `DetailRelatedActivitiesRail` + 调用方 Section header。

## 6.2 卡内布局通则

```
[ 媒体 ]
  ├─ 左上：状态 / 社交角标（captionBadgeInset）
  └─ 底栏：左 Title/Time/Meta · 右 参加 CTA
```

- 常规字阶：叠字在媒体上（`platformMediaInfoBarChrome(.hero|.standard|.compact)`；CTA glass）
- Accessibility 大字：`prefersStackedCardChrome` → 图下信息区（无 Material 底栏）
- Increase Contrast / Reduce Transparency：Material 退 `secondarySystemBackground`
- Padding：底栏内边距由 style 的 `mediaChromeInset` 统一；信息行距 `cardInfoSpacing`；底栏图文距 `cardFooterSpacing`

#### 6.2.1 Material 底栏角色表（`PlatformMediaInfoBarStyle`）

| Style | Material | 卡片场景 |
|-------|----------|----------|
| `.hero` | `.ultraThinMaterial` | 精选 Featured、焦点 Editorial |
| `.standard` | `.thinMaterial` | 发现流 `HeroMediaCard`、跟进 / 热场 / 赛事横卡 |
| `.compact` | `.bar` | 榜单竖海报 |

禁止 Features 旁路手写 `.ultraThinMaterial` / `.thinMaterial` / `.bar` 铺封面底栏。

## 6.3 阴影与边框

卡片**无**描边装饰阴影；分组感来自页面 `groupedPage` 与媒体本身。

## 6.4 Zoom Clip

`ActivityZoomClip`：`card` / `rail` / `poster` / `editorial` —— 与静态卡 shape 一致；精选视觉仍可用 `fullBleedShape`（圆角 0），Zoom 源用 `card` 对齐详情头图。

---

# 7 List System

| 容器 | 何时用 |
|------|--------|
| **ScrollView + LazyVStack** | 发现货架、混合 Hero + 多分区、横滑轨外层 |
| **Form** | 详情主结构、支付/确认/发布类设置流、发起人管理 |
| **List** | 纯列表 Sheet（成员、订单、导航 App）、系统 inset 列表体验 |
| **LazyVGrid / Grid** | 搭子人墙等双列/等宽货架 |
| **PlatformFlowLayout** | 喜好胶囊等「按内容宽、自动折行」（官方 `Layout`）；`Form` Section + 系统 capsule（`InterestCapsuleChip`）；禁止等宽 `LazyVGrid` 硬截断文案 |
| **喜好数量** | 编辑资料：`ToolbarItem(.topBarTrailing)` 等宽数字 `n/max`（对齐 List 多选计数）；登录引导：底栏 `safeAreaInset` 文案 + CTA。**禁止**单独 Form 进度卡 / `navigationSubtitle` |
| **横滑 ScrollView** | `scrollTargetLayout` + `viewAligned` + `contentMargins`（`DiscoverBrowseLayout`） |

## 7.1 Form 细则（详情）

- `.listSectionSpacing(.compact)`  
- 相关决策信息合并同一 `Section`（避免双白卡灰缝）  
- 头图 Section：`listRowBackground(.clear)`，横向 inset 0  
- 行：副标题单元格 = 头像/缩略图 + 主文 `.body` + 副文 `.subheadline`，**垂直居中**  
- Disclosure：系统 `NavigationLink`；相关活动为视图式推入（不参与发现 Zoom）  
- **Features 默认零自定义间距**：不在 Form 行外再套 Metrics padding；需要例外时先改 Design / 系统修饰符，再考虑 token

## 7.2 消息模块边距与列表行（系统「信息」）

### 列表行

- **组件：** `PlatformConversationRow` + `PlatformToolbarAvatarLabel`（单层 glass，边长 = `@Environment(\.platformChromeMeasurements)`）
- 编辑资料：`PhotosPicker` + `PlatformToolbarAvatarLabel` → `CommunityPhotoStore` / `avatarLocalName`（**Sendable label**：预览与按钮分离，见 [DevelopmentGuide §7.7](Docs/DevelopmentGuide.md#77-photospicker-与-sendable-label)）
- **导航：** `NavigationLink`（隐藏 disclosure）+ `platformConversationListChrome()` / `platformConversationListRowChrome()`
- **禁止：** 在 List/`NavigationLink` 行内嵌 `UIListContentView`（会裁切头像）；勿同时叠行水平 insets 与 List contentMargins

### 外圈：页边（一个系统指数）

**真源：** `PlatformConversationListRow.horizontalInset`（= `PlatformMetrics.contentInset` / 系统 Layout Margins）

| 场景 | API |
|------|-----|
| 收件箱 / 好友 / 消息二级 List | `platformConversationListChrome()` → plain + `canvas` + `contentMargins`；行 `platformConversationListRowChrome()` **仅垂直**；勿再叠行水平 insets |
| 会话线程 ScrollView | `platformMessageThreadScrollMargins()` |
| 输入栏 / @ 条 / 通话页边 | `platformMessagePagePadding()` 或 `PlatformMessagesChrome.pageHorizontalInset` |
| 行内栈间距 | `PlatformMessagesChrome.stackSpacing` / `bubbleAvatarSpacing`（subtitleCell 探针） |
| List / Form 空态 | 交给系统；**勿**再叠 `emptyStateVerticalPadding`（仅线程 `PlatformChatEmptyThread` 可用 `emptyVerticalPadding`） |

**禁止：** Features 用发现 `railCardSpacing` / Form `formRowVerticalPadding` / 手写 `EdgeInsets(…, contentInset, …)` 叠在已 chrome 的 List 上。

### 内圈：控件间距

`bubbleContentPadding`（气泡/输入框内）；勿用 `contentInset` 当内边距。

### 气泡

- 己方 `.tint` + 对方 `secondarySystemFill`；大圆角 continuous
- **单聊**：无侧栏头像；**群聊**：仅对方左侧头像（聚类末条显示）
- 输入栏（Messages 骨架）：左圆「+」/录音取消；**胶囊内右侧**承载 mic / 文字「发送」/ 录音 `stop` / 预览「发送」（勿外侧再挂方钮或 `arrow.up`）
- **点 mic**：录音（框内右 `stop`）→ 预览（框内左 `play`、右「发送」）→ `onVoiceCapture`；`AVAudioRecorder` / `AVAudioPlayer`；**键盘保持**
- 本机落盘，**不**宣称已上云（B5）；会话与评论/评价底栏均接 `onVoiceCapture`；取消/发送后继续保焦
- 「+」Menu：有业务回调则接线；未接时仍展示并诚实 Alert；评论等无 `onVoiceCapture` 仍可进录音态，点发送再诚实提示
- 底栏挂载：`platformMessageComposerBottomBar` = iOS 26 **`safeAreaBar`**；Composer **无**实心 `canvas` 底带
- **禁止**进录音就收键盘；禁止假发「3 秒气泡」；禁止 `.bar` 第三色 / `safeAreaInset` 硬切；禁止字段 `secondarySystemFill`
- Form / credential / searchable **不是** Messages 底栏；Form 仍用 `platformTextInputScrollChrome` 交互式收键盘
- 系统 Text Style；勿用活动页 glass CTA

### 7.2.1 文本输入 / 键盘（全 App）

真源：`Design/PlatformTextInputChrome.swift`。按**场景家族**选皮，禁止混用。

| Surface | API |
|--------|-----|
| `.form` | `platformFormTextInput(_:)` / `PlatformReviewsWriteSheet`（导航栏发送；陪玩口碑须订单门控） |
| `.messageComposer` | `PlatformMessageComposerBar`（字段 `platformMessageComposerTextInput`） |
| `.search` | `.searchable` |
| `.alert` | Alert `TextField`（可挂 `platformFormTextInput`） |
| `.credential` | `platformCredentialTextInput(.phone/.oneTimeCode)`（Login 卡片容器仍用 Login chrome） |
| 收键盘（共用） | `platformTextInputScrollChrome()`；`platformSheet(.form/.browser/.filter/.confirm)` 已自动挂 |

同一模块、多皮；禁止跨 surface 混皮或 Features 旁路第二套键盘字典。`loginCredentialFieldStyle` 仅兼容转发。  
**CI 门禁**：`Scripts/check-text-input.sh`（由 `check-imports.sh` 调用）——凡 `TextField` 须挂 `platformFormTextInput` / `platformCredentialTextInput` / `platformMessageComposerTextInput`；Features 与 Design（除 `PlatformTextInputChrome`）禁止手写 `keyboardType` / `submitLabel` / `textContentType` 等。

## 7.3 空状态

全 App 空态统一 `ContentUnavailableView`：
- 结构：`Label` + `description` + 可选裸 `Button` actions；搜索用 `.search(text:)`
- 放置：页面级用 `platformContentUnavailablePageChrome()`（铺满后系统垂直居中），或 `List.overlay` 叠固有尺寸居中；**禁止**整页空态做 List 行 / ScrollView 首子视图（会顶在上方）
- **禁止**空态挂 `activityPrimaryCTA` / `.borderedProminent` / 自设字号 / UIKit 空态旁路
- **禁止**再叠 `emptyStateVerticalPadding`
- `activityPrimaryCTA` 仅用于卡片/底栏主操作，不进空态 actions

---

# 8 Motion

| 动效 | 实现 | 场景 |
|------|------|------|
| **Push** | `NavigationStack` 默认 | 二级页 |
| **Sheet** | `platformSheet(_:)` detents | form / filter / browser / confirm / action |
| **Zoom** | `navigationTransition(.zoom)` + `matchedTransitionSource` | 活动卡 → 详情；「我的」长条凭证 → 展开票面 |
| **Scroll edge** | `.scrollEdgeEffectStyle(.soft, for: .top)` | 发现、详情顶 |
| **Large Title collapse** | 系统（非发现默认） | 适用 Large Title 页 |
| **Tab minimize** | `.tabBarMinimizeBehavior(.onScrollDown)` | 根 Tab |
| **Matched geometry** | Zoom namespace；非装饰性 match | 仅导航转场 |
| **Sensory** | `.sensoryFeedback` | 发送、点赞等即时交互；结果告知走 Alert |
| **结果告知** | `platformFeedbackAlert` | 收藏、筛选、订单状态等 |
| **Reduce Motion** | 尊重环境值；不叠加额外炫光动画 | 全局 |

Sheet 档位：

- `form` → `.large`  
- `filter` / `browser` → `.medium + .large`  
- `confirm` → `.medium`  
- `action(height:)` → 固定高  

一律 `presentationDragIndicator(.visible)`。

---

# 9 Components

## 9.1 Button

| 样式 | API | 用途 |
|------|-----|------|
| Primary CTA | `activityPrimaryCTA` / 底栏 `activityDetailBottomPrimaryCTA` | 参加、主行动；glass + capsule；可双行副标题 |
| Secondary CTA | `activitySecondaryCTA` / Bottom Secondary | 取消参加、次要 |
| Glass Icon | `activityGlassIcon` / `ActivityDetailControls.GlassIconButton` | 闹钟、导航、私信、发送、关闭 |
| Glass Chip | `activityGlassChip` | 头图「N 张」「编辑相册」 |
| Toolbar Circle / Capsule | `platformToolbar*` | 发现顶栏 |
| Destructive | `ButtonRole.destructive` | 删除评论、取消活动 |

`controlSize`：顶栏 `.regular`；主转化 `.large`；卡上可为 `.small` / `.regular`。

## 9.2 Chip / Filter

`PlatformFilterChip`：系统 `.glass` / `.glassProminent` + `.controlSize(.regular)` + `.capsule` + **多色** SF Symbol（同档 `.body` / `.medium`）；`GlassEffectContainer` 横滑条；降低透明度回退 bordered。图文距：`labelReservedIconWidth` **按符号逐枚测量** + `labelIconToTitleSpacing`（glass `imagePadding`，为 0 则 `footnote.leading`）。广场挂载：List **首 Section**（随内容滚动，对齐通知中心）；可选 `platformCategoryChipTopBar`（`safeAreaInset(.top)`）仅非 searchable 场景。禁止整条共用过大预留宽、手写 `.shadow` / Metrics 芯片 padding。

## 9.3 Badge

`PlatformMediaCaptionBadge` / `PlatformCaptionBadge`：

- 媒体左上状态（快满、已参加等）  
- `captionBadgeInset` + 水平/垂直 caption padding  
- tint 或 material chrome  

发起人徽章用 **SF Symbol**（认证 `checkmark.seal.fill`、会员 `crown.fill`、等级文案），不另造色块章。

## 9.4 Avatar

`PlatformListAvatarView`：

- 消息模块：`PlatformToolbarAvatarLabel` — **单层** `glassEffect(.circle)`，头像盘与 glass 同边长（`@Environment(\.platformChromeMeasurements)`），无内嵌小圆
- 编辑资料选图：`PhotosPicker` + `PlatformToolbarAvatarLabel`；保存仍走 `CommunityPhotoStore` → `avatarLocalName`（label 闭包仅 `String`，见 [DevelopmentGuide §7.7](Docs/DevelopmentGuide.md#77-photospicker-与-sendable-label)）
- 列表页边：`contentInset`（与顶栏 leading 对齐）；铺满后视觉边距不再被外圈 glass 撑开
- 其它模块默认：`PlatformListAvatarView` + `listAvatarSide`

## 9.5 Tag

兴趣/画像标签用系统文本流或轻量 wrap；颜色 secondary/tint，无描边贴纸风。

## 9.6 Search

系统 `.searchable` / `ContentUnavailableView.search`（消息等）；活动发现以分类 title menu + 顶栏筛选 Menu 为主。

## 9.7 Segment / Picker

- 顶栏分类：`Picker` / `Menu` + `Label`（`toolbarTitleMenu`），不自绘 segmented 皮肤。
- 顶栏分类：「我的活动」trailing `Menu` + `Picker(.inline)`，**label 用纯 `Text` 当前分类**（勿 `Label`，防 toolbar 收成图标）；「我的陪玩」trailing 对齐搭子筛选图标 Menu。
- 页内分段（约陪玩详情：资料 / 服务 / 评价 / 动态）：`platformSegmentedPickerChrome()` = 系统 `.segmented` + 清底 + 水平与 Section 卡同宽；**iOS 26 玻璃由系统提供**，禁止再包自定义 `glassEffect`。

## 9.8 反馈（Alert / Confirmation Dialog）

**禁止自定义 Toast 浮层。**  
操作结果用系统容器：

| 场景 | API | 规则 |
|------|-----|------|
| 告知结果（收藏、筛选、订单状态等） | `.alert` + `platformFeedbackAlert` | 单一「好的」；文案绑定 `String?` |
| 复制等无需打断的轻量结果 | `platformLightFeedback` | 触觉反馈 + 自动清空绑定；不用 Alert |
| 破坏性 / 多选项决策 | `.confirmationDialog` 或 `.alert` | 见 §12.4 |
| 需表单或下一步 | `.platformSheet(...)` | 不压成 Alert |

`platformFeedbackAlert` = 对 `Binding<String?>` 的系统 Alert 封装。

## 9.9 Empty / Loading

- Empty：`ContentUnavailableView`  
- Loading：系统 `ProgressView`；处理中可用 `processingOverlay`（cardShape + 系统 fill）

## 9.10 Step Symbol

有序说明统一：`1.circle`…（`ActivityDetailStepSymbol`），`.secondary` + hierarchical。

---

# 10 Icons

## 10.1 规则

1. **只用 SF Symbols**（活动封面占位、导航、状态、工具栏）。  
2. 渲染统一走 `platformSymbolStyle` / `platformContentSymbolStyle` / `platformListActionSymbolStyle`（见 `PlatformSymbolStyle.swift`）：
   - **默认** `.hierarchical` — Toolbar、glass、次要 meta、占位图  
   - **状态** `.monochrome` + `PlatformStatus` — 成功 / 警告 / 危险 / 点赞激活  
   - **角标** `.palette` — 媒体删除钮、已发送勾等双层符号  
   - **多色** `.multicolor` — 设置入口、筛选条件、分类 / 圈子内容图标、公约列表  
3. **勿强制彩色**：Tab Bar、Toolbar Menu、Navigation chevron、破坏性 `role`、系统选中 tint。  
4. 与文字并排：优先 `Label`；列表行主操作除外。  
5. 权重跟随正文 Dynamic Type，不写死 pointSize（列表标准头像位图除外）。  
6. 镜像与本地化：使用系统可本地化符号名；颜色用系统语义色、`PlatformStatus` 与系统 **`AccentColor`**（`PlatformAction.brandAccent` 别名）。

## 10.2 活动常用

| 语义 | Symbol 例 |
|------|-----------|
| 时间 / 日历提醒 | `alarm`、`calendar` |
| 导航 | `arrow.triangle.turn.up.right.diamond` |
| 私信 | `bubble.left` |
| 分享 / 更多 | `square.and.arrow.up`、`ellipsis` |
| 收藏 | `bookmark` / `bookmark.fill` |
| 认证 / 会员 | `checkmark.seal.fill`、`crown.fill` |
| 费用勾选 | `checkmark.circle.fill` / `circle` |
| 空状态 | `calendar`、`sparkles` 等 |
| 设置 | `lock.shield`、`bell.badge`、`hand.raised.fill`、`flag.fill`、`info.circle` |

决策卡行头用文案「时间」「地点」，**不再**用 clock/mappin 作行头图标。

---

# 11 Accessibility

## 11.1 Dynamic Type

- 全部系统 Text Style。  
- `DiscoverAccessibility`：大字阶放开行数；`prefersStackedCardChrome` 避免封面叠字裁切。  

## 11.2 VoiceOver

- 卡片打开：合并 `accessibilityLabel`（状态 + 标题 + 时间 + meta）。  
- 叠字层常 `accessibilityHidden`，避免与 `NavigationLink` 重复。  
- 发起人/评论行：`accessibilityElement(children: .combine)` 或显式 summary。  
- 短暂反馈走系统 Announcement。  

## 11.3 Contrast

- 媒体叠字：`platformMediaInfoBarChrome(_ style:)`（hero / standard / compact）；文案系统语义色；CTA glass。  
- 语义色状态（warning/success）仅用于短标签，不用于大段正文。  

## 11.4 Reduce Motion

- 不额外叠加自定义弹性动画。  
- Zoom / 系统转场由系统在 Reduce Motion 下降级。  

## 11.5 触控

- 主 CTA `controlSize(.large)`；底栏 `buttonSizing(.flexible)`。  
- 图标按钮圆形 glass，满足最小触控目标。  

---

# 12 页面结构规范

## 12.1 活动发现 `ActivitiesView`

```
NavigationStack
└─ ScrollView
   ├─ [可选] Featured Hero（仅默认浏览态；筛选时隐藏；精选转化唯一入口）
   └─ LazyVStack(spacing: sectionSpacing)
      ├─ 转化优先货架（快满 / 今晚 / 免费 / 热场 / 附近…，≤6 轨；无独立「精选」轨）
      └─ [可选] 活动分享入口（`ActivitiesBrowseRoute.communityFeed`）
Toolbar：`platformTabRoot*`（inlineLarge + 分类 title menu + Trailing 筛选 Menu / 发起）
Background: groupedPage
Zoom destination + slot 源；详情相关活动不参与同 namespace Zoom。`ActivityEngagementStore` 非观察对象，避免浏览埋点拆掉列表 Zoom 源。货架结果按输入指纹缓存；种子封面不用 GeometryReader，避免 Lazy 预取掉帧。
```

**一屏原则**：Hero 抢参加；货架跟进；筛选走顶栏 Menu 即时生效；促销头在「我的」。

## 12.2 活动详情 `ActivityDetailView`

```
Form
├─ Section 头图（clear background）
├─ Section 标题+决策（费用/时间/地点/名额/成员入口）  ← 同一 Section
├─ Section 发起人（header「发起人」）
├─ Section* 行程 / 费用 / 装备 / 须知（按 blueprint 排序）
├─ [可选] 管理 / 订单
├─ [已参加] 顶栏「我的行程」票券按钮（`ticket.fill`，在分享/更多左侧）
├─ Section 活动讨论（转场后再挂）
└─ Section 相关活动（横滑轨贴边；header 同参加须知）
+ safeAreaInset 底栏 CTA
  · 参与者已参加：secondary「取消参加」+ primary「我的行程」
  · 参与者已结束：primary「我的行程」（复盘在行程页）
  · 群聊：Toolbar「更多」→ 打开活动群
+ toolbar：`ToolbarItemGroup` + 文字图标钮（同活动 / 广场 Tab 根）；更多用 `ellipsis`
+ listSectionSpacing(.compact)
```

**转化漏斗**：货架 → 标题/pitch → 费用与名额 → 时间地点 → 发起人信任 → 参加。  
长文（行程/费用/准备/须知/讨论/相关）全部在折叠视口之下。

## 12.3 Sheet 族

| 流程 | Kind | 内容 |
|------|------|------|
| 发布/编辑 | `.form` | Form |
| 筛选（搭子等 Form） | `.filter` | Form |
| 活动发现筛选 | 顶栏 `Menu` | inline Picker / Toggle，即时生效 |
| 成员/订单/支付 | `.browser` | List/Form；成员轻量卡与「全部成员」同档 |
| 参加成功 | `.confirm` | 短栈 |
| 举报活动 | `.form` | 原因 + 情况说明 + 证明材料；提交后 Alert 收尾确认 |
| 导航 App | `.navigationPicker` | inset List；`LabeledContent` 活动地址 + 地图 App 行；系统 `.medium` 单档 |
| 分享活动 | `PlatformShareSheet` | 系统 `UIActivityViewController` 的 SwiftUI 桥接；iPhone 从底部呈现 |

## 12.4 Alert / Confirmation Dialog

只使用 SwiftUI 系统 `.alert` 与 `.confirmationDialog`，不自绘弹窗。

| 意图 | 系统容器 | 规则 |
|------|----------|------|
| 阻塞告知、错误、敏感词 | `.alert` | 单一「好的 / 知道了」；信息必须先读再继续 |
| 需理解后果的多结果决策 | `.alert` | 如「仅取消 / 取消并退款」；按钮角色明确 |
| 退出登录 / 注销账号 | `.alert` | 设置页账号后果确认；破坏动作 `.destructive`，必须有 `.cancel` |
| 删除预约记录 / 取消预约 | `.alert` | 陪玩订单详情后果确认；破坏动作 `.destructive`，必须有 `.cancel` |
| 退出俱乐部 / 用户举报 / 拉黑 / 删除会话 | `.alert` | 后果确认或选择举报原因；破坏动作 `.destructive`，必须有 `.cancel` |
| 活动举报受理收尾 | `.alert` | Sheet 提交材料后弹出「已收到反馈」；单一「好的」 |
| 菜单触发的移出群聊 | `.confirmationDialog` | `titleVisibility: .visible`；破坏动作必须 `.destructive`，必须有 `.cancel` |
| 有输入、摘要、支付或下一步 | `.platformSheet(.confirm/.form/.browser)` | 不压缩为 Alert/Dialog |
| 非阻塞成功 / 状态告知 | `.alert` + `platformFeedbackAlert` | 单一「好的」；不用 Toast / 自绘浮层 |

破坏性动作不得从 `Menu`、`List` 行或详情按钮直接执行；先写入待确认状态，再由系统 Dialog 执行。

## 12.5 文案与状态

- 动作词与 `ActivityCardStatus` / `ActivityDetailCopy` 对齐。  
- 名额紧张用 warning 语义，不堆营销脚注。  

---

# Appendix A — 代码锚点

| 主题 | 文件 |
|------|------|
| 色 / 语义 / 状态 | `Design/PlatformSemantics.swift` |
| 间距 / 圆角 / 形状 | `Design/PlatformMetrics.swift` |
| 运行时控件边长（顶栏圆钮、输入栏） | `Design/PlatformChromeMeasurements.swift` |
| 列表头像 / 顶栏 / 消息与活动 chrome | `PlatformListAvatar.swift`、`PlatformToolbarChrome.swift`、`PlatformConversationListChrome.swift`、`PlatformActivityChrome.swift`、`PlatformActivityChipsBadges.swift`、`PlatformMessagesChrome.swift` |
| 货架卡 | `Design/PlatformCatalog*.swift`、`Features/Activities/ActivityCards.swift` |
| 横滑布局 | `Design/DiscoverBrowseLayout.swift` |
| Zoom | `Design/ActivityZoomNavigation.swift`、`Features/Buddies/BuddyZoomNavigation.swift` |
| Sheet | `Design/PlatformSheet.swift` |
| 文本输入 / 键盘 | `Design/PlatformTextInputChrome.swift`、`PlatformMessageComposerBar.swift`、`PlatformMessageComposerRecordingChrome.swift`、`PlatformVoiceRecorder.swift`、`PlatformReviewsCommentComposer.swift` |
| 发现页 | `Features/Activities/ActivitiesView.swift` |
| 搭子选人 | `Features/Buddies/BuddiesView.swift`、`BuddyBrowseShelves.swift`、`BuddyPaidMarketCatalog.swift`、`BuddyPaidLeaderboard.swift`、`BuddyPaidTopCard.swift`、`BuddyGridCard.swift`、`BuddyPosterShelfCard.swift`、`BuddyOrgInfoScaffold.swift`、`CircleGroupManageViews.swift`、`ProfileCircleDetailView.swift`、`BuddyMemberProfileSheet.swift`、`BuddyMemberListSheet.swift`、`BuddyMemberCopy.swift`、`BuddyVoiceHallViews.swift`、`BuddiesModeSwitch.swift`、`BuddyFilterSheet.swift`、`BuddyBookingSheet.swift`、`BuddyScheduleSlot.swift`、`BuddyCityCatalog.swift` |
| 详情 | `Features/Activities/ActivityDetailView.swift`、`ActivityDetailContent.swift`、`ActivityDetailView+FormSections.swift` |
| Tab 折叠 | `ContentView.swift` |

---

# Appendix B — 设计评审清单

- [ ] 强调色是否只用系统 `AccentColor` / 环境 tint（无自定义 clover `.tint`）？  
- [ ] 是否只用系统色与 Material？  
- [ ] 字号是否全部系统 Text Style（无项目字阶枚举）？  
- [ ] Form/List 页是否把间距交给系统容器，而非 Features 手调 Metrics？  
- [ ] 发现货架几何是否收在 Design 组件内（业务无裸数字、无复制轨比例）？  
- [ ] 控件是否只用 `ButtonStyle` + `controlSize`，未自算芯片 padding？  
- [ ] 若出现 Metrics，是否属于系统读不到的几何，且优先由 Design 消费？  
- [ ] 发现/详情 Safe Area 策略是否符合第 4.2 节？  
- [ ] 卡片比例与圆角是否落在第 6 节表？  
- [ ] 详情是否 Form + compact section spacing？  
- [ ] 头像行是否垂直居中且无错误折行？  
- [ ] 进详情是否 Zoom 而非纯 push（发现卡）？  
- [ ] 浏览卡：活动/搭子 Zoom 进详情；广场媒体可分页滑动，双击点赞，单点不进大图？  
- [ ] 反馈是否无自定义 Toast（用 `platformFeedbackAlert` / `.confirmationDialog`）？  
- [ ] Dynamic Type / 大字叠字是否已切 stacked？  
- [ ] 是否引入了禁止的装饰阴影或品牌渐变？  

---

*最后同步：2026-08-28（Tab 文案统一「广场」；PlatformSemantics 仅语义色；搭子圈子 View / MessagesModel 拆分已反映于 Appendix A）。*

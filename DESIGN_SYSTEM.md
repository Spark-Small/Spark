# 坐标系 Design System

> 基于活动版块实现沉淀的产品级设计规范。  
> 原则：**Apple 原生 · SwiftUI First · HIG · App Store Today 编排 · Apple TV 沉浸 · Apple Music 留白**。  
> 系统级：**业务少决策、多交给系统容器**；命名间距留给 Design 与系统读不到的几何，不是追求零 Metrics。  
> 实现源码锚点：`Design/PlatformSemantics.swift`、`Design/PlatformCatalogCards.swift`、`Design/ActivityZoomNavigation.swift`、`Design/WalletPassFace.swift`、`Design/WalletPassStack.swift`、`Features/Activities/**`、`Features/Profile/ProfileCredentialCards.swift`、`Features/Profile/ProfileCredentialFolderViews.swift`、`Features/Profile/ActivityCredentialExpandedView.swift`、`Services/PassKit/**`。

---

# 1 Design Philosophy

## 1.1 一句话

用系统组件与系统语义，把「发现一场局 → 读懂 → 参加」做成 iPhone 上最自然的路径。

**系统级定义：** 业务少决策、多交给系统容器；不是删掉所有命名间距。

## 1.2 产品气质

| 灵感来源 | 在坐标系中的落点 |
|---------|------------------|
| **App Store Today** | 发现页分区货架、精选 Hero、横滑轨、榜单海报、焦点大卡 |
| **Apple TV** | 精选全宽沉浸、媒体穿顶、玻璃顶栏浮在内容上 |
| **Apple Music** | 大留白、少装饰、分区节奏疏朗、转化区信息克制 |
| **Photos** | 两侧圆形 glass + 中间双行胶囊顶栏；Zoom 进详情 |
| **Settings / Form** | 详情页用系统 Form 承载决策与说明；钱包页主卡为例外（银行卡面），流水 / 设置仍 Form |
| **PassKit** | 官方同构链路：Source → Build → Distribute → Update Web Service → System Wallet；App 内凭证夹在「我的」；`AddPassToWalletButton`；签名落盘 `SignedWalletPasses` |

## 1.3 硬性约束

1. **SwiftUI First**：布局、导航、材质、动效优先系统 API。  
2. **官方组件优先**：`NavigationStack`、`TabView`、`Form`/`List`、`Label`、`ButtonStyle.glass`、`ContentUnavailableView`、SF Symbols。  
3. **无品牌色体系**：颜色只用系统语义色（`primary` / `secondary` / `tint` / `Color(.system…)`）。  
4. **不自算沉浸**：顶栏显隐、scroll edge、Tab 折叠交给系统。  
5. **转化优先**：详情首屏只保留决策信息；长说明下沉；禁止冗杂脚注干扰参加。  
6. **一套节奏两套页面**：发现 = 媒体货架；详情 = Form 副标题行。  
7. **分层管间距**：Form/List 页交给系统行距与 `controlSize`；命名间距只服务系统读不到的几何（见 1.5）。

## 1.4 反模式（禁止）

- 自定义 HSB 品牌紫 / 奶油纸质风 / 报纸排版风  
- 手写 toast 浮层（用触觉 + VoiceOver 播报）  
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
| **搭子** | 情境活动卡 + 兴趣话题 + 状态人卡；陪玩中段语音厅 | 默认同好；筛选 Sheet；右上「陪玩」；同好：情境→话题→人→组织；陪玩：可预约→语音厅→更多；邀约/预约本地闭环；信任见 `Docs/TrustBehaviorModel.md` |

**`PlatformMetrics` 的正确角色：**

- 保留：系统字体 / 列表边距推导出的共享几何，以及构图比、轨可见比例。  
- 消费方优先是 **Design 组件**，不是 Features 随手引用。  
- Features 若必须引用，仅限货架编排已有 token（如 `sectionSpacing`），且不得再发明局部魔法数。

---

# 2 Visual Language

## 2.1 颜色（仅系统语义）

实现：`PlatformSurface` / `PlatformStatus`。

| Token | API | 用途 |
|-------|-----|------|
| `groupedPage` | `Color(.systemGroupedBackground)` | 发现页、列表底 |
| `canvas` | `Color(.systemBackground)` | 内容流、部分详情正文场景 |
| `elevated` | `Color(.secondarySystemGroupedBackground)` | 分组上的卡片面 |
| `groupedBlock` | `Color(.secondarySystemBackground)` | canvas 上的信息块 |
| `primary` / `secondary` / `tertiary` | SwiftUI 语义 | 主文 / 副文 / 更弱元信息 |
| `tint` | `.tint` / `.accentColor` | 认证标、主操作强调 |
| `success` / `warning` / `danger` | `.green` / `.orange` / `.red` | 名额、状态、破坏性操作 |
| Fill 占位 | `tertiarySystemFill` → `secondarySystemFill` | 无图封面渐变 |

**深色模式**：不另建色板。语义色与 Material 自动适配；媒体上的叠字使用 `.colorScheme(.dark)` 局部强制可读性。

## 2.2 圆角（Continuous，由 grid 推导）

| Token | 推导 | Shape | 用途 |
|-------|------|-------|------|
| `radiusMedia` | ≈ 1.5×grid | `mediaShape` | 缩略图、地图预览、小媒体 |
| `radiusPoster` | ≈ 1.75×grid | `posterShape` | 跟进/热场横卡、榜单海报 |
| `radiusCard` | ≈ 2.5×grid | `cardShape` | 发现大卡、处理遮罩 |
| `radiusEditorial` | ≈ 3×grid | `editorialShape` | 焦点大卡 |
| `fullBleed` | 0 | `fullBleedShape` | 精选 Hero 贴边 |

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
| 按钮 / chip 高度 | `.controlSize(.large/.regular/.small)` | 手写 horizontal/vertical padding 冒充系统控件 |
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
| 底栏参加区 | `safeAreaInset(edge: .bottom)`，按钮自行 padding，无整条 `.bar` |

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
| 我的竖海报内容轨 | 0.29 | 约三张 2:3 圈子海报 + 露出第 4 张 |

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

- `TabView` + 五 Tab：活动 / 搭子 / 社区 / 消息 / 我的  
- `.tabBarMinimizeBehavior(.onScrollDown)`（下滑收纳）  
- 各 Tab 内 `NavigationStack`

## 5.2 Title 模式

| 页面 | `navigationBarTitleDisplayMode` |
|------|----------------------------------|
| 活动发现 | `.inline`（Photos 式中间胶囊，不用 Large Title 抢 Hero） |
| 搭子选人 | `.inline`（「筛选」· 右侧「陪玩」；无穿顶 Hero） |
| 消息收件箱 | `.inline`（左通讯录 · 右加号；好友与群聊同列表） |
| 社区 Feed | `.inline`（左更多：收藏 / 赞过 / 我的分享 / 转发 / 公约 · 右发分享） |
| 活动详情 | 无大标题；工具栏 glass 操作 |
| Sheet / 二级列表 | `.inline` |
| 需要层级列表且无 Hero 时 | 可用 `.large`（非活动发现默认） |

## 5.3 Toolbar

**发现顶栏（Photos）**

- Leading：圆形 glass（分类菜单）  
- Principal：无（不展示地点/温度）  
- Trailing：圆形 glass（筛选等）  
- `controlSize: .regular`  

实现：`platformToolbarCircleStyle()`。

**搭子选人顶栏**

- Leading：系统文字按钮「筛选」（地区 / 性别 / 距离 / 兴趣 / 可约，同一 Form Sheet；有条件时 symbol fill）  
- Principal：无（默认同好；陪玩态由右侧按钮选中表达）  
- Trailing：单个文字按钮「陪玩」（点按进入陪玩，再点返回同好；选中时 semibold）  
- **一页一事**：同好页 = 情境找局 + 选人 + 组织；陪玩页 = 预约 + 语音厅  
- **同好页**：情境活动卡（`PlatformContinueCard`）→ 兴趣话题 chips → 双列状态人卡 → 兴趣组织  
- **陪玩页**：可预约双列 → 语音厅频道卡（Discord 感，中段）→ 更多陪玩  
- **人卡**：照片叠距离 / 共同兴趣；底部一句状态（`lookingFor` / 活跃）；同好无卡内 CTA，陪玩保留邀约  
- **邀约闭环（本地演示）**：绑活动发出 → `pending` 待回执 → 模拟接受/婉拒 → 邀请记录可「进群」  
- **预约闭环（本地演示）**：点选档期 → `pendingConfirm` 待接单 → `awaitingPayment` 可支付 → 支付后私聊；拒单为 `cancelled`  
- **信任**：详情 Form 挂 `TrustPublicProfileSections`（徽章 + 履约事实，无人对人星评）；「⋯」含不感兴趣 / 举报 / 拉黑；陪玩可有「平台认证」角标；底栏打招呼 + 邀约/预约（`activityDetailBottom*CTA`）。模型见 `Docs/TrustBehaviorModel.md`  
- **详情分区**：头图（3:4）→（可选）来源行 → 身份决策 → 资料信任行 → 基本资料 → 关于/服务 → 共同兴趣 → 组织 → 档期 → 信任档案 → 相关活动横滑轨  
- **成员入口**：组织 / 工会头像、语音厅麦位 → 半屏 `BuddyMemberProfileSheet`（`.confirm`，不 Zoom）；「查看全部」→ `BuddyMemberListSheet`（`.browser`）；完整资料经视图式 `NavigationLink` 推入并带 `BuddyProfileSource`  

**我的顶栏与身份区**

- 顶栏 Leading：账号 `Menu`；访客显示「创建账号」，登录后显示「账号」
- 顶栏 Trailing：系统设置入口
- 身份区：头像 + 昵称 + `@账号`，整行进入编辑资料
- 身份区下方：两个等宽大号系统按钮；左「开通会员」，右「我的钱包」
- **钱包**：顶部银行卡面主卡；下方 Form 为支付设置与交易流水。活动票 / 陪玩凭证在「我的」内容库以凭证卡展示，不堆在钱包里。
- **我的内容库**：活动 / 陪玩凭证均为 **长条凭证** 纵向叠放；Zoom / 推入展开页用 **Form**：票面头图（无叠字顶栏）+ 主文/副文 + 时间/日期等 `LabeledContent`；活动另有安排/细则，陪玩页内含联系 / 订单操作 / 补发等（不再跳「管理预约」）；右上角加入 Apple Wallet。无中间履约预览页。发现/活动 Tab 仍 Zoom 进完整详情。已作废票不出现在预览。

### PassKit 凭证链路（官方同构 · 本机闭环）

```
Source(PassSourceFactory)
  → Record(PassStore / PassRecord)
  → pass.json + assets(PassPackageBuilder)
  → Channels(PassDistribution: App / 导出 / Signed 落盘 / .pkpasses)
  → Update(PassUpdateWebService: register · list serials · get latest · 模拟推送)
  → System Wallet(PassKitLoader + AddPassToWalletButton)
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
| 系统 | `PassKitLoader` | 读 `SignedWalletPasses/{serial}.pkpass` |

签名证书与 Pass Builder **不进 App**；真机加入需开发者签名后放入 Signed 目录。

- 一级内容库：我的活动 / 我的发布 / 我的圈子 / 我的陪玩预约卡片轨；**不含收藏聚合**
- 收藏分域：社区分享 → 社区左上角 Menu「收藏的分享」；活动 → 活动页「更多」→「收藏的活动」
- 根页用 `platformTabBarHiddenWhenPushed(path.isEmpty)`；推入任一二级页后隐藏 Tab Bar
- Accessibility Dynamic Type：圈子海报卡可切图下堆叠；活动 / 陪玩 / 发布凭证以票面叠字为主（`ProfileCredentialCards`）

**详情顶栏**

- `.toolbarBackground(.hidden, for: .navigationBar)`  
- Trailing：`GlassIconMenu`（分享/更多）；搭子详情为系统 `Menu`（不感兴趣 / 举报 / 拉黑）  
- Zoom cover 预览态可有关闭钮  
- 隐藏 Tab Bar：`.platformSecondaryPage()`（封装 `.toolbar(.hidden, for: .tabBar)`）  
- 有 `NavigationPath` 的 Tab 根页：`.platformTabBarHiddenWhenPushed(path.isEmpty)`

## 5.4 Back Button

- 栈内详情：系统返回  
- `presentation == .zoomCover`：可隐藏返回，改用关闭  

## 5.5 打开详情

唯一推荐路径：

`NavigationLink(value:)` + `matchedTransitionSource` + `navigationTransition(.zoom)`  

封装：`ActivityZoomNavigationLink` / `activityZoomNavigationDestination`；搭子选人：`BuddyZoomNavigationLink` / `buddyZoomNavigationDestination`；组织：`circleDetailNavigationDestination`。

同一栈内同类型 `navigationDestination` 只保留栈根一份；二级页用 `…IfNeeded` / `circleDetailNavigationDestination`（Environment 判断已注册则跳过）。**Sheet 会继承呈现方 Environment**：自带 `NavigationStack` 的 Sheet 若要值跳组织 / 活动 Zoom / 搭子，须确认不会误继承「已注册」标记（见 `.cursor/rules/navigation-destination.mdc`）。

活动 Zoom 源 id 用 `ActivityZoomSource`（`activityID` + `slot` + `intent`），同一活动在多货架中不得撞号；用 `activityZoomSlot(_:)` 分槽。`intent`：`.browseDetail`（默认）→ 完整详情；`.participantPass`（「我的」长条凭证）→ `ActivityCredentialExpandedView` 展开完整票面。

Zoom 性能：转场期间不改源列表（浏览埋点延后）；详情相关卡不挂同 namespace Zoom；精选源 clip 与详情头图 `cardShape` 对齐；评论 / 相关轨首帧后再挂。

---

# 6 Card System

## 6.1 总表

| 类型 | 用途 | 比例 | 圆角 | 布局要点 |
|------|------|------|------|----------|
| **Featured Hero** | 发现顶栏精选 | 3:4 | 0 全宽 | 穿顶；底栏信息 + 参加；Zoom source |
| **Discover 竖大卡** | 兴趣/品类流 | 16:9 | 20 | 封面叠字或 a11y 图下堆叠 |
| **Continue / Hot 横卡** | 跟进、热场轨 | 16:9 | 14 | 轨宽 ~0.86；底栏同 Hero 结构 |
| **Poster 榜单** | 排名轨 | 3:4 | 14 | 轨宽 ~0.36；序号角标 |
| **Wallet Pass Stack** | 长条凭证堆 | 露条 = `walletPassStackHeaderPeek`（字阶）；堆高 = 条高+min((n−1)×peek, maxExtra) | strip | 系统 Wallet 同构叠放；Zoom → 展开票面 |
| **Wallet Pass Face** | 展开态履约票面 | 3:4 | poster | 头图认票 + 长条凭证码 + 地点/系统 glass 导航；安排/细则在票面下 Form；Wallet 在右上角 |
| **Profile Circle Poster** | 「我的圈子」预览 | 2:3 竖海报 | poster | `ProfileLibraryShelfCard`；圈子卡不显示「已加入」 |
| **Editorial 焦点** | 焦点大卡 | 4:5 | 24 | 轨宽 ~0.88 |
| **Person 搭子** | 双列状态人卡 | 网格 3:4 | discover | 无穿顶 Hero；叠距离/兴趣；一句状态；默认同好 / 右上「陪玩」 |
| **Situation 情境** | 活动横卡轨 | 16:9 | continue | 同好首幕；`PlatformContinueCard`；兴趣重合优先 |
| **Topic 话题** | 兴趣 chips | — | chip | `BuddyHobbyOption` ↔ `filter.hobby` |
| **Circle 组织** | 同好末幕 | 3:4 | poster | 轨宽 ~0.36；加入=进组织群；次于选人 |
| **Voice 语音厅** | 陪玩中段频道卡 | 横卡 ~0.86 | continue | Discord 感：厅名·麦位·在听·进厅 |
| **Detail Hero** | 详情头图 | 3:4 | card（圆角卡） | 安全区下；天气胶囊；相册控件 |
| **Detail Related** | 相关活动轨 | 16:9 横卡 | rail | Form 内横滑；露邻卡；非 List 行 |
| **Compose Cover** | 发布封面 | 高 160 | media | Sheet 表单内 |

活动紧凑横卡统一使用 `PlatformActivityCompactCard`：组件只负责 16:9 媒体、状态角标、两行标题、单行 meta 与 Dynamic Type；导航、Zoom 和轨宽由调用层负责。

## 6.2 卡内布局通则

```
[ 媒体 ]
  ├─ 左上：状态 / 社交角标（captionBadgeInset）
  └─ 底栏：左 Title/Time/Meta · 右 参加 CTA
```

- 常规字阶：叠字在媒体上（`onMedia` → 局部 dark）  
- Accessibility 大字：`prefersStackedCardChrome` → 图下信息区  
- Padding：水平/底 `contentInset`；信息行距 `cardInfoSpacing`；底栏间距 `cardFooterSpacing`

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
| **LazyVGrid / Grid** | 本版活动主路径不用；兴趣选择等再用 |
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

- **组件：** `PlatformConversationRow` + `PlatformToolbarAvatarButton`（单层 glass，内容铺满 `navigationBarButtonSide`）
- 编辑资料：`PhotosPicker` + `PlatformToolbarAvatarLabel` → `CommunityPhotoStore` / `avatarLocalName`
- **导航：** `NavigationLink`（隐藏 disclosure）+ `platformConversationListChrome()` / `platformConversationListRowChrome()`
- **禁止：** 在 List/`NavigationLink` 行内嵌 `UIListContentView`（会裁切头像）；勿同时叠行水平 insets 与 List contentMargins

### 外圈：页边（一个系统指数）

**真源：** `PlatformMetrics.contentInset` = 系统 Layout Margins（≥16pt）

| 场景 | API |
|------|-----|
| 收件箱 / 好友 / 消息二级 List | `platformConversationListChrome()` → plain + `canvas` + `contentMargins` = `contentInset`；行 `platformConversationListRowChrome()` 仅垂直；分区头 `PlatformMessagesSectionHeader` |
| 会话线程 ScrollView | `platformMessageThreadScrollMargins()` → `platformMessagePageMargins()` |
| 输入栏 / @ 条 | `platformMessagePagePadding()` |

### 内圈：控件间距

`bubbleContentPadding`（气泡/输入框内）；勿用 `contentInset` 当内边距。

### 气泡

- 己方 `.tint` + 对方 `secondarySystemFill`；大圆角 continuous
- **单聊**：无侧栏头像；**群聊**：仅对方左侧头像（聚类末条显示）
- 输入栏：「+」/ 发送 = `.glass` + `.large`；单行胶囊高度对齐同屏实测「+」（UIButton large glass 仅首帧回退）；工具间距 = 系统 `imageToTextPadding`；无底条
- 系统 Text Style；勿用活动页 glass CTA

## 7.3 空状态

统一 `ContentUnavailableView`（系统插画 + 文案）。发现货架空态的上下留白由 Design 使用 `emptyStateVerticalPadding`；Form/List 空态优先交给系统列表自身节奏。

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
| **Sensory** | `.sensoryFeedback` + `PlatformFeedback.announce` | 成功参加等 |
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

`PlatformFilterChip`：系统选中态；背景 `groupedPage`。用于筛选条，不堆装饰胶囊。

## 9.3 Badge

`PlatformMediaCaptionBadge` / `PlatformCaptionBadge`：

- 媒体左上状态（快满、已参加等）  
- `captionBadgeInset` + 水平/垂直 caption padding  
- tint 或 material chrome  

发起人徽章用 **SF Symbol**（认证 `checkmark.seal.fill`、会员 `crown.fill`、等级文案），不另造色块章。

## 9.4 Avatar

`PlatformListAvatarView`：

- 消息模块：`PlatformToolbarAvatarButton` / `Label` — **单层** `glassEffect(.circle)`，头像盘与 glass 同边长（`navigationBarButtonSide`），无内嵌小圆
- 编辑资料选图：`PhotosPicker` + `PlatformToolbarAvatarLabel`；保存仍走 `CommunityPhotoStore` → `avatarLocalName`
- 列表页边：`contentInset`（与顶栏 leading 对齐）；铺满后视觉边距不再被外圈 glass 撑开
- 其它模块默认：`PlatformListAvatarView` + `listAvatarSide`

## 9.5 Tag

兴趣/画像标签用系统文本流或轻量 wrap；颜色 secondary/tint，无描边贴纸风。

## 9.6 Search

系统 `.searchable` / `ContentUnavailableView.search`（消息等）；活动发现以分类 + 筛选 Sheet 为主。

## 9.7 Segment / Picker

分类用 `Picker` / `Menu` + `Label`（顶栏），不自绘 segmented 皮肤。

## 9.8 Toast

**禁止自定义 Toast。**  
`platformTransientFeedback` = 成功触觉 + `AccessibilityNotification.Announcement`。

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
   - **多色** `.multicolor` — 设置入口、筛选条件、分类 / 组织内容图标、公约列表  
3. **勿强制彩色**：Tab Bar、Toolbar Menu、Navigation chevron、破坏性 `role`、系统选中 tint。  
4. 与文字并排：优先 `Label`；列表行主操作除外。  
5. 权重跟随正文 Dynamic Type，不写死 pointSize（列表标准头像位图除外）。  
6. 镜像与本地化：使用系统可本地化符号名；颜色只用系统语义色与 `PlatformStatus`，无品牌色板。  

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

- 媒体叠字：局部 `.colorScheme(.dark)`。  
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
   ├─ [可选] Featured Hero（全宽 3:4，穿顶）
   └─ LazyVStack(spacing: sectionSpacing)
      ├─ Section Header（双行）
      ├─ 横滑轨 / 竖卡流 / 榜单 / 焦点…
      └─ …
Toolbar: Photos 圆形 + 胶囊；Trailing「更多」含发起 / 收藏的活动 / 筛选
Background: groupedPage
ScrollEdge: soft top
Zoom destination + slot 源；详情相关活动不参与同 namespace Zoom。`ActivityEngagementStore` 非观察对象，避免浏览埋点拆掉列表 Zoom 源。货架结果按输入指纹缓存；种子封面不用 GeometryReader，避免 Lazy 预取掉帧。
```

**一屏原则**：精选即品牌+主视觉；下方货架单一职责分区；不把筛选结果做成仪表盘。

## 12.2 活动详情 `ActivityDetailView`

```
Form
├─ Section 头图（clear background）
├─ Section 标题+决策（费用/时间/地点/名额/成员入口）  ← 同一 Section
├─ Section 发起人（header「发起人」）
├─ Section* 行程 / 费用 / 装备 / 须知（按 blueprint 排序）
├─ [可选] 管理 / 订单
├─ Section 活动讨论（转场后再挂）
└─ Section 相关活动（横滑轨，视图式推入）
+ safeAreaInset 底栏 CTA
+ toolbar glass
+ listSectionSpacing(.compact)
```

**转化漏斗**：Hero → 标题/pitch → 费用与名额 → 时间地点 → 发起人信任 → 参加。  
长文（行程/费用/准备/须知/讨论/相关）全部在折叠视口之下。

## 12.3 Sheet 族

| 流程 | Kind | 内容 |
|------|------|------|
| 发布/编辑 | `.form` | Form |
| 筛选 | `.filter` | Form |
| 成员/订单/支付 | `.browser` | List/Form；成员轻量卡与「全部成员」同档 |
| 参加成功 | `.confirm` | 短栈 |
| 举报活动 | `.form` | 原因 + 情况说明 + 证明材料；提交后 Alert 收尾确认 |
| 导航 App | `confirmationDialog` | Apple / 高德 / 百度等离散动作 |
| 分享活动 | `PlatformShareSheet` | 系统 `UIActivityViewController` 的 SwiftUI 桥接；iPhone 从底部呈现 |

## 12.4 Alert / Confirmation Dialog

只使用 SwiftUI 系统 `.alert` 与 `.confirmationDialog`，不自绘弹窗。

| 意图 | 系统容器 | 规则 |
|------|----------|------|
| 阻塞告知、错误、敏感词 | `.alert` | 单一「好的 / 知道了」；信息必须先读再继续 |
| 需理解后果的多结果决策 | `.alert` | 如「仅取消 / 取消并退款」；按钮角色明确 |
| 退出登录 / 注销账号 | `.alert` | 设置页账号后果确认；破坏动作 `.destructive`，必须有 `.cancel` |
| 删除预约记录 / 取消预约 | `.alert` | 陪玩订单详情后果确认；破坏动作 `.destructive`，必须有 `.cancel` |
| 退出组织 / 用户举报 / 拉黑 / 删除会话 | `.alert` | 后果确认或选择举报原因；破坏动作 `.destructive`，必须有 `.cancel` |
| 活动举报受理收尾 | `.alert` | Sheet 提交材料后弹出「已收到反馈」；单一「好的」 |
| 菜单触发的移出群聊 | `.confirmationDialog` | `titleVisibility: .visible`；破坏动作必须 `.destructive`，必须有 `.cancel` |
| 离散动作选择 | `.confirmationDialog` | 如选择导航 App；不使用 Form Sheet |
| 有输入、摘要、支付或下一步 | `.platformSheet(.confirm/.form/.browser)` | 不压缩为 Alert/Dialog |
| 非阻塞成功反馈 | `platformTransientFeedback` | 触觉 + VoiceOver；不弹成功 Alert |

破坏性动作不得从 `Menu`、`List` 行或详情按钮直接执行；先写入待确认状态，再由系统 Dialog 执行。

## 12.5 文案与状态

- 动作词与 `ActivityCardStatus` / `ActivityDetailCopy` 对齐。  
- 名额紧张用 warning 语义，不堆营销脚注。  

---

# Appendix A — 代码锚点

| 主题 | 文件 |
|------|------|
| 色 / 间距 / 字 / glass / avatar / 消息 chrome | `Design/PlatformSemantics.swift`、`Design/PlatformMessagesChrome.swift` |
| 货架卡 | `Design/PlatformCatalogCards.swift`、`Features/Activities/ActivityCards.swift` |
| 横滑布局 | `Design/DiscoverBrowseLayout.swift` |
| Zoom | `Design/ActivityZoomNavigation.swift`、`Features/Buddies/BuddyZoomNavigation.swift` |
| Sheet | `Design/PlatformSheet.swift` |
| 发现页 | `Features/Activities/ActivitiesView.swift` |
| 搭子选人 | `Features/Buddies/BuddiesView.swift`、`BuddyBrowseShelves.swift`、`BuddyGridCard.swift`、`BuddyPosterShelfCard.swift`、`BuddyOrgInfoViews.swift`、`BuddyMemberProfileSheet.swift`、`BuddyMemberListSheet.swift`、`BuddyMemberCopy.swift`、`BuddyVoiceHallViews.swift`、`BuddiesModeSwitch.swift`、`BuddyFilterSheet.swift`、`BuddyBookingSheet.swift`、`BuddyScheduleSlot.swift`、`BuddyCityCatalog.swift` |
| 详情 | `Features/Activities/ActivityDetailView.swift`、`ActivityDetailSections.swift` |
| Tab 折叠 | `ContentView.swift` |

---

# Appendix B — 设计评审清单

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
- [ ] 反馈是否无自定义 Toast？  
- [ ] Dynamic Type / 大字叠字是否已切 stacked？  
- [ ] 是否引入了禁止的装饰阴影或品牌渐变？  

---

*文档版本：系统级 = 业务少决策、多交给系统容器；命名间距保留给 Design 与系统读不到的几何。新增 UI 先选 Form/List/controlSize，再复用 Design 组件，最后才扩 `PlatformMetrics`。*

# 坐标系 · 导航、功能与结构框架

> 基于当前代码库梳理的产品架构说明。  
> 设计参照：[DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md)、[BuddiesProductPlan.md](BuddiesProductPlan.md)、[TrustBehaviorModel.md](TrustBehaviorModel.md)。  
> Apple 侧灵感：App Store Today / Photos Zoom / PassKit / Settings Form / TabView（iOS 26）等原生模式。

---

## 1. 一句话产品结构

| 板块 | 卖什么 | 一句话 |
|------|--------|--------|
| **活动** | 场 | 发现一场局 → 读懂 → 参加 / 支付 |
| **搭子** | 人 | 找人玩：免费同好 / 付费预约 |
| **广场** | 内容 | 活动相关图文分享与复盘 |
| **消息** | 关系与履约沟通 | 好友 / 群聊 / 通话 |
| **我的** | 身份与资产 | 账号、订单、凭证、信任、设置 |

入口链路：

```
未登录 → Launch（信封 / 登录）
已登录未完善 → Onboarding（兴趣）
已登录已完善 → TabView 五 Tab
```

实现：`坐标系App` → `ContentView` → `AppModel` + 各 Feature `@Observable` Model。

---

## 2. 导航框架

### 2.1 一级：系统 TabView

| Tab | 符号 | 根视图 | 顶栏标题 |
|-----|------|--------|----------|
| 活动 | `calendar` | `ActivitiesView` | 动态分类（如「猜你喜欢」）+ 可点标题菜单 |
| 搭子 | `person.2` | `BuddiesView` | 「搭子」 |
| 广场 | `bubble.left.and.bubble.right` | `CommunityView` | 「广场」 |
| 消息 | `message` | `MessagesView` | 「消息」（未读 badge） |
| 我的 | `person.crop.circle` | `ProfileView` | 「我的」 |

顶栏共用 chrome：`Design/PlatformTabRootChrome.swift`  
（`inlineLarge` 大标题 + 空 `principal` + `platformTabRootToolbar`）

参考 Apple：**iOS TabView**（系统折叠 / Liquid Glass）、**Photos / Mail** 式 `inlineLarge` 标题。

### 2.2 二级：每 Tab 独立 NavigationStack

每个 Tab 根页各自持有 `NavigationStack(path:)`（多为 `TabNavigationState`），目的地在**栈根注册一次**。

| 模式 | 类型 / Helper | 用途 | Apple 参照 |
|------|---------------|------|------------|
| 活动 Zoom | `ActivityZoomSource` + `activityZoomNavigationDestination` | 发现卡 → 详情；凭证长条 → 展开票面 | Photos Zoom / matched geometry |
| 搭子 Zoom | `BuddyZoomRoute` + `buddyZoomNavigationDestination` | 人墙卡 → 资料 | 同上 |
| 圈子浏览 | `CircleBrowseRoute` + `circleBrowseNavigationDestination` | 圈子信息 / 成员 | 程序化 `path`，避免 Lazy 多层 Link |
| Sheet 内栈 | `independentNavigationSheetChrome` | Sheet 清继承标记后再注册目的地 | Sheet 继承 Environment 陷阱 |
| 广场 | `NavigationPath` + 类型目的地 | 帖子 / 关联活动 / 内容库 | 标准 `navigationDestination` |
| 我的 | `ProfileRoute` | 钱包、订单、凭证、信任、设置 | Settings 式推入 |

**硬规则（与代码一致）：** 同一 `NavigationStack` 内同类型 `navigationDestination` 只保留栈根一份；Sheet 勿误用父栈「已注册」标记。

### 2.3 三级：Sheet / 半模态

| 场景 | 典型 Sheet |
|------|------------|
| 活动 | 发起 / 编辑、筛选、参加确认、支付、成功、举报、评论 |
| 搭子 | 筛选、邀约、预约下单、圈子加入、语音厅相关 |
| 广场 | 发分享、更多操作 |
| 消息 | 发起聊天、加好友、资料卡 |
| 我的 | 编辑资料、登录 / 创建账号、退款申请 |

### 2.4 跨 Tab 深链（`AppModel`）

| API | 切到 | 效果 |
|-----|------|------|
| `openActivity(_:)` | 活动 | 打开活动详情 |
| `openMessages(...)` | 消息 | 打开会话（可聚焦消息 / 通话） |
| `openMyBookings(...)` | 我的 | 陪玩凭证列表或单条详情 |
| `beginComposeActivity()` / `beginEditActivity` | 活动 | 打开发起 / 编辑 |
| `openActivityGroupChat(for:)` | 消息 | 活动 → 群聊 |
| 通知深链 | 路由分发 | 活动 / 会话 / 预约 |

参考 Apple：**UNNotification** 深链进对应场景；多 Tab 用 pending 字段消费，避免跨栈硬推。

---

## 3. 核心板块与功能分类

### 3.1 活动（场）

**职责：** 发现与参加线下 / 组局面。

| 能力类 | 功能 |
|--------|------|
| 发现 | 分类标题菜单（猜你喜欢为首）、精选 Hero、推荐货架、搜索式筛选 |
| 详情 | Form 决策信息（时间地点费用名额）、评论、相关活动 / 圈子 |
| 转化 | 参加确认、演示支付、加入活动群 |
| 主办 | 发起 / 编辑、管理名额与改期、取消与退款演示 |
| 凭证 | 参加后活动凭证（「我的」夹内查看 / Wallet） |

**结构节奏：** App Store Today 货架（Hero + 分区轨）→ Photos Zoom 进详情 → Settings Form 决策。

**关键路径：** `Features/Activities/`、`ActivitiesModel`、`Design/ActivityZoomNavigation.swift`

---

### 3.2 搭子（人）

**职责：** 找人玩。活动卖场，搭子卖人（见 [BuddiesProductPlan.md](BuddiesProductPlan.md)）。

```
找人玩
├─ 免费（同好）  打招呼 / 邀约去某场
└─ 预约（陪玩）  选档期 / 支付 / 履约
```

| 能力类 | 免费路径 | 预约路径 |
|--------|----------|----------|
| 浏览 | 精选横滑 + 附近双列墙 | 意图入口、热门、排行榜、更多服务者 |
| 匹配 | 兴趣 / 距离 / 活跃排序 | 擅长、档期、价、认证 |
| 行动 | 打招呼、邀约活动 | 私信、快速下单、履约凭证 |
| 次要 | 兴趣圈子 | 语音厅 |

**关键路径：** `Features/Buddies/`、`BuddiesModel`、`BuddyZoomNavigation.swift`

---

### 3.3 广场（内容）

**职责：** 活动相关种草 / 复盘流，**不做找人**。

| 能力类 | 功能 |
|--------|------|
| 信息流 | 图文帖列表、详情、点赞 / 收藏 / 评论 / 转发 |
| 创作 | 发分享（可关联活动） |
| 内容库 | 收藏的分享、赞过的、我的分享 / 转发、社区公约 |

**结构节奏：** 系统 `List` 信息流（接近 Apple News / 系统 Feed 密度），非货架。

**关键路径：** `Features/Community/`、`CommunityModel`

---

### 3.4 消息（沟通）

**职责：** 关系网与履约沟通通道。

| 能力类 | 功能 |
|--------|------|
| 收件箱 | 好友会话 + 群聊同一列表；搜索会话 / 历史 |
| 通讯录 | 好友列表、好友请求（角标） |
| 会话 | 文本时间线、快捷模版、群昵称等 |
| 关系 | 加好友（UID）、发起私聊 / 建群 |
| 通话 | 通话会话记录 / 演示页 |

**结构节奏：** Messages 式列表 + 会话栈；顶栏通讯录入口。

**关键路径：** `Features/Messages/`、`MessagesModel`、`PlatformMessagesChrome`

---

### 3.5 我的（身份与履约资产）

**职责：** 账号、商业、凭证、信任、合规设置。

| 能力类 | 功能 |
|--------|------|
| 身份 | 头像昵称、编辑资料、兴趣完善、访客 / 登录 |
| 商业 | 会员、钱包、订单（活动 + 陪玩） |
| 凭证 | 活动凭证夹、陪玩预约凭证、活动邀约；可展开 / 加 Wallet |
| 社交资产 | 圈子、内容库入口等 |
| 信任 | 行为信用私有看板、公开片段、安全签到、真人认证 |
| 设置 | 隐私、通知、青少年、退出等合规运维 |

**结构节奏：** Settings 式 `List` / `Form`；凭证贴近 **PassKit**（夹 → 展开票面 → 系统 Wallet）。

**关键路径：** `Features/Profile/`、`Features/Trust/`、`Services/PassKit/`、`Services/Trust/`

---

### 3.6 横切能力（非 Tab，全局支撑）

| 板块 | 作用 | 主要落点 |
|------|------|----------|
| **Launch** | 品牌信封、本地登录 | `Features/Launch/` |
| **信任账本** | 行为事件 → 四轴信用（非星级墙） | `Services/Trust/` + [TrustBehaviorModel.md](TrustBehaviorModel.md) |
| **钱包 / 支付 / 退款** | 演示支付、Pass、退款策略 | `WalletStore`、`RefundFlow`、PassKit |
| **位置 / 天气** | 附近排序、问候天气 | `LocationService`、`GreetingWeatherStore` |
| **通知** | 提醒与深链 | `NotificationService`、`AppNotificationRouter` |
| **同步编排** | 报名 / 发帖等域事件驱动群聊与统计 | `AppDomainEvent`、`AppSyncOrchestrator` |
| **设计系统** | 语义色、货架几何、Zoom / 票面组件 | `Design/`、`DESIGN_SYSTEM.md` |

---

## 4. 工程结构（代码地图）

```
坐标系/
├── ContentView.swift          # AppTab、AppModel、TabView、深链
├── Design/                    # 平台 chrome、货架卡、Zoom、票面、Tab 根标题
├── Features/
│   ├── Activities/            # 活动发现与详情
│   ├── Buddies/               # 找人（免费 / 预约）
│   ├── Community/             # 广场
│   ├── Messages/              # 消息
│   ├── Profile/               # 我的
│   ├── Trust/                 # 信任 UI
│   └── Launch/                # 启动与登录
├── Models/                    # 领域模型、持久化快照
└── Services/                  # 仓库、支付、PassKit、信任、通知、位置
Docs/
├── BuddiesProductPlan.md
├── TrustBehaviorModel.md
└── AppArchitecture.md         # 本文
```

### 数据层概览

| 层 | 内容 |
|----|------|
| 枢纽 | `AppModel`：选中 Tab、各域 Model、用户 / 鉴权、pending 深链 |
| 域 Model | `ActivitiesModel`、`BuddiesModel`、`CommunityModel`、`MessagesModel` |
| 实体 | `Activity`、`DiscoverBuddyItem`、圈子 / 语音厅、帖、会话、订单与凭证记录等 |
| 持久化 | 本地 Repository + `AppPersistence`（演示级，非生产后端） |

当前为 **本地演示架构**：样例数据 + 本地持久化 + 演示支付 / 退款；领域边界已按上表切开，便于日后接真实 API。

---

## 5. 用户主路径（漏斗）

```mermaid
flowchart LR
  subgraph discover [发现]
    A[活动货架] --> AD[活动详情]
    B[搭子人墙] --> BD[人 / 陪玩详情]
    C[广场帖] --> CD[帖详情]
  end
  subgraph convert [转化]
    AD --> J[参加 / 支付]
    BD --> Chat[打招呼 / 下单]
  end
  subgraph fulfill [履约]
    J --> G[活动群 / 凭证]
    Chat --> M[消息 / 预约凭证]
    G --> P[我的 · 凭证夹]
    M --> P
  end
```

**转化原则（设计系统）：** 详情首屏只留决策信息；长说明下沉；每屏只保留一个 Primary CTA（见下节）。

---

## 6. 各界面最重要操作（Primary CTA）

按「这一屏最该完成的事」定主按钮；实现上详情底栏用 `activityDetailBottomPrimaryCTA`，次要用 Secondary。

### 6.1 Tab 根页

| 界面 | 最重要操作 | 位置 / 说明 |
|------|------------|-------------|
| **活动** | **参加**（卡上） | Hero / 货架卡右下角；顶栏「发起活动」为供给侧次要主入口，「筛选」为条件入口 |
| **搭子 · 免费** | **打招呼** | 人卡 / 详情沟通入口；「邀约一起」为进阶转化 |
| **搭子 · 预约** | **预约 / 快速下单** | 卡上预约、详情底栏主钮 |
| **广场** | **发分享** | 右上角 `+`；空态同款 |
| **消息** | **进入会话** | 点列表行；右上「通讯录」是关系入口，不是本屏主转化 |
| **我的** | **编辑资料 / 身份行** | 点头像昵称进编辑；「开通会员」「我的钱包」为商业次级入口 |

### 6.2 关键详情 / 转化页

| 界面 | 最重要操作 | 角色 / 状态变化 |
|------|------------|-----------------|
| **活动详情** | **参加**（免费参加 / 确认支付等） | 已参加 → **进入活动群**；主办 → **进入活动群**（「管理活动」次要）；已结束且相关 → **分享体验** |
| **活动卡（发现）** | **参加** | 满员 → **加入候补**；已参加 → 展示「已参加」 |
| **同好详情** | **邀约一起**（主）+ **打招呼**（次） | 底栏双钮，邀约是转化主钮 |
| **陪玩详情** | **快速下单 / 预约陪玩**（主）+ **打招呼**（次） | 不可约时主钮禁用，先打招呼 |
| **帖子详情** | **互动**（赞 / 评 / 藏） | 顶栏更多；创作主入口在广场根页 |
| **会话详情** | **发送消息** | 底栏输入 / 发送 |
| **预约下单 Sheet** | **确认下单 / 支付** | 选档后确认 |
| **邀约 Sheet** | **发送邀约** | 选活动后确认 |
| **参加确认 / 支付** | **确认参加 / 支付** | 活动转化闭环 |

### 6.3 「我的」履约子页

| 界面 | 最重要操作 |
|------|------------|
| **活动 / 陪玩凭证展开** | **加入 Apple Wallet**（展示履约）；取消 / 退款为破坏性次要 |
| **订单列表** | **打开订单详情**（查看 / 退款入口） |
| **信任看板** | **去认证 / 签到** 等推进信用的动作 |
| **设置** | 无单一主 CTA；保存类在各编辑子页 |

### 6.4 漏斗对照

| 域 | 主路径 |
|----|--------|
| 活动 | 卡上参加 → 详情参加 → 进群 → 凭证 / Wallet |
| 搭子 · 免费 | 打招呼 →（可选）邀约一起 → 消息 |
| 搭子 · 预约 | 预约 / 快速下单 → 支付 → 消息 / 凭证 |
| 广场 | 发分享 → 互动 |
| 消息 | 进会话 → 发送 |

文案锚点：`ActivityCardStatus` / `ActivityDetailCopy`、`BuddyDetailCopy`、`CommunityCopy`、`MessagesCopy`、`ProfileDashboardCopy`。

---

## 7. Apple 官方模式对照（借鉴说明）

以下为**产品 / 交互参照**，非逐文件开源复刻：

| 坐标系落点 | Apple 模式 / 文档方向 |
|------------|----------------------|
| 活动货架 + Hero | [App Store] Today 分区与大卡节奏 |
| Zoom 进详情 | Photos / SwiftUI `matchedTransitionSource` + `navigationTransition(.zoom)` |
| 可点大标题分类 | SwiftUI `toolbarTitleMenu` / `ToolbarTitleMenu`（Invites 等系统应用同类交互） |
| 详情与设置页 | Settings：`Form` / `List` / `LabeledContent` |
| 凭证与加钱包 | PassKit：票面、夹、`AddPassToWalletButton` |
| Tab 根标题 | `toolbarTitleDisplayMode(.inlineLarge)` + 系统 scroll edge |
| 消息列表 | Messages：会话列表 + 未读、系统 List 密度 |
| 信任与隐私 | 行为信用私有 / 公开展示分层（对齐 HIG 隐私最小化，非星级打卡墙） |

设计约束见 `DESIGN_SYSTEM.md`：SwiftUI First、无品牌色板、系统容器优先、禁止自定义 toast / 装饰 glow。

---

## 8. 核心板块清单（速查）

1. **活动发现与参加** — 场、支付、群、凭证  
2. **搭子找人** — 免费同好 / 付费预约、圈子、语音厅  
3. **广场内容** — 分享流与内容库  
4. **消息与关系** — 会话、通讯录、通话  
5. **我的账户与履约资产** — 身份、订单、凭证、钱包、会员  
6. **信任与安全** — 行为账本、认证、签到  
7. **启动与鉴权** — Launch、本地登录、Onboarding  
8. **平台基建** — Design System、深链、通知、位置、域事件同步  

---

## 9. 与周边文档的关系

| 文档 | 回答什么 |
|------|----------|
| 本文 `AppArchitecture.md` | **整 App 导航、板块地图与各屏主 CTA** |
| `Vision.md` | **产品愿景 V1**（让一起玩，变得简单、自然、可信） |
| `BuddiesProductPlan.md` | 搭子 Tab 产品第一性原理与 IA |
| `TrustBehaviorModel.md` | 信任账本事件与公私展示 |
| `DESIGN_SYSTEM.md` | 视觉 / 组件 / 反模式与实现锚点 |

---

*文档随代码演进；若 Tab 增减、深链 API 或主 CTA 文案变更，以 `ContentView.swift` / `AppModel`、各 Feature 根视图与上表文案锚点为准。*

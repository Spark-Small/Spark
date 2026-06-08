# Spark 五 Tab 页面结构（一级 / 二级细化）

> **Status:** Living document — 与当前 `main` 代码一致。  
> **Last updated:** 2026-06-07  
> **Related:** [TYPOGRAPHY.md](TYPOGRAPHY.md) · [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · `.cursor/rules/ios-swiftui-layout.mdc`

**文档层级**

| 层级 | 内容 |
|------|------|
| L1 | Tab 一级页 — 区域与组件 |
| L2 | Push / Sheet / Cover — 子页结构 |
| **L3** | 线框级 — 间距、字号、尺寸、Safe Area、门控文案、状态 |

---

## L3 全局设计 Token

| Token | 值 | 代码常量 `SparkLayoutMetrics` |
|-------|-----|------------------------------|
| `standardHorizontalPadding` | **16** | Feed / Inbox / 详情水平边距 |
| `compactVerticalPadding` | **8** | Section inset、toolbar chip |
| `sectionVerticalPadding` | **12** | 区块垂直间距 |
| `minimumTouchTarget` | **44** | HIG 最小触控（`.sparkMinimumTouchTarget()`） |
| `sparkCardCornerRadius` | **20** | `RoundedRectangle.sparkCard` |
| `inboxModuleInnerPadding` | **14** | 模块卡内边距（与 `actionCardInnerPadding` 同值） |
| Match 玻璃卡 | R**28** / maxW **420** | `matchCardCornerRadius` / `matchCardMaxWidth` |
| Inbound 格子 | R**20** / 媒体 **140** | `inboundCellCornerRadius` / `inboundMediaHeight` |
| iPad Split | **320** | `SparkAdaptiveLayout.sidebarIdealWidth` |
| iPad 发现卡 | **480** | `SparkAdaptiveLayout.discoverCardMaxWidth` |
| iPad 搜索可读宽 | **640** | `SparkAdaptiveLayout.contentReadableMaxWidth` |

**实现：** `Packages/SparkDesignSystem/Sources/SparkDesignSystem/SparkLayoutMetrics.swift`

### L3 语义表面

**主 Tab 平铺流（社区动态 / 消息 / 活动 Inbox）**

| 层级 | API | 说明 |
|------|-----|------|
| 列表画布 | `.sparkFlatTabListStyle()` | `Color(.systemBackground)` |
| 列表行 | `.sparkFlatTabListRow()` | 全宽行 · 行间 `Divider` |
| 空态 | `.sparkContentUnavailableCanvas()` | 同 `systemBackground` |
| 固定顶栏 | `.sparkPinnedControlBar()` | 搜索/筛选 inset（`.bar`） |

**二级列表（设置 / 账号 / 部分 Browse）**

| 层级 | API | 说明 |
|------|-----|------|
| 画布 | `.sparkScreenListStyle()` | `systemGroupedBackground` |
| 模块行 | `.sparkSemanticListRow()` | 玻璃模块 + 行 chrome |

**实现：** `SparkSemanticSurface.swift`

### L3 全局字号（系统语义样式）

Spark **无自定义字体**；全部使用 SF Pro 语义 Text Style + Dynamic Type。完整规范见 **[TYPOGRAPHY.md](TYPOGRAPHY.md)**。

| 层级 | SwiftUI | 字重 | 前景色 | 用途 |
|------|---------|------|--------|------|
| Section 标题 | `.subheadline` | `.semibold` | `.secondary` | Feed / Inbox 区块头 |
| 行主标题 | `.body` / `.subheadline` | `.semibold` | `.primary` | 列表行、卡片作者 |
| 正文 | `.body` / `.subheadline` | regular | `.primary` | 详情、简介 |
| 元数据 | `.caption` | regular–`.semibold` | `.secondary` / `.accentColor` | 统计、关系、标签 |
| 辅助 | `.caption2` / `.footnote` | regular | `.secondary` | 时间、hint、脚注 |

**Tab 根导航：** 默认 `.navigationBarTitleDisplayMode(.large)` via `SparkScreenContainer`  
**例外 — 社区 Tab：** 无中间导航标题；`ToolbarItem(.principal)` 分段「动态 \| 识人 \| 我的社区」  
**沉浸 Tab（喜欢）：** `.toolbarBackground(.hidden)` + `.black` 背景  
**搜索：** 全局入口在「我的」Toolbar 🔍（非社区 Tab）

**玻璃 / 材质优先级：** `sparkGlassSurface` → `sparkGlassControl` → `.bar`（禁止 `.background(.ultraThinMaterial)` 与 `Color.opacity` 假玻璃）


## 导航总览

```
SparkRootView
├── 未登录 → LoginView（全屏，非 Tab）
└── 已登录 → SparkMainTabView（TabView × 5）
    ├── 喜欢    LikesRootView
    ├── 活动    ActivityRootView
    ├── 社区    CommunityRootView
    ├── 消息    MessagesRootView        [Tab Badge: 未读数]
    └── 我的    ProfileRootView

全局 Modal（AppRouter / PaywallRouter）
├── GlobalPresentation.authRequired（Sheet）
├── PaywallView（fullScreenCover）
└── Deep Link 消费 → 切换 Tab + pending 状态
```

**平台规则**

| width | 容器 |
|-------|------|
| compact（iPhone） | `NavigationStack` push / Sheet |
| regular（iPad） | `NavigationSplitView` 左列表 + 右详情 |

**设计系统**（Presentation 层统一）

- 玻璃/控件：`sparkGlassSurface` · `sparkGlassControl` · `.buttonStyle(.sparkPressable)`
- 图片：`SparkCachedRemoteImage`
- 照片文字区：`sparkPhotoTextScrim()`
- Tab 根：`SparkScreenContainer(embedding: .none)`
- Loading：`sparkLoadingAccessibilityLabel` / `SparkRetryUnavailableView`

---

## Tab 1 — 喜欢 `SparkTab.likes`

**需登录** · Coordinator：`LikesCoordinator` · 跨 Tab：`SparkTabOrchestrator.openMatchConversation`

### L1-1 发现流 `LikesRootView` → `likesDiscoverStack`

| 区域 | 组件 | 说明 |
|------|------|------|
| 顶栏 inset | `LikesIntentModeBar` | 分段：**配对 / 交朋友**；切换触发 `reloadWithPreferences` |
| 导航栏左 | 偏好按钮 | `slider.horizontal.3` → Sheet 偏好 |
| 导航栏右 | Inbound 入口 | `heart.text.square` + 数量角标；Deep Link `likesInbound` |
| 导航栏右 | 更多 Menu | 撤回上一位 |
| 进度 | `LikesFeedProgressBar` | 今日已看 / 池容量 |
| 主体 | `DiscoverCardStackView` | 全屏卡片栈；左右滑 Like/Pass；上滑资料；右滑超阈值开场白 |
| 卡片媒体 | `DiscoverCardMediaView` | 多图 `TabView` 横滑；视频；捏合缩放 |
| 卡片信息 | `DiscoverCardView` | 底部 `sparkPhotoTextScrim`：姓名·年龄·地点·每日精选·标签 |
| 底栏 | actionBar | Pass · Spark/加好友 · Like |
| 背景 | `.black` | 沉浸发现体验 |

**状态：** `idle` · `loading` · `loaded` · `empty`（今日看完 / 无推荐）· `failure`（重试）

**iPad regular：** `NavigationSplitView` — 左栏 `LikesInboundListView(sidebar)`，右栏发现流。

---

### L2 / Modal — 喜欢 Tab 内

| ID | 视图 | 呈现 | 触发 |
|----|------|------|------|
| L2-1 | `LikesPreferencesSheet` | Sheet `.medium` | 工具栏偏好 / 空态 CTA |
| L2-2 | `LikesInboundListView` | Sheet 或 Split 左栏 | 工具栏 Inbound / Deep Link |
| L2-3 | `DiscoverProfileSheet` | Sheet | 卡片上滑 / 点按资料区 |
| L2-4 | `LikesOpenerPickerSheet` | Sheet `.medium` | 右滑超阈值 / 长按流程 |
| L2-5 | `LikesReportSheet` | Sheet | 资料页举报 |
| L2-6 | `LikesViewerProfileGateSheet` | Sheet | 资料未完善 Gate |
| L2-7 | `MatchSheetView` | **fullScreenCover** | 互相 Like 成功 |

#### L2-2 Inbound 列表布局

```
NavigationStack（Sheet 模式）
└── LazyVGrid 2 列
    └── InboundLikeCell × N
        ├── SparkCachedRemoteImage 头像
        ├── Premium 模糊 + 锁（门控）
        └── Like 回赞按钮
└── safeAreaInset(bottom): Premium CTA（有模糊项时固定）
```

#### L2-7 Match 弹层布局

```
ZStack
├── .thickMaterial 全屏遮罩
└── ScrollView → 居中玻璃卡片（max 420pt）
    ├── 双头像 ZStack 交叉叠放（SparkCachedRemoteImage）
    ├── 标题 / 副标题
    ├── SparkQuestionCard × 2（破冰问答）
    ├── 开场白横向 ScrollView chip（sparkGlassControl）
    ├── 次 CTA：共同活动 / 推荐活动 / 咖啡局
    ├── 主 CTA：发消息 → orchestrator.openMatchConversation
    └── 稍后再说
```

#### L2-3 资料 Sheet 布局

```
NavigationStack + List
├── Section：TrustBadge · 活动次数 · Bio · 地点 · 共同活动
├── Section：SparkQuestionCard 列表（可 Like 回答）
└── Toolbar：举报
```

**首次：** `LikesOnboardingSheet`（`showOnboarding`）— 垂直滑动 / Inbound / 消息说明。

---

## Tab 2 — 社区 `SparkTab.community`

**需登录** · 默认 Tab · Coordinator：`CommunityCoordinator`

### L1-1 社区 Feed `CommunityRootView` → `communityFeedShell`

| 区域 | 组件 | 说明 |
|------|------|------|
| 容器 | `SparkScreenContainer` | 空 `navigationTitle` |
| 工具栏 principal | 分段 `Picker` | 「动态 \| 我的社区」`maxWidth: 280` |
| 工具栏 trailing | 发帖 | `SparkFeatureFlags.isCommunityPostingEnabled` |
| 分页 `.feed` | `TabView(.page)` | Plan A 相关帖 → `CommunityPostCard` |
| 分页 `.groups` | 已加入横滑 + 探索列表 | `MyCommunitiesCarousel` · `CommunityRowCell` · `CommunityJoinPromptCard` |
| 搜索 | — | 「我的」Tab Toolbar 🔍 → `SearchRootView`（非本 Tab） |

**compact 布局：** `TabView(.page)` 双分页；动态 `LazyVStack(spacing: 0)` + 卡片内 `Divider`。

**regular 布局：** `NavigationSplitView` — 左栏 ideal **320pt** · 右 `splitDetail` 帖子/社区详情。

**状态：** `idle` · `loading` · `loaded` · `empty` · `failure`

---

### L2 — Push / Split 详情

| ID | 视图 | 层级 | 布局要点 |
|----|------|------|----------|
| L2-1 | `CommunityPostDetailView` | Push / Split 右栏 | 关联活动行 · 作者 · 正文 · 评论区 · `CommunityReplyComposer` · Toolbar 举报 |
| L2-2 | `CommunityDetailView` | Push / Split 右栏 | 社区主页：Header · 活动列表 · 帖子 · 成员入口 |

#### L2-1 帖子详情

```
ScrollView + safeAreaInset(bottom: CommunityReplyComposer)
├── postHeader（作者 · 关联活动行 · 图集 · 正文 · 标签）
└── repliesSection（评论 · N + CommentRow）
Toolbar → CommunityReportSheet
```

#### L2-2 社区详情

```
ScrollView / List
├── CommunityDetailHeaderView（封面·简介·成员预览）
├── 活动区块 → onOpenActivity
├── 帖子列表 → onOpenPost
└── Toolbar → 成员 Sheet
```

---

### L2 — Modal / Sheet

| ID | 视图 | 触发 |
|----|------|------|
| M-1 | `CommunityRecapDraftSheet` | 活动结束 Recap Deep Link / `pendingRecapActivityID` |
| M-2 | `CommunityReportSheet` | 帖子详情举报 |
| M-3 | `CommunityMembersSheet` | 社区详情成员 |
| M-4 | `CommunityMemberProfileSheet` | 人发现 / 成员点头像 |

#### L2-1 帖子卡片 `CommunityPostCard`（Feed 内）

```
VStack
├── authorRow：SparkCachedRemoteImage 头像 · 关系 Badge
├── mediaRegion：SparkCachedRemoteImage 16:9 或纯文字背景
├── linkedActivityBanner（有关联活动时）
├── actionRow：Like · 评论数 · 分享 icon
└── contentRegion：正文 + 更多
```

---

## Tab 3 — 消息 `SparkTab.messages`

**需登录** · Tab Badge：`FetchUnreadCountUseCase` → `messagesTabWithBadge`

### L1-1 统一 Inbox `MessagesRootView` → `inboxShell`

| 区域 | 组件 | 说明 |
|------|------|------|
| 容器 | `SparkScreenContainer` | **无中间导航标题**（Tab 项已标识「消息」） |
| 工具栏 | 未读 Badge + **全部已读** | `MarkMessagesReadUseCase` |
| Action Items | 已移至活动 Tab | 见 Tab 4 L1 |
| 分段 | Toolbar `Picker(.segmented)` | **消息** / **群聊** · `maxWidth: 280` · 横向分页 |
| 工具栏 | **＋ Menu** | 发起聊天 · 扫一扫 · 全部已读（有未读时） |
| M-1 | `MessagesNewChatPickerView` | 发起聊天 · 搜索 · 选人开 DM |
| 配对行 | `ConversationRow` | 含未开聊新配对（`新配对，打个招呼`） |
| 群聊行 | `ConversationRow` | 仅进行中 / 即将开始；**已结束活动不展示** |

**compact：** `NavigationStack` → push `ConversationDetailView`  
**regular：** `NavigationSplitView` — 左 Inbox 列表，右会话详情

**状态：** `idle` · `loading` · `loaded` · `empty` · `failure`

---

### L2-1 会话详情 `ConversationDetailView`

| 区域 | 组件 | 说明 |
|------|------|------|
| top inset | `groupActivityBanner` / `dmContextHeader` | 群聊关联活动摘要；DM 上下文 |
| 主体 | `messageList` | 气泡 `ConversationMessageBubbles` |
| bottom inset | `composerBar` | 文本输入 + 发送 |
| 错误 | sendError 文案 | 发送失败 inline |

**进入时：** 若有未读 → 自动 `markConversationRead`

**跨 Tab：** Banner 点活动 → `onOpenActivity(activityID)` → 活动 Tab · DM 点头像 → `UserContextSheet`（`onOpenUserProfile`）

---

## Tab 4 — 活动 `SparkTab.activity`

**需登录** · Coordinator：`ActivityCoordinator` · 双轴 **发现 | 我的**（无 Feed Premium 行锁）

### L1-1 活动 Inbox `ActivityRootView` → `activityListShell`

| 区域 | 组件 | 说明 |
|------|------|------|
| 容器 | `SparkScreenContainer` | 无大标题 · `navigationTitle: ""` · `.inline` |
| 工具栏 principal | 分段 `Picker` | 「发现 \| 我的」 |
| **发现** | `ActivityBrowseSegmentContent` | 内联逛局列表；主办 tier / RSVP / 分类信任信号 |
| **我的** | Inbox 列表 + 即将行动 | `InboxActionItemsListSection`；横向 chips `ActivityListFilter` |
| 工具栏 Menu（我的） | 地图 / 提醒设置 / 创建活动 | 地图为 Sheet（非独立 Tab） |
| 列表行 | `ActivityInboxListRow` | RSVP 状态角标；无 Premium 遮罩 |

**compact：** `NavigationStack` push 详情  
**regular：** `NavigationSplitView` 左列表右详情

**状态：** 同上五态 + `showsFilterEmptyState`

---

### L2 — Push 详情 `ActivityDetailView`

| Section | 内容 |
|---------|------|
| 生命周期 | 已取消/已结束标签 |
| 邀请信息 | 主办 · Bio · 时间 · 地点 · 人数 |
| 主办其他活动 | NavigationLink 列表 |
| 参与者 | 头像列表 · Host 视角管理 |
| 活动说明 | 描述正文 |
| 邀请好友 | 复制链接 |
| RSVP | 报名 / 候补 / 取消 |
| Host 区 | Announce · Edit · Cancel · Feedback |
| 底部 | 群聊 · 导出日历(EventKit) · **写 Recap** → 社区 Tab |

**Modal from 详情：** `EditActivityView` · 举报 Sheet · Announce Sheet · 再办一局 Create

---

### L2 — Modal（从 L1 工具栏）

| ID | 视图 | 说明 |
|----|------|------|
| M-1 | 地图 Sheet | **我的** 分段工具栏；`ActivityMapView` |
| M-2 | `CreateActivityView` | 创建表单；可预填 `CreateActivityDraft`（匹配咖啡局） |
| M-3 | `notificationSettingsSheet` | `ActivityNotificationSettingsSection` |
| M-4 | `EditActivityView` | 从详情编辑 |

**Premium（主办工具）：** 审批 RSVP、群发通知等 Host 操作门控 `PremiumFeature.hostTools`（非浏览行锁）

**RSVP 后链路：** 群聊 Thread（`ensureActivityGroupThread`）+ 本地提醒（`ActivityNotificationRegistrar`）

---

## Tab 5 — 我的 `SparkTab.profile`

**无需登录即可进入 Tab** · 子功能部分需登录 · Coordinator：`ProfileCoordinator`

### L1-1 个人中心 `ProfileRootView`

| Section | 内容 |
|---------|------|
| **头部** | 头像占位 · 昵称 · `TrustScoreRingView` · `TrustBadgeView` |
| **Premium** | CTA 按钮（`isPremiumPaywallEnabled`）→ 全局 Paywall |
| **信任认证** | 完成认证 / 已完成 状态 → Wizard Sheet |
| **发现** | NavigationLink → **搜索** |
| **法律** | 隐私政策 · 用户协议（`SparkLegalLinks`） |
| **关于** | ICP 备案号 |
| **账号** | 退出登录（确认 Dialog）· 注销账号（二次确认 Dialog） |

**状态：** `idle` · `loading` · `loaded` · `failure`

---

### L2-1 搜索 `SearchRootView`（Push from 我的）

| 态 | 布局 |
|----|------|
| 空 query | List 建议词（`defaultSuggestions`） |
| 有 query · loading | ProgressView |
| 有 query · loaded | `SearchResultRow` 列表（人/活动/社区） |
| 有 query · empty | ContentUnavailableView |
| failure | SparkRetryUnavailableView |

**`.searchable`** 常驻导航栏 Drawer · 选结果 → `onSelectSearchResult` → 跨 Tab Deep Link

---

### L2-2 信任认证 `TrustVerificationWizardView`（Sheet）

```
NavigationStack + List
├── TrustScoreRingView
├── Section 认证进度：手机 / 实名 / 活体（L1–L3 MVP）
└── 逐步 Verify CTA
```

---

## 全局二级页面（跨 Tab）

| 页面 | 呈现 | 触发 |
|------|------|------|
| `LoginView` | 替换 Tab  shell | 未登录 / 登出后 |
| `PaywallView` | fullScreenCover | Premium 门控 / Deep Link `paywall` |
| `UserContextSheet` | Sheet | 活动/社区/消息点头像 · `GET /v1/users/{id}/context` |
| `GlobalPresentation.authRequired` | Sheet | 未登录访问需登录 Tab 或 Deep Link |

### LoginView（App 级，非 Tab）

```
NavigationStack + ScrollView
├── 标题 / 说明
├── 邮箱 + 密码
├── 登录按钮
├── Sign in with Apple
└── #if DEBUG 演示 hint
```

---

## Deep Link → 页面映射

| 路由 | 目标页面 |
|------|----------|
| `tab(likes/community/messages/activity/profile)` | 切换 Tab |
| `likesInbound` | 喜欢 Tab → Inbound Sheet |
| `conversation(threadID)` | 消息 Tab → L2 会话 |
| `communityPost(postID)` | 社区 Tab → L2 帖子详情 |
| `communityRecap(activityID)` | 社区 Tab → Recap Sheet |
| `activityDetail(activityID)` | 活动 Tab → L2 详情 |
| `paywall(placement)` | 全局 Paywall |

未登录 → 暂存 `pendingDeepLinkAfterAuth` → 登录后应用。

---

## 页面清单索引

| Tab | 一级 (L1) | 二级 Push | 二级 Modal |
|-----|-----------|-----------|------------|
| 喜欢 | 发现流 | — | 偏好·Inbound·资料·开场白·举报·Gate·Match |
| 社区 | Feed | 帖子详情·社区详情 | Recap·举报·成员·资料预览 |
| 消息 | Inbox | 会话详情 | — |
| 活动 | Inbox 列表 | 活动详情 | 逛局·创建·编辑·提醒设置 |
| 我的 | 个人中心 | 搜索 | 信任 Wizard |
| 全局 | — | — | 登录·Paywall·需登录提示 |

---

---

## L3 线框级 Spec — Tab 1 喜欢

### L1-1 发现流

```
┌─ Safe Area Top ─────────────────────────────────────┐
│ [Nav hidden bg]  ⚙️偏好          ❤️Inbound(角标) ⋯  │
├─ safeAreaInset(top) ────────────────────────────────┤
│ ┌─ ultraThinMaterial ─────────────────────────────┐ │
│ │  [配对 | 交朋友]  segmented  H:8 V:16 inset    │ │
│ └─────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────┤
│ ProgressBar  H:3  accent gradient  pad H16 top4    │
│ ┌─────────────────────────────────────────────────┐ │
│ │                                                 │ │
│ │           DiscoverCardStack (containerRelative) │ │
│ │           iPad maxW:480 centered                │ │
│ │                                                 │ │
│ └─────────────────────────────────────────────────┘ │
├─ safeAreaInset(bottom) ─ actionBar ─────────────────┤
│     (Pass 56)   (Spark 60 / Friend 52)   (Like 64) │
│              HStack spacing:20  pad V:12            │
└─ Safe Area Bottom ──────────────────────────────────┘
   背景: .black · 下拉 refreshable
```

| 元素 | 字号 | 尺寸 / 间距 | 备注 |
|------|------|-------------|------|
| 意图分段 | system segmented | pad H16 V8 | 切换 → `reloadWithPreferences` |
| 进度条 | — | 高 3pt | a11y value `seen/pool` |
| 姓名 | `.title2.bold` | overlay pad 20 | scrim 底 |
| 年龄 | `.title3.semibold` | 与姓名 baseline 对齐 | optional |
| 地点 | `.subheadline` secondary | `· 城市` | optional |
| 精选 badge | `.caption.semibold` | pad H8 V4 · glass capsule | `为你精选` |
| 兴趣 tag | `.caption` | 最多 4 个 · H6 · glass capsule | 横滑 |
| Bio | `.subheadline` | lineLimit 2 | |
| 资料 hint | `.caption` secondary | | `上滑查看资料` |
| scrim 底留白 | — | bottom **88** (match) / **120** (friends) | 避开 actionBar |
| Pass | `.title2.semibold` | **56×56** circle glass | a11y `跳过` |
| Spark | `.title2.semibold` | **60×60** yellow gradient |  charges=0 → Paywall |
| Friend | `.title3.semibold` | **52×52** circle glass | 交朋友模式 |
| Like | `.title2.semibold` | **64×64** pink gradient | 成功 → Match cover |
| Inbound 角标 | `.caption2.bold` | pad 4 · pink circle | offset x6 y-6 |
| 工具栏图标 | — | `.foregroundStyle(.white)` | 沉浸 Nav |

**手势：** 左滑 Pass · 右滑 Like · 上滑资料 Sheet · 右滑超阈值开场白 · 卡片内多图横滑 · 双指缩放

**空态：** `ContentUnavailableView` 白字 · CTA「调整发现偏好」「查看喜欢你的人」

**iPad regular：** Split 左栏 Inbound（ideal **320**）· 右栏发现流 · 工具栏无 Inbound 按钮（已在侧栏）

---

### L2-2 Inbound 列表

```
NavigationStack · title「喜欢你的人」
┌─ ScrollView ─────────────────────────┐
│ LazyVGrid 2col  spacing:12  pad:16   │
│ ┌──────────┐ ┌──────────┐            │
│ │ media140 │ │ media140 │            │
│ │ info bar │ │ 🔒 blur  │            │
│ └──────────┘ └──────────┘            │
└──────────────────────────────────────┘
├─ safeAreaInset(bottom) ──────────────┤
│ hint footnote secondary              │
│ [解锁喜欢你的人] borderedProminent    │
│ pad H16 V12 · background .bar        │
└──────────────────────────────────────┘
```

| 元素 | 规格 | Premium 门控 |
|------|------|--------------|
| 格子 | R20 · 媒体 **140** 高 | 模糊项显示 |
| 信息条 | pad **10** · `.bar` 底 | |
| 姓名 | `.subheadline.semibold` | 模糊 → `••••` |
| 开场白 | `.caption` secondary ×2 | 模糊隐藏 |
| Spark 边框 | yellow gradient stroke 2 | 非模糊 + intensity=spark |
| 锁 overlay | `.title2` lock + redacted | tap → Paywall |
| Footer hint | `.footnote` secondary | `开通 Premium 查看完整资料` |
| Footer CTA | borderedProminent fullWidth | `解锁喜欢你的人` |

---

### L2-7 Match 全屏

| 区域 | 规格 |
|------|------|
| 遮罩 | `.thickMaterial` fullScreen |
| 外层 Scroll | pad H**20** V**32** |
| 玻璃卡 | pad **24** · maxW **420** · R**28** glass |
| 头像 | **88×88** circle · 交叉 offset ±**32** · stroke 3 |
| 标题 | `.title.bold` center · `互相心动了！` |
| 副标题 | `.subheadline` secondary · `你和 %@ 互相喜欢` |
| 问题区 | section `.subheadline.semibold` · `SparkQuestionCard` ×2 |
| 开场白 chip | `.subheadline` · pad H14 V10 · glass capsule · 选中 accent stroke 2 |
| 次 CTA | `.bordered` fullWidth | 共同活动 / 推荐活动 / 三人咖啡局 |
| 主 CTA | `.borderedProminent` fullWidth | `发消息` |
| .dismiss | `.borderless` | `稍后再说` |

---

### L2-1 偏好 Sheet

- 呈现：`.presentationDetents([.medium])`
- 内容：`Form` / List 筛选字段（距离、年龄、意图等）
- 保存 → dismiss + reload

### L2-3 资料 Sheet

| Section | 内容 |
|---------|------|
| Header | `TrustBadgeView` · 活动次数 · Bio · 地点 · 共同活动 |
| Questions | `SparkQuestionCard` 可 Like |
| Toolbar | 举报 → `LikesReportSheet` |

---

## L3 线框级 Spec — Tab 2 社区

### L1-1 一级页（分段双分页）

```
SparkScreenContainer navigationTitle: ""  inline
Toolbar principal: Picker segmented「动态 | 我的社区」maxW 280（Phone 最近通话样式）
Toolbar trailing: 发帖（isCommunityPostingEnabled）
搜索: 「我的」Tab Toolbar 🔍 → SearchRootView

内容区: `TabView(.page)` ↔ `selectedSegment` 双向同步（可横向滑动切换；`accessibilityReduceMotion` 时直接 switch）

分页 .feed（动态）:
  ScrollView / Split List → CommunityPostCard × N（Plan A 相关帖过滤）

分页 .groups（我的社区）:
  Section 已加入 → MyCommunitiesCarousel（64 圆统一 · 探索更多同尺寸 tertiary + plus · spacing 12 · pad H16）
  Section 探索社区 → CommunityRowCell × N（48 圆头像 · 未加入）
  未加入时 → CommunityJoinPromptCard
```

**默认分段：** 有已加入社区 → `feed`；否则 → `groups`

**Section Header：** `.subheadline.semibold` · pad H16 V10 · `.secondary`

**MyCommunitiesCarousel 字号：** 社区名 `.caption.semibold` · 成员数 `.caption2` secondary

#### CommunityPostCard 像素级（Threads / Instagram 流式）

```
Feed 列表: LazyVStack spacing 0 · 无外层 H pad · 无玻璃卡片
┌─ authorRow  pad H16 top12 bottom8 ─────────────────┐
│ (avatar 36×36)  L1: name .body.semibold · community .footnote  time .caption2│
│  L2: 和你去了 XX .footnote.semibold accent（熟人优先，可 2 行）│
│  L3: 📅 关联活动 · 局后随拍（recap；与 L2 同活动不重复）│
├─ mediaRegion (有图)  edge-to-edge phone / inset iPad ┤
│  4:5 fill maxPixel 1280 · tap → detail              │
├─ actionRow  pad H16 V8  spacing 20 ─────────────────┤
│  ♥ count  💬 count  .subheadline · 0 不显示数字     │
├─ caption (有图)  pad H16 bottom12 ──────────────────┤
│  **Name** + body .body lineLimit 3 · [更多] .footnote│
│  #tags .footnote（关联活动已在作者区，不在底部）      │
├─ text body (无图)  .body 直接在作者下 max 6 行 ──────┤
└─ Divider ───────────────────────────────────────────┘
```

**iPad Split：** 左 List selection · 右 PostDetail / CommunityDetail · sidebar ideal **320**

> 首页不再使用 `PeopleDiscoveryCard`、FilterBar、底部「所有社区」长列表 — 见 [TYPOGRAPHY.md § 社区](TYPOGRAPHY.md#社区)。

---

### L2-1 帖子详情

```
├─ ScrollView  pad H16 V12  spacing 12 ─────────────┤
│ author .body.semibold primary                       │
│ 📅 关联活动 .footnote（与 Feed 同行，可点进活动）    │
│ body .body                                          │
│ replyCount .footnote secondary（>0 时）              │
│ Section「回复」.subheadline.semibold secondary       │
│ CommentRow: name .subheadline.semibold + body .body │
├─ safeAreaInset bottom ──────────────────────────────┤
│ CommunityReplyComposer TextField .body              │
└─────────────────────────────────────────────────────┘
Nav: inline title · Toolbar 举报
```

---

### L2-2 社区详情

```
Header: 封面 120 · 图标 72 overlap · 名 .title3.semibold · 统计 .footnote
简介 .body secondary · Join .subheadline.semibold minTouch 44
成员头像叠层 28 · +N .caption2
Segmented「最近活动 | 帖子」maxW 280
活动行: calendar secondary · title .body.semibold · 时间 .footnote
帖子行: author .subheadline.semibold · body .body · 互动 .footnote
行间 Divider
```

### L2-3 我的社区 · 探索列表（groups 分段）

```
CommunityRowCell: 头像 48 · 名 .body.semibold · 统计/bio .footnote
无玻璃卡片 · chevron · 行间 Divider（indent 60）
CommunityJoinPromptCard: title .subheadline.semibold · 说明 .footnote · .regularMaterial
```

---

## L3 线框级 Spec — Tab 3 消息

### L1-1 Inbox

```
SparkScreenContainer navigationTitle "" · inline（无大标题）
Toolbar principal: Segmented「消息 / 群聊」maxW280
Toolbar trailing: plus.circle Menu（未读数仅 Tab Bar Badge）
TabView(.page) · 各页 List · .sparkScreenListStyle · refreshable
```

| 分页 | 行规格 |
|------|--------|
| **消息** | `ConversationRow` · 新配对 preview `新配对，打个招呼` |
| **群聊** | 行规格同「消息」；仅可见群聊；已结束 / 归档不出现 |

#### ConversationRow

```
HStack spacing 14 · pad V2 (inboxRowVerticalPadding)
(avatar 48 + UnreadBadge topTrailing)  name .body.semibold / .body · time .caption2 tertiary
             preview .subheadline primary/secondary
```

**Swipe：** 未读 → `标为已读` blue · `不显示` · `删除` destructive

**iPad Split：** List selection tag threadID · 右 `ConversationDetailView`

---

### L2-1 会话详情

```
Nav inline title = peerDisplayName
├─ safeAreaInset(top) ────────────────────────────────┤
│ 群聊: VStack title .subheadline.semibold            │
│       countdown .caption secondary  .bar pad H16 V10 │
│ DM:  横滑 sharedActivity chips glass sparkCard      │
│       chip pad H12 V8 · caption2 + caption.semibold │
├─ ScrollView LazyVStack spacing 12 pad H16 V12 ──────┤
│ ConversationMessageBubbles                          │
│  文本: body pad H14 V10 · glass R20                   │
│  富卡片: pad 14 · sparkCard                         │
├─ safeAreaInset(bottom) ───────────────────────────────┤
│ sendError .caption red H16 (optional)               │
│ MessagesComposerBar: photo · TextField .body        │
│   .quaternary R20 · send .borderless .title         │
│ .bar pad H16 V10 (composerFieldVerticalPadding)     │
└─────────────────────────────────────────────────────┘
```

进入有未读 → 自动 `markConversationRead` · 发送成功 sensoryFeedback

---

## L3 线框级 Spec — Tab 4 活动

### L1-1 Inbox

```
SparkScreenContainer navigationTitle:"" inline
Toolbar principal: Segmented「活动 / 地图」maxW280 · TabView(.page) ↔ segment
地图分段: ActivityInboxMapView（点标记 → ActivityMeetupMapView）
Toolbar trailing ⋯ Menu: 逛局 / 活动提醒 / 创建活动
┌─ 横向 filter chips ScrollView pad H16 V8 ───────────┐
│ Section 即将行动 (action items)                     │
│ List ActivityInboxListRow                          │
│ 空态: ContentUnavailableView + 逛局/创建 CTA        │
└────────────────────────────────────────────────────┘
```

#### ActivityInboxListRow（Meetup 列表式）

```
HStack spacing 12 · pad V4
(date tile 52)  category .caption.semibold uppercase
                title .body.semibold
                status capsules .caption.medium glass
                weekday .subheadline secondary · time .subheadline secondary
                location mappin .subheadline secondary
                host .caption secondary
                [lock.fill trailing if locked]
```

| 行内 | 字号 | 备注 |
|------|------|------|
| 日期块 | 月 `.caption2.semibold` · 日 `.title3.bold` · `.quaternary` R10 | 无 `starts_at` → calendar 占位 |
| 分类 | `.caption.semibold` uppercase secondary | |
| RSVP / 生命周期 | `.caption.medium` glass capsule pad H6 V2 | 非锁定 |
| 标题 | `.body.semibold` | 锁定 → secondary |
| 日期 / 时间 | `.subheadline` secondary ×2 | `detailWeekdayDateLine` + `detailTimeLine` |
| 地点 | `.subheadline` secondary | 有 `location_name` 时 |
| 主办 | `.caption` secondary | `主办 %@` |
| 锁 | `.body.semibold` lock.fill | index>0 且非 Premium |
| 行 pad | V**4** | a11y 锁定：`%@，需订阅` |

**Premium 门控：** Inbox 第 2 条起 `isLocked` · Browse 同理 blur + tap Paywall

---

### L2 活动详情（Meetup 式 List Sections）

| Section | 内容 | 字号 |
|---------|------|------|
| Hero | 分类 · 标题 · 状态 capsule | `.caption.semibold` · `.title2.bold` |
| 时间与地点 | 日期/时间 · 地图预览 · 人数 | `.body.semibold` · `.subheadline` |
| 主办 | 头像 44pt · 主办名 · bio | `.body.semibold` · `.subheadline` |
| 底部 RSVP | `ActivityDetailRSVPBar` | 待回复时 `safeAreaInset` |
| 主办其他活动 | NavigationLink rows | `.subheadline.medium` + `.caption` |
| 参与者 | 头像 HStack · Host 管理 | |
| 活动说明 | 描述 | `.body` |
| 邀请好友 | 复制链接 | |
| RSVP | 报名/候补/取消 | borderedProminent |
| Host | Announce · Edit · Cancel | Menu / Button |
| 底部 | 群聊 · 日历 · 写 Recap | Recap → 社区 Tab |

---

### M-1 逛局 Sheet

```
NavigationStack Sheet
categoryPicker + timeWindowPicker  pad H V8
List 活动行（同 InboxRow 规格）
Premium: 模糊 + lock · tap → Paywall
navigationDestination → ActivityDetail(context: .discover)
```

### M-3 提醒设置 Sheet

- `.presentationDetents([.medium])`
- `Form` + `ActivityNotificationSettingsSection`
- inline Nav · Done 关闭

---

## L3 线框级 Spec — Tab 5 我的

### L1-1 ProfileRootView

```
NavigationStack > SparkScreenContainer「我的」embedding:.none
List .sparkScreenListStyle
```

| Section | 布局 |
|---------|------|
| **头部** | VStack spacing **16** · center · clear row bg |
| 头像 | SF `person.crop.circle.fill` **72pt** hierarchical accent | 占位，未接上传 |
| 昵称 | `.title2.semibold` · `Spark 用户` | |
| 信任环 | `TrustScoreRingView` fullWidth | |
| Badge | `TrustBadgeView` | |
| **订阅** | `sparkles` Label · Premium | flag 关闭则隐藏 |
| **信任认证** | CTA 或 `checkmark.seal.fill` secondary | pending → Wizard Sheet |
| **发现** | NavigationLink → Search | |
| **法律** | Link 隐私 / 协议 | |
| **关于** | LabeledContent ICP | |
| **账号** | destructive ×2 | confirmationDialog ×2 |

---

### L2-1 搜索 Push

| 态 | UI |
|----|-----|
| 空 query | List Section「建议」· clock icon · minHeight **44** |
| loading | ProgressView center + a11y |
| loaded | `SearchResultRow`: kind `.caption.semibold` · title `.headline` · subtitle `.subheadline` ×2 · chevron |
| empty | ContentUnavailableView |
| iPad | `sparkReadableWidth(640)` |

`.searchable` placement `.navigationBarDrawer(always)` · prompt `搜索 Spark`

---

### L2-2 信任 Wizard Sheet

- `NavigationStack` + `List`
- 顶：`TrustScoreRingView`
- Section 逐步：手机 / 实名 / 活体
- Verify CTA per step

---

## L3 线框级 Spec — 全局

### LoginView（非 Tab）

```
NavigationStack large title「登录 Spark」
ScrollView VStack spacing 24 pad 24
  subtitle .title3.semibold
  email/password fields spacing 12 · glass sparkCard
  登录 borderedProminent
  divider
  Sign in with Apple
背景 .background · sparkDismissesKeyboardOnScroll
```

### PaywallView

- `fullScreenCover` via `SparkMainTabView`
- placement 来自 Deep Link / 门控 tap

### GlobalPresentation.authRequired

- Sheet `.medium`
- pad **24** · title `.title2.semibold` · message secondary · OK borderedProminent

---

## L3 状态机速查（全 Tab 通用）

| 状态 | 视觉 | 交互 |
|------|------|------|
| idle / loading | 居中 `ProgressView` + sparkLoading a11y | 阻塞内容 |
| loaded | 主布局 | 全交互 |
| empty | `ContentUnavailableView` | 上下文 CTA |
| failure | `SparkRetryUnavailableView` | 重试按钮 |
| 分页 loading | 底部 ProgressView + loadingMore a11y | 不阻塞 |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-07 | 初版：五 Tab 一级/二级页面逐页布局细化 |
| 2026-06-07 | L3：线框级间距/字号/Safe Area/Premium 门控文案 |
| 2026-06-07 | 即将行动移至活动 Tab；消息页配对统一为 ConversationRow |

# Spark 功能清单与系统模块

> **Status:** Living document — reflects shipped code on `main`.  
> **Last updated:** 2026-07-02  
> **Related:** [ARCHITECTURE.md](ARCHITECTURE.md) · [PACKAGES.md](PACKAGES.md) · [API_CONTRACT.md](API_CONTRACT.md)

---

## 1. 产品形态

Spark 是 **iOS 17+ / Swift 6** 消费社交 App，核心体验为：**活动发现 · 陪玩搭子 → 社区信任沉淀 → 消息协调 → 个人中心**，Tab 间通过 `SparkTabOrchestrator` 编排联动（Nexus W0–W6）。

### 1.1 五 Tab 主界面

| Tab | Package | 游客 | 需登录（写操作） | 说明 |
|-----|---------|------|------------------|------|
| 活动 | SparkActivity | ✅ 发现 | RSVP / 主办 / 我的活动 | 默认 Tab；顶栏 **发现 \| 地图** |
| 搭子 | SparkBuddy | ✅ 浏览 | 预约 / 提供方入驻 | 陪玩列表 · 信任认证 · 标准套餐 |
| 社区 | SparkCommunity | ✅ Feed 只读 | 发帖 / 回复 | Activity Recap 晒图流 |
| 消息 | SparkMessages | ❌ | 全部 | 统一 Inbox、DM / 群聊 |
| 我的 | SparkProfile + SparkSearch + SparkTrust + SparkBuddy | ✅ 登录 CTA | 资料 / 搜索 / 信任 / 陪玩入驻 | 未登录显示 `GuestProfilePromptView` |

- 默认 Tab：**活动 · 发现**（游客）/ 登录后 `finishAuthentication` 仍落活动 Tab
- **取消登录 Sheet** 保留 `pendingCreateActivityDraft`（`AppRouter.cancelAuthPresentation` 不清草稿）
- **搜索**入口在「我的」Tab 内（需登录）
- **写操作门控**：报名、发帖、消息、创建活动 → `GlobalPresentation.authRequired`（Sheet 登录）；读公开活动/帖子/深链无需登录
- **Debug** 构建：`SPARKPremiumPaywallEnabled = NO`（冷启动不锁 Feed）；Release 仍为 `YES`

---

## 2. SPM 模块一览（15 packages）

```
Spark (App target)
├── SparkAppShell       — 壳层、Tab、路由、Deep Link、跨 Tab 编排
├── SparkAuth           — 登录 / 会话 / 注销
├── SparkActivity       — 活动 CRUD / RSVP / 提醒 / 发现
├── SparkBuddy          — 陪玩浏览 / 预约 / 提供方入驻与收益
├── SparkCommunity      — 社区 Feed / 帖子 / 举报
├── SparkMessages       — Inbox / 会话 / 活动邀请
├── SparkProfile        — 「我的」Tab 资料摘要
├── SparkSearch         — 全局搜索
├── SparkTrust          — 信任分 / L1–L3 认证向导
├── SparkPayments       — StoreKit 2 / Premium 门控
├── SparkNotifications  — Push Payload / Device Token 上传
├── SparkDesignSystem   — Liquid Glass UI 原语
├── SparkNetworking     — HTTPClient / APIClient / 远程图片缓存
├── SparkPersistence    — Keychain
└── SparkCore           — 公共类型、错误、日志、法务链接
```

### 2.1 分层约定（每个 Feature Package）

```
Presentation  →  View, ViewModel (@MainActor @Observable), Coordinator
Domain        →  Models, UseCase, Repository protocol
Data          →  DTO, Live*, Mock*, Mapper
```

- DI：`Spark/App/CompositionRoot.swift` — Mock vs Live 由 `APIConfiguration.usesMockBackend` 决定
- 详见 [ARCHITECTURE.md](ARCHITECTURE.md)

### 2.2 基础设施模块

| Package | 职责 |
|---------|------|
| **SparkCore** | `UserID`, `AppError`, `RetryPolicy`, `SparkLog`, `SparkLegalLinks`, `MockURL` |
| **SparkNetworking** | `HTTPClient` actor, `APIClient`, `AuthorizationInterceptor`, `RemoteImageCache`, 图片降采样 |
| **SparkPersistence** | `KeychainManager`, `KeychainAccessTokenProvider`, `InMemoryKeychainManager`（测试） |
| **SparkDesignSystem** | `sparkGlassSurface/Control`, `SparkCachedRemoteImage`, `SparkTabBottomAccessory`, `SparkToolbarSegmentedPicker`, `SparkFilterChipBar`, `SparkScreenContainer`, 无障碍 loading |
| **SparkNotifications** | Activity / Community / Messages Push Payload；`LiveDeviceTokenUploader` / `NoOpDeviceTokenUploader` |

### 2.3 应用壳层

| 类型 | 主要类型 |
|------|----------|
| 根视图 | `SparkRootView`, `SparkMainTabView` |
| 路由 | `AppRouter`, `SparkTab`, `DeepLinkParser`, `DeepLinkRoute` |
| Tab Chrome | `SparkMainTabChrome`, `ActivityTabChrome`, `CommunityTabChrome`（iOS 26.1+ bottom accessory） |
| 编排 | `SparkTabOrchestrator`, `SparkTabDependencies` |
| 全局呈现 | `GlobalPresentation`（登录 / Paywall / Info Sheet） |

---

## 3. 用户功能清单

### 3.1 认证 — SparkAuth

| 功能 | 实现 | API |
|------|------|-----|
| Sign in with Apple | ✅ 官方 `SignInWithAppleButton` | `POST /v1/auth/apple` |
| 手机号 + 短信 OTP 登录 | ✅ | `POST /v1/auth/phone/otp` · `POST /v1/auth/phone/verify` |
| 手机号找回密码 | ✅ | `POST /v1/auth/phone/password-reset` |
| 邮箱 + 密码登录 | ✅（保留 API） | `POST /v1/auth/email` |
| 邮箱注册 | ✅ `SignUpView`（无登录页入口；主路径为手机 OTP 隐式注册） | `POST /v1/auth/register` |
| 会话恢复 | ✅ Keychain | `GET /v1/auth/session` |
| 登出 | ✅ 清空手机表单 + 深链暂存 | `POST /v1/auth/sign-out` |
| 账号注销 | ✅ Profile 二次确认 | `POST /v1/auth/account/delete` |
| 登录态门控 | ✅ Tab / Deep Link Sheet | — |

**UseCases:** `RestoreSession`, `SignInWithApple`, `SendPhoneOTP`, `SignInWithPhoneOTP`, `ResetPasswordWithPhoneOTP`, `SignInWithEmail`, `SignUpWithEmail`, `SignOut`, `DeleteAccount`

---

### 3.2 社区 — SparkCommunity

| 功能 | 说明 |
|------|------|
| Tab Feed | 帖子 + 人发现综合流 |
| 帖子详情 | 标题、作者、回复列表 |
| 关联活动 | Banner → 跳转活动 Tab |
| 成员 / 资料 | `CommunityMembersSheet`, `CommunityMemberProfileSheet` |
| 关系 Badge | 关注 / 熟人等关系展示 |
| Recap 草稿 | 活动结束后 → 社区发帖草稿 Sheet |
| **举报帖子** | `CommunityReportSheet` |
| 发帖 UI | **已落地**（`isCommunityPostingEnabled` FAB）；Mock 媒体上传 + Live API 待扩展 |

**UseCases（8）:**  
`FetchCommunityTabExperience`, `FetchCommunityPosts`, `FetchCommunityPost`, `FetchCommunityDetailBundle`, `CreateCommunityPost`, `CreateCommunityReply`, `CreateCommunityRecap`, `ReportCommunityPost`

**Deep Links:** `communityPost(postID)`, `communityRecap(activityID)`

---

### 3.3 消息 — SparkMessages

#### Inbox（统一列表）

| 区块 | 说明 |
|------|------|
| 会话列表 | DM + 活动群聊 + 未开聊配对（`MessagesInboxSorting.unifiedDMConversations`）；未读 badge |
| 配对展示 | 新配对与已有 DM 同一 `ConversationRow`，preview「新配对，打个招呼」 |

#### 会话

| 功能 | 说明 |
|------|------|
| 单聊 / 群聊 | `ConversationDetailView` |
| 发消息 | 文本消息发送 |
| 会话上下文 | 关联活动摘要等 |
| 活动邀请响应 | Accept / Decline |
| 全部已读 | Mark read（全局 / 单 Thread） |

**UseCases（12）:**  
`FetchInbox`, `FetchUnreadCount`, `MarkMessagesRead`, `FetchMessageThreads`, `FetchThreadMessages`, `SendThreadMessage`, `MarkThreadRead`, `FetchConversationContext`, `EnsureDirectMessageThread`, `DismissActionItem`, `RespondToActivityInvite`

**Deep Link:** `conversation(threadID)`

---

### 3.4 活动 — SparkActivity

| 功能 | 说明 |
|------|------|
| 发现 Browse | `ActivityBrowseContent` + `ActivityBrowseFilter`（时间/分类 chip）；`GET /v1/activities/browse` |
| 地图 | 登录用户 Inbox 活动地图；游客登录 CTA |
| 我的活动 | Sheet：`ActivityRootView+MyActivities`（Inbox 筛选 + Action Items） |
| 活动 Inbox | 主办/参加 Feed；Action Items（`InboxActionItemsListSection`） |
| 详情 | Meetup 式 Scroll；RSVP 经 Tab Bottom Accessory（iOS 26.1+）或 `safeAreaInset` 回退 |
| 创建 / 编辑 / 取消 | Host CRUD；`ActivityCreateTemplateStore` 快捷/保存模板 |
| RSVP / Waitlist | 报名、候补、候补提升 |
| Host Announce | 向参与者群发通知 |
| Host Feedback | 活动结束反馈 |
| 举报活动 | Report flow |
| 日历导出 | EventKit 写入系统日历 |
| 本地 / 远程提醒 | `ActivityNotificationRegistrar`；`SPARK_ENABLE_PUSH` 条件下 APNs |
| 群聊联动 | RSVP 后创建活动 Thread |
| Community Recap | 详情页触发 Recap 草稿 |

**UseCases（14）:**  
`FetchActivityFeed`, `FetchActivityBrowsePage`, `FetchActivityDetail`, `FetchActivitiesByHost`, `CreateActivity`, `UpdateActivity`, `CancelActivity`, `UpdateActivityRSVP`, `JoinActivityWaitlist`, `PromoteFromWaitlist`, `AnnounceActivity`, `SubmitHostFeedback`, `ReportActivity`

**Deep Link:** `activityDetail(activityID)`

---

### 3.5 搭子 — SparkBuddy

| 功能 | 说明 |
|------|------|
| 浏览列表 | 服务分类 chip + 筛选 sheet（计费 / 排序 / 认证） |
| 详情 | 信任认证 · AI 匹配 · 套餐 · 评分维度 · 评价摘录 |
| 预约 | `BuddyBookingSheet` + 托管支付（Mock / Staging escrow 标记） |
| 语音预聊 | `BuddyPreChatSheet`（Mock 服务） |
| 平台聊天 | 跳转消息 Tab 私信 |
| 安全中心 | 定位 / SOS / 行程说明 |
| 提供方 | Profile 入驻申请 · 收益页（认证通过后） |

**UseCases:** `FetchBuddyListings`, `FetchBuddyListingDetail`, `CreateBuddyOrder`, `FetchBuddyProviderStatus`, `SubmitBuddyProviderApplication`, `FetchBuddyProviderEarnings`, `FetchBuddyProviderOrders`

**Deep Link:** `buddyListing(listingID)` · `spark://buddy/{id}`

---

### 3.6 我的 — SparkProfile · SparkSearch · SparkTrust

#### Profile Tab

| 功能 | 说明 |
|------|------|
| 资料摘要 | 信任分 Ring、加载 / 错误 / 重试 |
| 搜索入口 | 跳转 `SearchRootView` |
| Premium CTA | → Paywall（`SparkFeatureFlags.isPremiumPaywallEnabled`） |
| 隐私政策 / 用户协议 | `SparkLegalLinks` Link |
| ICP 备案号 | About Section |
| 登出 / 注销账号 | 注销二次确认 |

#### 搜索 — SparkSearch

| 功能 | 说明 |
|------|------|
| 查询建议 + 结果 | 人 / 活动 / 社区等 |
| API | `GET /v1/search?q=` |

**UseCase:** `SearchQuery`

#### 信任认证 — SparkTrust

| 功能 | 说明 |
|------|------|
| L1–L3 向导 | 手机 / 实名 / 活体（MVP） |
| 信任分展示 | `TrustScoreRingView`, `TrustBadgeView` |
| API | `/v1/trust/profile`, phone/real-name/liveness verify |

**UseCases:** `FetchTrustProfile`, `VerifyTrustLevel`

---

### 3.7 订阅 — SparkPayments

| 功能 | 说明 |
|------|------|
| StoreKit 2 | 产品加载、购买 |
| Restore Purchases | App Store 审核要求 |
| EntitlementManager | Premium 状态 |
| PaywallView | 多 placement |
| 功能门控 | Activity Feed 锁定等 |

**Deep Link:** `paywall(placement)`

---

## 4. 跨 Tab 编排（SparkTabOrchestrator）

| 能力 | 触发场景 |
|------|----------|
| `openMatchConversation` | 消息 Inbox 新配对 → DM |
| `fetchRecommendedActivity` | 活动推荐上下文 |
| `fetchRecommendedBuddy` | 活动详情 → 配套陪玩推荐 |
| `fetchActivityRecap` | 社区 Recap 草稿预填 |
| `syncPremiumEntitlement` | StoreKit 权益同步 |
| `syncActivityReminders` | RSVP 后提醒同步 |
| `sendGroupChatMessage` | 活动群聊发消息 |
| `ensureActivityGroupThread` | 创建活动群 Thread |

---

## 5. Deep Link 路由

定义：`DeepLinkRoute`（`SparkAppShell`）

| 路由 | 行为 |
|------|------|
| `tab(SparkTab, query?)` | 切换 Tab；`search` 别名 → profile |
| `paywall(PaywallPlacement)` | 全屏 Paywall |
| `conversation(threadID)` | 消息 Tab 打开会话 |
| `communityPost(postID)` | 社区帖子详情 |
| `communityRecap(activityID)` | 社区 Recap 草稿 |
| `activityDetail(activityID)` | 活动详情 |
| `buddyListing(listingID)` | 搭子 Tab 打开陪玩详情 |

未登录时路由暂存于 `pendingDeepLinkAfterAuth`，登录后自动应用。

详见 [UNIVERSAL_LINKS.md](UNIVERSAL_LINKS.md)。

---

## 6. 后端 API 域（Staging）

实现：`cloudfunctions/spark-api` · 契约：[API_CONTRACT.md](API_CONTRACT.md)

| 域 | 主要端点 |
|----|----------|
| Auth | session, email, **register**, **password-reset**, apple, sign-out, **account/delete** |
| Messages | inbox, threads, messages, read, action-items, direct/activity threads |
| Activities | feed, browse, CRUD, RSVP, waitlist, announce, feedback, report |
| **Buddy** | `GET /v1/buddies`, detail, `POST /v1/buddy-orders`, provider status/application/earnings/orders |
| Community | feed, communities, posts, **media/stage**, replies, **report** |
| Search | `GET /v1/search` |
| Trust | profile, phone/real-name/liveness verify |
| Devices / Push | `POST /v1/devices`, internal notifications send |
| Profile | avatar upload-url, profile PATCH |

### 运行环境

| 配置 | API Base |
|------|----------|
| Debug / 默认 | `https://mock.spark.local` → Mock Repository |
| Release | `Config/SparkRelease.xcconfig` → 生产 API |

---

## 7. UseCase 完整列表（Domain 层）

### SparkAuth（10）

- `RestoreSessionUseCase`
- `SignInWithAppleUseCase`
- `SendPhoneOTPUseCase`
- `SignInWithPhoneOTPUseCase`
- `ResetPasswordWithPhoneOTPUseCase`
- `SignInWithEmailUseCase`
- `SignUpWithEmailUseCase`
- `SignOutUseCase`
- `DeleteAccountUseCase`
- `RequestPasswordResetUseCase` *(deprecated — legacy email API stub)*

### SparkMessages（12）

- `FetchInboxUseCase`
- `FetchUnreadCountUseCase`
- `MarkMessagesReadUseCase`
- `FetchMessageThreadsUseCase`
- `FetchThreadMessagesUseCase`
- `SendThreadMessageUseCase`
- `MarkThreadReadUseCase`
- `FetchConversationContextUseCase`
- `EnsureDirectMessageThreadUseCase`
- `DismissActionItemUseCase`
- `RespondToActivityInviteUseCase`

### SparkActivity（14）

- `FetchActivityFeedUseCase`
- `FetchActivityBrowsePageUseCase`
- `FetchActivityDetailUseCase`
- `FetchActivitiesByHostUseCase`
- `CreateActivityUseCase`
- `UpdateActivityUseCase`
- `CancelActivityUseCase`
- `UpdateActivityRSVPUseCase`
- `JoinActivityWaitlistUseCase`
- `PromoteFromWaitlistUseCase`
- `AnnounceActivityUseCase`
- `SubmitHostFeedbackUseCase`
- `ReportActivityUseCase`

### SparkBuddy（7）

- `FetchBuddyListingsUseCase`
- `FetchBuddyListingDetailUseCase`
- `CreateBuddyOrderUseCase`
- `FetchBuddyProviderStatusUseCase`
- `SubmitBuddyProviderApplicationUseCase`
- `FetchBuddyProviderEarningsUseCase`
- `FetchBuddyProviderOrdersUseCase`

### SparkCommunity（9）

- `FetchCommunityTabExperienceUseCase`
- `FetchCommunityPostsUseCase`
- `FetchCommunityPostUseCase`
- `FetchCommunityDetailBundleUseCase`
- `CreateCommunityPostUseCase`
- `PrepareCommunityMediaUploadUseCase` (Mock + Live stage)
- `CreateCommunityReplyUseCase`
- `CreateCommunityRecapUseCase`
- `ReportCommunityPostUseCase`

### SparkLikes（archived）

- Package retained for reference; **not** in App target. See [adr/0004-sparklikes-archived.md](adr/0004-sparklikes-archived.md).

### SparkSearch（1）

- `SearchQueryUseCase`

### SparkTrust（2）

- `FetchTrustProfileUseCase`
- `VerifyTrustLevelUseCase`

### SparkProfile（1）

- `FetchProfileSummaryUseCase`

---

## 8. 工程与质量门禁

| 目标 | 命令 |
|------|------|
| Guardrails | `make check` |
| SwiftLint | `make lint` |
| Gate 1 架构 | `make usecase-tests`, `make coverage` |
| Gate 2 UI | `make lint-ui-gate` |
| Gate 3 性能 | `make lint-perf-gate` |
| Gate 4/5 上架 | `make lint-appstore-gate` |
| 单元测试 | `make test-packages` |
| CI 全套 | `make ci` |
| Staging 部署 | `make deploy-spark-api` |

详见 [CI.md](CI.md)。

---

## 9. 已知缺口 / 占位（非代码阻塞项）

| 项 | 状态 |
|----|------|
| 社区发帖 UI | **已落地**（FAB 门控 + Live `media/stage`） |
| 隐私政策 / 用户协议 URL | 占位，待运营页面上线 |
| ICP 备案号 | 占位 |
| Instruments 性能 Profile | 静态 Gate 通过；无实测签字 |
| App Store Connect 元数据 / 截图 | 仓库外 |
| 生产远程 Push | 需付费 Team + `SPARK_ENABLE_PUSH` + 生产 entitlements |

---

## 10. 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-07 | 初版：五 Tab 功能清单、15 模块、62 UseCase、Deep Link、API 域 |
| 2026-06-08 | 完成优先级清单：Auth register/reset、社区 Live 媒体、SparkLikes 归档 ADR |

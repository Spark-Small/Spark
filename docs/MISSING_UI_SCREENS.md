# Spark — 缺失前端 UI 页面清单

> **Status:** Living document — 对照 `main` 代码与 [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) · [TAB_SCREENS.md](TAB_SCREENS.md)  
> **Last updated:** 2026-06-19  
> **判定标准：** Domain/UseCase 或 API 已存在，但 **Release 可触达的 SwiftUI 页面缺失、仅占位、或导航死胡同**

---

## 1. 摘要

| 维度 | 数量（约） | 说明 |
|------|-----------|------|
| **完全缺失** | 0 | — |
| **占位 / MVP 桩** | 3 | 微信 Open SDK；Trust 第三方 SDK；社区 Live 媒体 API |
| **不完整 / 规划未做** | 1 | 真机 Push 全流程联调 |
| **已落地（本轮 + W1–W5）** | 35+ | 见 §2 各模块「**已落地**」行 |

**剩余最高优先级：** MODULE-H 微信 Open SDK 真分享；社区图片 **Live API** + 审核态；Trust **运营商/公安/活体** SDK。

---

## 2. 按模块 — 缺失 UI 明细

图例：**状态** = 缺失类型 · **已有底层** = UseCase / API · **建议页面** = 待建 SwiftUI 入口

### 2.1 SparkAuth — 认证

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **注册页** `SignUpView` | **已落地（无入口）** | `SignUpWithEmailUseCase` · Mock + Live `/v1/auth/register` | —（手机 OTP 登录即注册） | P1 |
| **忘记密码** `ForgotPasswordView` | **已落地** | `ResetPasswordWithPhoneOTPUseCase` · Mock + Staging | `LoginView` → NavigationLink | P2 |

**已有 UI：** `LoginView`（手机 OTP + Apple + 注册/找回密码）

---

### 2.2 SparkCommunity — 社区

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **发帖页** `CreateCommunityPostView` | **已落地** | `CreateCommunityPostUseCase` | FAB（`isCommunityPostingEnabled`） | **P0** |
| **回复 Composer** `CommunityReplyComposer` | **已落地** | `CreateCommunityReplyUseCase` | 帖子详情底部输入 | **P0** |
| **UGC 媒体发帖** | ✅ Live stage | `PrepareCommunityMediaUpload` + `POST /v1/community/media/stage` | PhotosPicker → stage → publish with `media[]` | — |
| **社区 scoped 搜索** `CommunitySearchView` | **已落地** | 本地 filter | 社区 Toolbar 搜索 → 帖子筛选 | P3 |

**已有 UI（完整）：** Feed、帖子详情、Recap 草稿、成员 Sheet、举报、PeopleDiscoveryList

---

### 2.4 SparkMessages — 消息

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **图片发送** | **已落地** | `SendThreadMessage` + `ChatMessageKind.image` | `PhotosPicker` + Mock 本地文件 URL | P2 |
| **会话 Peer 资料** `ConversationPeerProfileView` | **已落地** | `FetchConversationContext` | DM 工具栏 → 资料页 + 共同活动 | P2 |

**已有 UI（完整）：** 统一 Inbox、会话详情、活动邀请响应

---

### 2.5 SparkActivity — 活动

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **碰头地图** `ActivityMeetupMapView` | **已落地** | MapKit geocode | 详情 NavigationLink | P2 |
| **轻回顾** `ActivityPastRecapView` | **已落地** | 结束态详情 | 「查看往期回顾」 | P2 |
| **站内邀友** `ActivityInvitePickerView` | **已落地** | Inbox 候选 | `ActivityInviteFriendsSection` | P1 |
| **微信分享** | MVP 桩 | 邀请文案 | `ActivityWeChatShareSheet`（复制 + `weixin://`，无 SDK） | P2 |
| **协办 / RSVP 审批** | **已落地** | `ReviewAttendeeRSVP` · `SetAttendeeCoHost` | 主办管理 → `ActivityHostApprovalView` | P3 |
| **Push 权限引导** | **已落地** | `PushNotificationPermissionGuideView` | 登录后 MainTab 首次 fullScreenCover | P1 |

**已有 UI（完整）：** Inbox、Browse、详情、RSVP、Host、Feedback、Recap、ShareLink、日历

---

### 2.6 SparkProfile — 我的

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **资料编辑** `ViewerProfileEditView` | **已落地** | Likes Profile UseCases | Profile 头部「编辑资料」Sheet | **P0** |
| **头像上传** | **已落地** | `RequestAvatarUploadUseCase` | 编辑 Sheet 内 PhotosPicker | **P0** |
| **账号设置** `AccountSettingsView` | **已落地** | 通知 + 屏蔽 + 订阅 | Profile → 账号设置 NavigationLink | P1 |

**已有 UI（完整）：** Trust Ring/Badge、认证向导、搜索、Premium、法务、ICP、登出/注销

---

### 2.7 SparkSearch — 搜索

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **用户详情** `SearchPersonProfileView` | **已落地** | Search person 结果 | `SearchRootView` navigationDestination | **P0** |
| **搜索历史** | **已落地** | `SearchHistoryStore` | 空态 List「最近搜索」+ 清除 | P3 |

**已有 UI（完整）：** 建议列表、活动/社区/用户结果跳转

---

### 2.8 SparkTrust — 信任认证

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **L2/L3 原生 SDK 流程** | MVP 桩 | `VerifyTrustLevelUseCase` | `TrustVerificationFlowView` Mock 表单；无运营商/公安/活体 SDK | P1 |
| **级别说明** `TrustLevelDetailView` | **已落地** | `FetchTrustProfile` | 已完成级别详情 + 向导未完成 → Flow | P2 |

**已有 UI（完整）：** 向导 Shell、Ring、Badge、Flow 表单、级别详情

---

### 2.9 SparkNotifications — 推送

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **通知偏好** `NotificationPreferencesView` | **已落地** | UserDefaults 分类开关 | Profile / AccountSettings 入口 | P1 |
| **Push 授权引导** `PushNotificationPermissionGuideView` | **已落地** | `UNUserNotificationCenter` | MainTab 首次 fullScreenCover | P2 |

---

### 2.10 SparkPayments — 订阅

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **管理订阅** | **已落地** | App Store URL | `AccountSettingsView` → 系统订阅页 Link | P3 |

**已有 UI（完整）：** `PaywallView`、Restore、门控

---

### 2.11 SparkAppShell — 壳层 / 跨 Tab

| 建议页面 | 状态 | 已有底层 | 现状 | 优先级 |
|----------|------|----------|------|--------|
| **统一身份卡** | **已落地** | 各 Tab Profile | `SparkUnifiedIdentityContent` / Member Sheet | P1 |
| **Universal Link Fallback** | **已落地（App 内）** | `DeepLinkParser` | 无法解析 URL → `UniversalLinkFallbackView` Sheet | P2 |
| **配对约局确认** | **已落地** | `MatchToActivityConfirmView` | Match → 时段确认 → `CreateActivityDraft` | P1 |

**已有 UI（完整）：** 五 Tab、`AppRouter`、Deep Link、登录/Paywall Sheet

---

## 3. 与 MODULE 规划对照

| MODULE | 状态 | 备注 |
|--------|------|------|
| **E** Community UGC | 发帖/回复/搜索已落地；Mock 媒体上传；Live API 待扩展 | |
| **F** 头像上传 | Profile + Gate 均已接 | |
| **C** Universal Links | App Fallback + `web/public/a/index.html` 静态页 | |
| **H** 微信 SDK | `ActivityWeChatShareSheet` 占位；真 SDK 待合规 | |
| **B** APNs | 偏好 + 首次引导已落地 | |

---

## 4. 仍待后续（非本轮范围）

- **微信 Open SDK** 分享卡片（MODULE-H）
- 社区 **图片/视频 Live API** 与审核态 UI
- Trust **运营商 / 公安 / 活体** 第三方 SDK 嵌入
- 真机 **Push 全流程** 联调（付费 Team + 生产 entitlements）

---

## 5. 波次状态

| 波次 | 状态 |
|------|------|
| W1–W4 | ✅ 已落地 |
| W5 | ✅ 地图、回顾、社区 FAB 门控 |
| **后续任务（2026-06-07）** | ✅ Auth、BlockedUsers、消息图片/Peer、AccountSettings、搜索历史、Trust Flow、Match 确认、Push 引导、Deep Link Fallback |
| **遗留收尾（2026-06-07）** | ✅ 协办审批、WeChat Sheet、Trust Flow 导航、Mock 媒体上传、Web 落地页 |

---

## 6. 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-07 | 初版 |
| 2026-06-07 | W1–W5 落地 |
| 2026-06-07 | **后续任务全量落地** |
| 2026-06-07 | **遗留收尾**：审批/协办、WeChat Sheet、Trust Flow、Mock 媒体、Web `/a/` |

# 坐标系 · 归档（已移除 / 已更名）

> **本文件为归档附录。** 已删除方案列表仍有效。  
> **现行规范**：[Project/](../Project/README.md)。  

---

## 2026-09-30 规范迁入 Project/

开发规范收拢为 `Project/00`–`21`。  
`SoftLaunchConventions.md` / `ReleaseBlockers.md` 已收成**短桩**（勿再写平行阻塞表）。  
同日文档清洁：PRD / AppArchitecture / DevelopmentGuide / Auth·Activities / DESIGN_SYSTEM 等加**附录裁决横幅**；索引见 [README.md](README.md)。  
旧 `Docs/README` 批次索引、Release 长文等已退役；勿在 `Docs/` 新建平行总纲。

---

## 2026-09-30 文档收敛（已删除长文）

| 已删文件 | 去向 |
|----------|------|
| `ReleaseEngineeringPlan.md` | 七批次已完成；剩余外部依赖 → [Project/16](../Project/16_RELEASE_CHECKLIST.md) B（短桩 [ReleaseBlockers.md](ReleaseBlockers.md)） |
| `RemainingReleaseClientPlan.md` | Wave 已落地；约定 → Project/06·16（短桩 SoftLaunchConventions） |
| `GiantFileSplitPlan.md` | Split-A…J 完成；一文件一主类型纪律 → Project/07（附录 DevelopmentGuide 笔记） |
| `ProductReviewModificationPlan.md` | 履约收敛摘要见下节 |
| `ReleaseReadinessAudit.md` | 审计长文退役；阻塞表 → Project/16 B |

---

## 2026-09 履约收敛（已完成 · 勿回退）

| 勿回退 | 原因 |
|--------|------|
| `ActivityUpcomingTodo*.swift` | 已删除；履约 checklist 仅在「我的行程」 |
| 活动 Tab 完整待办卡 | 与「履约唯一主页」冲突 |
| 报名成功 Sheet 内 checklist / 进群 | 成功 Sheet 主 CTA 仅为「打开我的行程」 |
| 自定义 Toast 浮层 | 用 `platformFeedbackAlert` / `platformLightFeedback` |

**仍存在的相关文件（勿误标为已删）：** `BuddyRecordDetailViews.swift`、`ActivityNextUpBanner` / `ActivityNextUpPresentation`。

---

## 已删除的视图 / Sheet

| 旧名称 | 替代 |
|--------|------|
| `WalletPassEventTicketFace` | `ActivityJourneyCredentialFace` + `Design/CredentialArt/` |
| `OnboardingSheet` | `AppWelcomeGuideView` + `InterestOnboardingView` / `InterestTaxonomyFormEditor` |
| `GuestAccessGate` / 访客主路径 | 硬登录墙（`ContentView`） |
| `ActivityFilterSheet` | `ActivityFilterMenu` |
| `ActivityFavoritesView` | 收藏态由 Model + 发现卡承担 |
| `ActivityPaymentSheet` | 参加确认流内支付 + `ActivityOrdersSheet` |
| `ActivityIntentMomentSheet` | 已取消 |
| `ActivityLayoutDemoView` | 已取消 |
| `ActivityCatalogSeeAllSheet` | 已取消 |
| `InterestTaxonomyPicker`（Chip UI） | `InterestTaxonomyFormEditor` |
| `ActivityUpcomingTodo*` | 「下一场」Banner + 我的行程 |
| `LocalAuthSheet` 作为登录主入口 | `LoginView` + `LegalConsentGate`（资料区若仍有协议入口勿当会话门闸） |

## 已拆分的文件

| 旧文件 | 新文件 |
|--------|--------|
| `BuddyOrgInfoViews.swift` | `BuddyOrgInfoScaffold`、`CircleGroupManageViews`、`ProfileCircleDetailView`（`ProfileGuildsListView` 已删，工会入口走「我的俱乐部」） |
| `MessagesModel+Social.swift` | `+RichPayloads` / `+GroupAdmin` / `+FriendRequests` / `+FriendProfile` / `+Search` / `+Persistence` |
| `LocalRepositories.swift`（App 层聚合） | `Packages/CoordinateKit/.../CoordinateData/Local*Repository.swift` |
| `EngagementRepository.swift`（App 层 typealias） | 直接使用 `CoordinateDomain.EngagementRepository` |
| `LocalCommercialSelfTests.swift` | `ContentView` DEBUG 内联清理 |

## 已废弃 API / 模式

| 旧用法 | 现行做法 |
|--------|----------|
| Features 内 `AppComposition` | `AppDependencies` + `@Environment` |
| `platformTransientFeedback` | `platformFeedbackAlert` / `platformLightFeedback` |
| `DiscoverType` 字阶枚举 | 系统 Dynamic Type |
| `activity.isLifecycleEnded(now:)` | 属性 `isLifecycleEnded`；带时间用 `isLifecycleEnded(at:)` |
| `AppComposition.local*Repository()` | `resolvedLocal*Repository()` |
| `@Environment(PlatformChromeMeasurements.self)` | `@Environment(\.platformChromeMeasurements)` |
| `ContentView` `@State chromeMeasurements` | `PlatformChromeRoot` @ `坐标系App` |
| `@MainActor static var defaultValue`（EnvironmentKey） | `MainActor.assumeIsolated` 惰性单例（见 DevelopmentGuide §7.4） |
| `.tabPushDestination`（文档曾用名） | 目的地直接 `.toolbarVisibility(.hidden, for: .tabBar)` |
| `SnapshotFileActor`（已删除） | JSON 回退实际走 `LocalSnapshotFileStore` |
| `WalletPassStack` / `WalletRecordFace` | 票面走 `WalletPassFace*`；余额卡走 `WalletPaymentCardFace` |
| `ChatTypes.swift` | `ChatConversation` / `ChatMessage` / `ChatGroupTypes` |
| `ActivitiesWriting` / `BuddiesWriting` | 写路径收口 Domain UC + Model 扩展 |
| `BuddyPeopleBrowseHeader` / `BuddyBookingCatalogHeader` / `BuddyServiceCard` | 已移除；见 DESIGN_SYSTEM |
| `PassFaceModel.stripIllustrationName` | 彩绘改走 `CredentialArtCatalog` |
| App 内票面右上角「加入 Wallet」主 CTA | 主 CTA **分享纪念票**；Wallet 在「更多」菜单 |
| `ContentView` = 仅 Tab 根 | 会话门闸 + 延后 `AppModel`（见 AuthModule） |

## 历史持久化键（迁移保留）

| 键 / 文件 | 说明 |
|-----------|------|
| `api.useRemoteCatalog` | 迁移至 `FeatureFlags`（`migrateLegacyFlagsIfNeeded`） |
| `profile.wallet.balanceCents` | 钱包余额迁移键 |
| `*_snapshot.json` | SwiftData 迁入后由 `PersistenceMigration` 清理 |
| `profile_recent_browse.json` | 迁入 `RecentBrowseItem` 后清理 |

---

*新增归档项时：在本表追加一行，并从活跃文档中删除重复描述。*

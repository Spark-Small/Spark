# 坐标系 · 归档（已移除 / 已更名）

> 仅供检索历史命名，**勿在新代码中引用**。当前规范见 [DevelopmentGuide.md](DevelopmentGuide.md)。  
> 上线阻塞与修复批次见 [ReleaseReadinessAudit.md](ReleaseReadinessAudit.md)。

---

## 2026-09 履约收敛（已完成 · 勿回退）

产品评审改造方案（原 `ProductReviewModificationPlan.md`）已全部落地，文件改为归档摘要。

| 勿回退 | 原因 |
|--------|------|
| `ActivityUpcomingTodo*.swift` | 已删除；履约 checklist 仅在「我的行程」 |
| 活动 Tab 完整待办卡 | 与「履约唯一主页」冲突 |
| 报名成功 Sheet 内 checklist / 进群 | 成功 Sheet 主 CTA 仅为「打开我的行程」 |
| 自定义 Toast 浮层 | 用 `platformFeedbackAlert` / `platformLightFeedback` |

**仍存在的相关文件（勿误标为已删）：** `BuddyRecordDetailViews.swift`（邀约 / 预约详情）、`ActivityNextUpBanner` / `ActivityNextUpPresentation`。

---

## 已删除的视图 / Sheet

| 旧名称 | 替代 |
|--------|------|
| `WalletPassEventTicketFace` | `ActivityJourneyCredentialFace` + `Design/CredentialArt/` |
| `OnboardingSheet` | `AppWelcomeGuideView` + `InterestTaxonomyFormEditor` |
| `ActivityIntentMomentSheet` | 已取消 |
| `ActivityLayoutDemoView` | 已取消 |
| `ActivityCatalogSeeAllSheet` | 已取消 |
| `InterestTaxonomyPicker`（Chip UI） | `InterestTaxonomyFormEditor` |
| `ActivityUpcomingTodo*` | 「下一场」Banner + 我的行程 |

## 已拆分的文件

| 旧文件 | 新文件 |
|--------|--------|
| `BuddyOrgInfoViews.swift` | `BuddyOrgInfoScaffold`、`CircleGroupManageViews`、`ProfileCircleDetailView`、`ProfileGuildsListView` |
| `MessagesModel+Social.swift` | `+RichPayloads` / `+GroupAdmin` / `+FriendRequests` / `+FriendProfile` / `+Search` / `+Persistence` |
| `LocalRepositories.swift`（App 层聚合） | `Packages/CoordinateKit/.../CoordinateData/Local*Repository.swift`；敏感词校验在 `Services/ContentModeration.swift`（无关替代） |
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
| `SnapshotFileActor`（包内存在但未接线） | JSON 回退实际走 `LocalSnapshotFileStore`；勿在文档中当作活跃 I/O 路径 |
| `BuddyPeopleBrowseHeader` / `BuddyBookingCatalogHeader` / `BuddyServiceCard` | 已移除；见 DESIGN_SYSTEM §6.1 现行组件 |
| `PassFaceModel.stripIllustrationName` | 彩绘改走 `CredentialArtCatalog`；PassKit 字段见 `ActivityPassFieldBuilder` |
| App 内票面右上角「加入 Wallet」主 CTA | 主 CTA **分享纪念票**；Wallet 在「更多」菜单 |

## 历史持久化键（迁移保留）

| 键 / 文件 | 说明 |
|-----------|------|
| `api.useRemoteCatalog` | 迁移至 `FeatureFlags`（`migrateLegacyFlagsIfNeeded`） |
| `profile.wallet.balanceCents` | 钱包余额迁移键 |
| `*_snapshot.json` | SwiftData 迁入后由 `PersistenceMigration` 清理 |
| `profile_recent_browse.json` | 迁入 `RecentBrowseItem` 后清理 |

---

*新增归档项时：在本表追加一行，并从活跃文档中删除重复描述。*

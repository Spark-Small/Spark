# 巨型文件拆分方案（Apple 对齐）

> **状态**：Split-A…J **已全部落地**（按代码推断；待人工编译确认）  
> **依据**：[ReleaseEngineeringPlan.md](ReleaseEngineeringPlan.md) 批次 7 · [DevelopmentGuide.md](DevelopmentGuide.md) §6.2 · [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)  
> **原则**：一文件一主类型；SwiftUI 大屏用「编排器 + 具名子 View」；Model 才用 `Type+Concern.swift`。

---

## 1. 目标

| 项 | 标准 |
|----|------|
| 体量 | 单文件目标 ≤ ~400 行（§6.2） |
| 行为 | 纯结构搬家，无产品逻辑变更 |
| 可预览 | 独立 UI 类型尽量带 `#Preview` |
| 分层 | 不破坏 Tab / `navigationDestination` / Domain / Repository |
| Design | Design 不塞 Feature 业务 Models |

---

## 2. Apple / 本仓约定

1. **文件名 = 主类型名**（API Design Guidelines 常见落地）。  
2. **SwiftUI**：大 `body` 拆成子 `View`，显式传入数据与回调；少用跨文件 `private`→`internal` 的 `View+Slice`。  
3. **Model**：继续 `MessagesModel+*` / `ActivitiesModel+*` 式扩展。  
4. **View 动作**：可保留 `*View+Actions.swift`（仓库已有 `ActivityDetailActions` 模式）。  
5. **MARK**：文件内用 `// MARK: -` 分组；不要用 MARK 代替拆文件。

---

## 3. 执行批次

### 3.1 PR-Split-A · 陪玩发现袋（优先）

**源**：`Features/Buddies/BuddyPaidMarketViews.swift`（~1056）

| 新文件 | 主类型 |
|--------|--------|
| `BuddyPaidQuickEntry.swift` | `BuddyPaidQuickEntry` + `BuddyPaidQuickEntryBar` |
| `BuddyPaidLeaderboardFeed.swift` | `BuddyPaidLeaderboardFeedItem` + `BuddyPaidLeaderboardFeedPlanner` |
| `BuddyPaidHotBadge.swift` | `BuddyPaidHotBadge` |
| `BuddyPaidMarketCatalog.swift` | `BuddyPaidBoardPeriod` + `BuddyPaidMarketCatalog` |
| `BuddyFeaturedCompanionCard.swift` | Card + Rail（同文件若仍 <400） |
| `BuddyPaidLeaderboard.swift` | `BuddyPaidLeaderboard` |
| `BuddyPaidTopCard.swift` | Top 卡 |
| `BuddyPaidLeaderboardRow.swift` | 榜行 |
| `BuddyCompanionServiceSKU.swift` | SKU + Menu + Row + DetailTab |

完成后删除 `BuddyPaidMarketViews.swift`。

### 3.2 PR-Split-B · 会话详情（其次）

**源**：`Features/Messages/ConversationDetailView.swift`（~824）

| 新文件 | 职责 |
|--------|------|
| `ConversationDetailView.swift` | 编排：状态、组装、Sheet/Alert |
| `ConversationThreadView.swift` | 时间轴、加载更早、滚动 |
| `ConversationMessageRow.swift` | 单条气泡 + 上下文菜单 |
| `ConversationComposerSection.swift` | 输入区、快捷回复、选图入口 |
| `ConversationDetailToolbarTitle.swift` | 顶栏标题 |
| `ConversationDetailMoreMenu.swift` | 更多菜单 |
| `ConversationDetailView+Actions.swift` | send / leave / loadPhoto 等共享状态动作 |

气泡壳仍用 `Design/PlatformMessagesChrome`；业务行留在 Features。

### 3.3 后续（同规则，可穿插）

| 批次 | 源 | 状态 |
|------|-----|------|
| Split-C | `WalletPassFace.swift` | ✅ Content / Typography / Chrome / Face / Strip / Barcode / Factory / RecordFace |
| Split-D | `ActivityDetailSections.swift` | ✅ DecisionCard / ContentBlocks / PeopleSheet / HeroGallery / CommentsSection / RelatedSections |
| Split-E | `PlatformReviewsUI.swift` | ✅ HeaderFilter / Reaction / RatedCard / CommentsHost / Composer / Support |
| Split-F | `PlatformMessagesChrome.swift` | ✅ Metrics / ThreadChrome / Bubble / ComposerBar / BadgeDots |
| Split-G | `ProfileAccountCommercialViews.swift` | ✅ CreateAccount / Membership / Wallet / TopUp / BecomeCompanion |
| Split-H | `ActivityJoinConfirmSheet.swift` | ✅ JoinConfirm / DraftRows / ContentEditorSheet |
| Split-I | `BuddyDetailSections.swift` | ✅ Hero / ProfileHeader / InfoSections / MatchSections |
| Split-J | `ProfileSettingsViews.swift` | ✅ Settings 根 + Account / Notifications / Privacy / About / Tickets / Blocked |

---

## 4. 验收清单

- [x] 原袋文件已删除（`BuddyPaidMarketViews.swift`）  
- [x] 单文件 ≤ ~400 行（`ConversationDetailView` 编排器约 453：Sheet/Alert 留在编排器，略超；Catalog/SKU 均 <250）  
- [ ] 搭子发现精选 / 榜 / 详情 SKU 可用（人工）  
- [ ] 会话发图、重试、更多菜单、通话入口可用（人工）  
- [x] 无新增 `navigationDestination` 重复注册  
- [ ] 人工编译通过后再合入  

---

## 5. 进度

| 批次 | 状态 |
|------|------|
| 文档 | ✅ |
| Split-A BuddyPaid | ✅ 已拆为 9 文件并删除原袋 |
| Split-B ConversationDetail | ✅ 编排器 + Thread / Row / Composer / Toolbar / MoreMenu / +Actions |
| Split-C WalletPassFace | ✅ 8 文件（Design；CoordinateModels 白名单已更新） |
| Split-D ActivityDetailSections | ✅ 6 文件（Features/Activities） |
| Split-E PlatformReviewsUI | ✅ 6 文件（Design） |
| Split-F PlatformMessagesChrome | ✅ 5 文件（Design；白名单已更新） |
| Split-G ProfileAccountCommercialViews | ✅ 5 文件（Features/Profile） |
| Split-H ActivityJoinConfirm | ✅ JoinConfirm + DraftRows + ContentEditor |
| Split-I BuddyDetailSections | ✅ 4 文件（Features/Buddies） |
| Split-J ProfileSettingsViews | ✅ 7 文件（Features/Profile） |

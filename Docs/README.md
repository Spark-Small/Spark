# 坐标系 · 文档索引

> 最后同步：**2026-09-29**  
> **新人路径**：Vision → PRD → AppArchitecture → DevelopmentGuide → DESIGN_SYSTEM  
> **上线路径**：ReleaseReadinessAudit §0 → ReleaseEngineeringPlan §11–§13 → RemainingReleaseClientPlan

---

## 文档地图

```
战略层          Vision.md
产品层          PRD.md  ← 功能需求、技控对照、验收（主 PRD）
                UserJourneyTechControl.md  ← 用户旅程 / 技控节点（心理层）
                BuddiesProductPlan.md      ← 搭子域 IA 细则
                TrustBehaviorModel.md      ← 信任域细则
架构层          AppArchitecture.md         ← 导航、代码地图、持久化
工程层          DevelopmentGuide.md        ← 开发规范、DI、测试、PR 自检
                CredentialArt.md           ← 行程凭证彩绘、SVG 模板、PassKit 关系
                ReleaseReadinessAudit.md   ← 上线审计原文 + §0 落地对照（活跃）
                ReleaseEngineeringPlan.md  ← 7 批次工程方案与 §13 进度
                RemainingReleaseClientPlan.md ← 诚实门控后客户端 Wave（已落地；余 tag/托管页）
                GiantFileSplitPlan.md      ← 巨型文件拆分 Split-A…J
                ../CONTRIBUTING.md         ← 贡献入口、本地命令速查
视觉层          ../DESIGN_SYSTEM.md        ← UI 组件与反模式
归档            Archive.md                 ← 已删除 API / 文件（勿引用）
                ProductReviewModificationPlan.md  ← 2026-09 履约收敛（已完成摘要）
```

**单一事实源**：行为需求 → PRD · 代码落点 → AppArchitecture · 工程规范 → DevelopmentGuide · **订单/预约状态** → PRD §6 · **上线阻塞（当前）** → ReleaseReadinessAudit **§0–§1** · **批次进度** → ReleaseEngineeringPlan §13

---

## 读哪份？

| 文档 | 回答什么 | 何时改 |
|------|----------|--------|
| [Vision.md](Vision.md) | 愿景、使命、V1 边界 | 品牌 / 战略改版 |
| **[PRD.md](PRD.md)** | **FR、技控对照 §5、状态语义 §6（含陪玩预约状态机）、发布清单 §8** | 新功能 / 改行为 / 状态机 |
| [AppArchitecture.md](AppArchitecture.md) | 导航、板块、代码地图、持久化 | Tab / 深链 / 架构变更 |
| **[DevelopmentGuide.md](DevelopmentGuide.md)** | **分层、DI、导航、行程凭证（§6.4）、MainActor/并发/PhotosPicker（§7）、测试、PR 自检 §9** | 工程规范 / 流程变更 |
| [CredentialArt.md](CredentialArt.md) | SVG 模板、场景映射、运行时着色、与 PassKit 边界 | 改彩绘资源或 CredentialArt API |
| [../CONTRIBUTING.md](../CONTRIBUTING.md) | 贡献入口、本地命令、`swift test` | 首次提 PR |
| [UserJourneyTechControl.md](UserJourneyTechControl.md) | 用户 0→1 心理与技控（**≠ 实现清单**） | 旅程讨论；落地查 PRD §5 |
| **[ReleaseReadinessAudit.md](ReleaseReadinessAudit.md)** | **§0 落地对照 + 审计原文；提审前先看 §0–§1 / §11–§12** | 上线评审 / 修复排期 |
| **[ReleaseEngineeringPlan.md](ReleaseEngineeringPlan.md)** | **7 批次任务、验收、§11 门禁、§13 进度表** | 开工排期 / 对照已完成项 |
| [GiantFileSplitPlan.md](GiantFileSplitPlan.md) | 巨型文件拆分：一文件一主类型、Split-A…J 进度 | 拆 >400 行 Feature / Design 文件 |
| [RemainingReleaseClientPlan.md](RemainingReleaseClientPlan.md) | 诚实门控后客户端 Wave；**Wave 编码已落地**，余人工 tag / 托管页 / 编译 | 提审前客户端核对 |
| [BuddiesProductPlan.md](BuddiesProductPlan.md) | 搭子 Tab IA：免费 / 预约 | 搭子发现或商业化改版 |
| [TrustBehaviorModel.md](TrustBehaviorModel.md) | 行为信用、事件、公私展示 | 信任域事件或展示变更 |
| [../DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) | 视觉、组件、反模式 | UI 组件或布局规范变更 |
| [Archive.md](Archive.md) | 已删除文件 / API；2026-09 履约收敛勿回退项 | 废弃旧实现时追加 |
| [ProductReviewModificationPlan.md](ProductReviewModificationPlan.md) | ~~活跃改造清单~~ → **已归档摘要**（履约收敛） | 勿追加新项；查历史用 |

---

## 角色快捷入口

| 角色 | 日常阅读 |
|------|----------|
| **产品** | PRD §5 技控对照 → UserJourney → 域细则 |
| **设计** | DESIGN_SYSTEM → PRD §2.6 Apple 参照 |
| **iOS 开发** | DevelopmentGuide → AppArchitecture → PRD FR |
| **上线 / Review** | [ReleaseReadinessAudit §0](ReleaseReadinessAudit.md) → [ReleaseEngineeringPlan §11](ReleaseEngineeringPlan.md) → [DevelopmentGuide §9.2](DevelopmentGuide.md) |
| **新人** | 本页 → Vision → PRD §2 → DevelopmentGuide §2–5 |

---

## 当前实现快照（2026-09-29）

```
未登录 → Launch → LoginView（SignInWithAppleButton；微信仅 DEBUG；Release 远程短信）
已登录 → TabView 五 Tab（活动 → 搭子 → 广场 → 消息 → 我的）· iPhone 首发
         └─ 广场可按产品生命周期并入活动 Tab「活动分享」
首次进活动 Tab → AppWelcomeGuideView（1 页意图，可跳过）
兴趣编辑 → 我的 → 编辑资料 → InterestTaxonomyFormEditor
```

- 引导：`WelcomeGuideStore` · 权限：报名成功 / 点「附近」时请求（非开屏链）
- 活动 Tab：**「下一场」** 摘要 Banner（7 天窗口；新用户不显示）+ `.searchable`
- 组合根：`AppDependencies` + `AppComposition`（含 `TrustBehaviorLedger` / `LocalMediaLibrary`）
- 持久化：SwiftData 快照 + `MainActorPersistence.chained`；写失败 → `AppPersistenceHealth`；后台 `scenePhase` flush
- 合规：`PrivacyInfo.xcprivacy` · `LegalDocumentURLs` · Bundle ID `app.zuobiaoxi.coordinate` · Release HTTPS
- 诚实门控：Release 无假外部支付成功 / 无假充值 / 无自动回复 / 无模拟接单 / 无静默演示报名
- 测试：Domain + Networking + App ≈ **102** 例；CI `.github/workflows/ios-test.yml`
- 上线：**客户端门控已收口**；阻塞项 = 真支付·IM·供给 API + 托管页可达 + 基线 tag（见 ReleaseReadinessAudit §0）

细节见 [AppArchitecture.md](AppArchitecture.md)、[ReleaseEngineeringPlan.md](ReleaseEngineeringPlan.md) §13。

---

## 新增文档约定

1. 先确定层级（产品 / 架构 / 工程 / 视觉）
2. 更新本索引；**勿在多处重复同一张表**（易混状态、PR 清单以 PRD / DevelopmentGuide 为准；**当前上线阻塞以 ReleaseReadinessAudit §0 为准**）
3. 技控节点新增时：UserJourney 记心理 → PRD §5 记 FR 映射
4. 已完成的改造方案：压缩为摘要或迁入 Archive，**勿与活跃审计文档并列为主清单**

---

*功能合并前检查 PRD FR 表与 AppArchitecture 是否同步。*

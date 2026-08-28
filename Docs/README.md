# 坐标系 · 文档索引

> 最后同步：**2026-08-28**（与当前代码库一致）

## 读哪份？

| 文档 | 回答什么 | 何时改 |
|------|----------|--------|
| [Vision.md](Vision.md) | 愿景、使命、V1 边界 | 品牌 / 战略改版 |
| [AppArchitecture.md](AppArchitecture.md) | **整 App 导航、板块、主 CTA、代码地图、启动流程** | Tab / 深链 / 引导 / 功能入口变更 |
| [UserJourneyTechControl.md](UserJourneyTechControl.md) | 用户 0→1 旅程与技控闸门（**产品视角，弱绑定实现**） | 旅程节点、验收、排期讨论 |
| [BuddiesProductPlan.md](BuddiesProductPlan.md) | 搭子 Tab IA：免费 / 预约 | 搭子发现或商业化改版 |
| [TrustBehaviorModel.md](TrustBehaviorModel.md) | 行为信用账本、事件、公私展示 | 信任域事件或展示变更 |
| [../DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md) | 视觉、组件、反模式、屏幕配方 | UI 组件或布局规范变更 |

## 当前实现快照（2026-08-28）

### 启动与引导

```
未登录 → Launch（信封动画）→ LoginView（协议勾选与登录分离）
已登录 → TabView 五 Tab
  └─ 首次进入活动 Tab → AppWelcomeGuideView（半屏 4 页 SVG 插画，可跳过）
       └─ 完成后写入默认兴趣并标记 hasCompletedOnboarding
兴趣编辑 → 我的 → 编辑资料 → InterestTaxonomyFormEditor
```

- 引导视图：`Features/Launch/Views/AppWelcomeGuideView.swift`
- 呈现入口：`Features/Activities/ActivitiesView.swift`
- 权限链（跟踪 / 通知）：欢迎引导关闭后再弹（`ContentView` + `PermissionLaunchPrompts`）

### 已移除（勿再引用）

| 项 | 说明 |
|----|------|
| `OnboardingSheet` | 全屏兴趣选择引导 |
| `ActivityIntentMomentSheet` | 活动 Tab「想做什么」意图 Sheet |
| `ActivityLayoutDemoView` | 布局演示页 |
| `ActivityCatalogSeeAllSheet` | 活动目录查看全部 Sheet |
| `InterestTaxonomyPicker` | Chip 流兴趣选择（已由 Form Toggle 编辑器替代） |
| 活动详情「私信发起人」 | 详情页不再提供 DM 发起人入口；成员 Sheet / 群聊保留 |

### 工程约束

- 导航目的地：见 `.cursor/rules/navigation-destination.mdc`
- 改完不自动 `xcodebuild`：见 `.cursor/rules/no-auto-build.mdc`

---

*新增文档前先更新本索引，避免多份文档描述同一实现细节时互相矛盾。*

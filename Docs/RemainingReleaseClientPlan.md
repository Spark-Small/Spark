# 坐标系 · 剩余客户端修改方案（Apple 对齐）

> **状态**：Wave-L/P/C/A/M/D/S **编码已落地**；另已完成架构错误通道 / 旅程种子 / 原生规范收口（2026-09-29）  
> **依据**：[ReleaseEngineeringPlan.md](ReleaseEngineeringPlan.md) §11–§13 · [ReleaseReadinessAudit.md](ReleaseReadinessAudit.md) §0 · [DevelopmentGuide.md](DevelopmentGuide.md)  
> **范围**：诚实门控后客户端独立项；真支付 / IM / 供给 / Apple 服务端校验见 §8（非本方案编码范围）。  
> **版本**：2026-09-29

---

## 0. 原则（官方推荐 → 本仓落地）

| Apple / 行业推荐 | 本仓做法 |
|------------------|----------|
| [App Store Review 5.1.1](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)：隐私政策可访问 | 托管 HTTPS 页 + App 内可 `OpenURL`；App 内长文仅作离线兜底 |
| [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) | 已有 `PrivacyInfo.xcprivacy`；本方案不重复造清单，只核对声明与真实 API 一致 |
| [SwiftData 版本化迁移](https://developer.apple.com/documentation/swiftdata/schemamigrationplan) | 已有 `VersionedSchema` + `SchemaMigrationPlan`；**改模型必须升版本 + stage**，禁止 silent reset |
| MainActor 串行写 / 避免竞态 | Domain Model + Gateway 均用 `MainActorPersistence.chained`；写失败进 `AppPersistenceHealth` 横幅 |
| [HIG · Accessibility · Reduce Motion](https://developer.apple.com/design/human-interface-guidelines/accessibility) | `PlatformMotion.withAnimation` / `platformAnimation`；业务侧少直接 `withAnimation` |
| [HIG · Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback) | 内容拦截用系统 alert / `platformFeedbackAlert`，说明原因与申诉入口 |
| Swift API Design：一文件一主类型 | 巨型文件继续按 [GiantFileSplitPlan](GiantFileSplitPlan.md) |
| 不破坏审计「不要动」 | Tab / `navigationDestination` / Domain UseCase / Repository 四层结构不动 |

**交付纪律**：改完不主动 `xcodebuild`；结论写「按代码推断」；涉及公共 API / 导航 / 新增文件时，结尾请人工编译确认。

---

## 1. 现状快照（本方案执行后）

| 原 ID | 实况 |
|-------|------|
| B1-3 | ✅ Schema V1 + MigrationPlan；改 Model 纪律已写入 DevelopmentGuide |
| B1-6 | ✅ Feature Model + Gateway chained；写失败横幅已接 |
| B2-5 | ✅ `LegalDocumentURLs` 外开；离线兜底；**托管页须公网可达** |
| B2-6 | ✅ CI 注释与 destination 说明 |
| B2-7 | ⚠️ 基线 tag **需人工**打出 |
| B6-4 | ✅ 主路径已迁 `PlatformMotion`（含 Launch / 聊天滚动 / 收藏等） |
| B7 内容过滤 | ✅ `scanText` + 青少年词表；UGC 主路径已挂钩 |
| B7 部署目标 | ✅ 维持 26.5 |
| 巨型文件 | ✅ Split-A…J（见 GiantFileSplitPlan）；SampleData 等数据袋不按 UI 规则硬拆 |
| 架构收口 | ✅ 写失败统一上报；`LocalMediaLibrary`；Ledger DI；Release 种子诚实；离线发送失败 |
| 原生规范 | ✅ SIWA / a11y material / Launch Metrics（见审计 §8） |

---

## 2. 执行波次（建议 PR 切分）

```text
Wave-L  合规外链（B2-5）           提审前门禁 · 优先
Wave-P  持久化写路径（B1-6 余量）   数据安全
Wave-C  CI + 基线（B2-6 / B2-7）   可复现
Wave-A  减弱动态（B6-4）           体验 / a11y
Wave-M  文本内容过滤增强           审核成熟度
Wave-S  巨型文件 Split-C…          可穿插 · 见独立文档
Wave-D  部署目标决策               默认「维持」，仅文档
```

后端阻塞项（支付 PSP、IM、供给目录、Apple token 校验）**不进 Wave 编码**；见 §8。

---

## 3. Wave-L · 隐私政策 / 用户协议托管 URL（B2-5）

### 3.1 目标

满足 Review：**设置与登录勾选处可打开可访问的隐私政策网页**（Guideline 5.1.1）。App 内文案保留为无网兜底。

### 3.2 落点

| 文件 | 改动 |
|------|------|
| 新建 `Services/LegalDocumentURLs.swift`（或扩 `LegalConsentStore`） | `static let privacy` / `agreement`：Release 为 `https://…`；Debug 可 xcconfig 覆盖 |
| `ProfileComplianceOpsViews.swift` | `legal://` 优先 `OpenURL` 外开托管页；失败再 sheet 本地 `PrivacyPolicyView` |
| `LocalAuthSheet` / 设置「隐私政策」入口 | 同策略：按钮外开 + 「离线查看」次级入口 |
| `Info.plist` / 文案 | 无需 ATS 例外（仅 HTTPS） |

### 3.3 Apple 对齐要点

1. URL 必须 **HTTPS**、公网可达（提审前用真机 Safari / App 内点开验证）。  
2. 页面声明收集类型与 `PrivacyInfo.xcprivacy`、App 内权限文案一致。  
3. 青少年 / 认证照 / 内容安全等已在本地文案中的能力，网页需同步，避免「App 说有、网页没有」。  
4. 使用系统 `OpenURLAction` / `Link`，不要自绘不可访问的假链接。

### 3.4 验收

- [ ] Release 构建点击「隐私政策」「用户协议」可打开托管页  
- [ ] 无网时仍可看本地全文（兜底）  
- [ ] 更新 [ReleaseEngineeringPlan §11](ReleaseEngineeringPlan.md) 对应勾选  

### 3.5 产品依赖

需先提供最终托管域名（建议 `https://www.zuobiaoxi.com/privacy` · `/terms`）。无域名时：**阻塞 Wave-L 合入提审**，可先用占位常量 + `#if DEBUG` 本地页。

---

## 4. Wave-P · SwiftData 写路径与迁移纪律（B1-3 / B1-6）

### 4.1 B1-3 · 迁移纪律（骨架已在，补流程）

**现状**：`坐标系/Models/Persistence/AppSwiftDataSchema.swift` 已按 Apple 推荐接好 `migrationPlan:`。

**下次改模型的强制步骤**：

1. 新增 `AppSwiftDataSchemaV2: VersionedSchema`（`versionIdentifier` 递增）。  
2. `AppSwiftDataMigrationPlan.schemas` 追加 V2。  
3. `stages` 增加 `.lightweight` 或自定义 `MigrationStage`（轻量可自动的字段增删走 lightweight；重命名 / 变换用自定义）。  
4. `AppSwiftDataContainer` 的 `Schema(versionedSchema:)` 指向**最新** schema。  
5. 在 DevelopmentGuide 持久化自检增加：「改 `@Model` 必升版本」。

**禁止**：删库、用 seed 覆盖用户容器、依赖「装不上就清 App」。

**本 Wave 代码量**：以文档 + PR 自检勾选为主；无字段变更则不必造空 V2。

### 4.2 B1-6 · Gateway 写串行

**问题**：`SwiftDataSnapshotGateway.save` 每次裸 `Task { try? await actor.saveSnapshot }`，快速连续写可能乱序，且吞错。

**推荐改法**（对齐 `MainActorPersistence.chained`）：

```swift
// 示意：Gateway 内
private var saveTask: Task<Void, Never>?

func save(_ snapshot: Snapshot) {
    cached = snapshot
    let previous = saveTask
    let copy = snapshot
    saveTask = MainActorPersistence.chained(after: previous) {
        do {
            try await self.actor.saveSnapshot(copy, domainKey: self.domainKey)
        } catch {
            // 挂钩已有落盘失败提示通道（与 ActivitiesModel 一致），勿静默 try?
        }
    }
}
```

| 项 | 要求 |
|----|------|
| 串行 | 同一 Gateway 实例写操作 chained |
| 错误 | 不再无限 `try?`；至少遥测 / 可观察失败（与 B1-5 提示策略一致） |
| 后台 | 已有 `flushPersistenceForBackground`；确认 Gateway 未完成 Task 在 flush 时被 await |
| 测试 | 单元：连续 save A→B，磁盘最终为 B |

**不要动**：Repository 协议形状、Domain UseCase。

### 4.3 验收

- [ ] Gateway 连续写最终一致  
- [ ] 写失败可被用户或日志感知  
- [ ] DevelopmentGuide / PR 自检写入「改 Model → 升 Schema」  

---

## 5. Wave-C · CI 与基线（B2-6 / B2-7）

### 5.1 B2-6 · `ios-test.yml`

**现状**：`.github/workflows/ios-test.yml` → `-destination '…iPhone 16 Pro'`；工程 `IPHONEOS_DEPLOYMENT_TARGET = 26.5`。

**推荐**：

1. destination 与本地常用模拟器对齐；若 runner 无该机型，改用 `generic/platform=iOS Simulator` 或文档化固定 `id=`。  
2. workflow 注释写明：**部署目标以 pbxproj 为准**；升级 Xcode / 系统时同步改 destination。  
3. 保留 `Scripts/check-imports.sh` + `Packages/CoordinateKit` `swift test`（已符合模块边界 CI）。  
4. 不在 CI 默认跑全量 UI 测试（除非已稳定）；失败要可复现。

参考：[Running tests](https://developer.apple.com/documentation/xcode/running-tests-and-determining-code-coverage) — destination 必须存在于 runner。

### 5.2 B2-7 · 基线 tag

| 步骤 | 说明 |
|------|------|
| 命名 | `release-readiness-2026-09-29`（或审计日后的客户端门控收口日） |
| 内容 | 含诚实门控合入后的 main；附 ReleaseEngineeringPlan §13 摘要 |
| 禁止 | force-push 改写该 tag |

本项为**流程**，代码 PR 可不含文件变更。

### 5.3 验收

- [ ] CI 在干净 runner 绿（或已知 skip 有文档）  
- [ ] 基线 tag 已打并可 checkout  

---

## 6. Wave-A · 减弱动态效果收敛（B6-4）

### 6.1 缺口

`PlatformMotion.resolved` / `platformAnimation(_:value:)` 已存在；业务仍大量 `withAnimation(…)`（Launch 信封、活动筛选、消息 Sheet 等）。`withAnimation` **不会**自动读 `accessibilityReduceMotion`。

### 6.2 推荐 API

在 `PlatformAccessibilityChrome.swift`：

1. View 内：`@Environment(\.accessibilityReduceMotion)` + `withAnimation(PlatformMotion.resolved(anim, reduceMotion:))`。  
2. 抽小型 helper（如 `platformWithAnimation`），避免复制。  
3. **装饰性**大动画（信封展开）：reduceMotion 时直接切终态（HIG：提供等价非动画结果）。  
4. **不要**改气泡双击点赞的 gesture（已有 a11y action，审计已认可）。

### 6.3 迁移顺序

| 优先级 | 区域 |
|--------|------|
| P0 | `ContentView`、Tab 切换相关 |
| P1 | `ActivitiesView` / 筛选条、`MessagesSocialSheets` |
| P2 | `Features/Launch` 信封与登录动效 |
| P3 | `PlatformFeedback`、其余 Design |

每批纯替换，无产品逻辑变更。

### 6.4 验收

- [ ] 系统开启「减弱动态效果」时，迁移过的入口无大段位移动画  
- [ ] 功能仍可达（终态正确）  

---

## 7. Wave-M · 文本内容过滤增强（批次 7）

### 7.1 现状

| 能力 | 状态 |
|------|------|
| 图片 | `MediaModerationService`（头像 / 聊天 / 社区 / 封面） |
| 文本 | `ContentModeration.containsSensitive` 词表极少；挂钩不全 |

### 7.2 推荐架构（客户端可独立做的部分）

```text
用户输入 → ContentSafety.scanText(_:) → .allow / .block(reason)
                ↑
        本地词表（可配置） + 可选 Remote API（FeatureFlag）
```

| 项 | 做法 |
|----|------|
| API | 扩展 `ContentModeration` 或新建 `ContentSafety`；返回原因字符串供 alert |
| 挂钩 | 社区发帖、聊天发送、资料昵称/简介、活动标题/描述（与图审挂钩点对称） |
| 青少年 | `YouthModePreference` 更严词表或直接拦更多类 |
| 误杀 | 文案指向已有举报 / 工单申诉（勿静默失败） |
| 远程 | `FeatureFlags` 控制；失败策略与图审一致（fail-open / fail-closed 写进 Flag 注释） |
| 隐私 | 远程送文本需隐私政策披露；仅本地词表则无新增收集 |

对齐：[App Review 1.2 User-Generated Content](https://developer.apple.com/app-store/review/guidelines/#user-generated-content) — 过滤 + 举报 + 封禁能力需可演示。

### 7.3 非目标

- 不在本 Wave 接完整服务端审核台  
- 不替换已有 `MediaModerationService`  

### 7.4 验收

- [ ] 敏感词发送被拦并提示  
- [ ] 青少年模式可观测更严  
- [ ] 举报入口仍可用  

---

## 8. 明确不做（本方案编码范围外）

| 项 | 原因 | 客户端可预备 |
|----|------|--------------|
| 真 Apple Pay / 微信 / 支付宝 / 退款回调 | 需 PSP + 后端 | 保持 `CommercePaymentPolicy` 诚实门控 |
| WebSocket / APNs IM | 需 IM 与推送证书 | 保持 `MessagingDeliveryPolicy` + `.failed` 重发 |
| 远程陪玩目录 | 需供给 API | 保持空态文案 + `useRemoteBuddies` |
| Apple identityToken 服务端校验 | 需 Auth 后端 | 客户端已有 `SignInWithAppleButton` + 凭证状态检查 |
| 部署目标下调 | 产品 / 覆盖面决策；当前 26.5 与工具链绑定 | §9 仅记录决策，默认维持 |

---

## 9. Wave-D · 部署目标（决策，默认不改代码）

| 选项 | 含义 |
|------|------|
| **维持 26.5（推荐默认）** | 与当前 Xcode / API（含新 glass 等）一致；首发 iPhone-only |
| 下调 | 需审计新 API availability、大面积 `#available`，成本高 |

写入 ReleaseEngineeringPlan：「部署目标维持至产品书面要求下调」。无书面要求则 **Wave-D 无代码 PR**。

---

## 10. Wave-S · 巨型文件（指针）

执行细节不重复：见 [GiantFileSplitPlan.md](GiantFileSplitPlan.md)。

| 顺序 | 文件（约行数） |
|------|----------------|
| Split-C | `WalletPassFace.swift` (~1028) |
| Split-D | `ActivityDetailSections.swift` (~876) |
| Split-E | `PlatformReviewsUI.swift` (~801) |
| Split-F | `PlatformMessagesChrome.swift` (~750) |
| Split-G | `ProfileAccountCommercialViews.swift` (~736) |

规则：Design 不塞 Feature 业务 Model；编排器 + 具名子 View；不新增重复 `navigationDestination`。

---

## 11. 建议实施顺序（本周 → 提审）

1. **Wave-L**（有托管 URL 即可开工；无 URL 则并行催产品）  
2. **Wave-P** Gateway chained（纯工程，可立刻）  
3. **Wave-C** CI destination + tag  
4. **Wave-A** / **Wave-M** 穿插  
5. **Wave-S** 按评审带宽  
6. 真机走完 [ReleaseEngineeringPlan §11](ReleaseEngineeringPlan.md) 门禁  

---

## 12. 完成定义（本方案）

- [x] Wave-L：托管隐私 / 协议 URL 已接线（`LegalDocumentURLs` → 外开；离线兜底保留）— **提审前须确认公网页可达**  
- [x] Wave-P：Gateway 写串行 + 迁移纪律写入 DevelopmentGuide / Schema 文件头  
- [x] Wave-C：CI workflow 注释与 destination 说明；基线 tag **需人工** `git tag release-readiness-2026-09-29`  
- [x] Wave-A：`PlatformMotion.withAnimation`（含 P3：OrgScaffold / Thread / Bubble / 收藏 / Detail 书签）  
- [x] Wave-M：`ContentModeration.scanText` 挂钩聊天 / 发帖 / 转发 / 资料 / 活动 / 评论  
- [x] Wave-D：部署目标维持 **26.5**（无代码变更）  
- [x] Wave-S Split-C…J：票面 / 详情 / 评价 / 消息 chrome / 商业页 / 参加确认 / 搭子详情段 / 设置页  
- [x] Wave-P 余量：Gateway 写失败 → `AppPersistenceHealth` 可关闭横幅  
- [ ] §8 后端项仍未勾 —— **预期**  
- [ ] 人工编译 / 真机抽检；托管隐私页公网可达；基线 tag  

---

## 13. 本轮落地摘要（2026-09-29）

| Wave | 主要落点 |
|------|----------|
| L | `LegalDocumentURLs`；设置外开 + 离线入口 |
| P | Gateway chained + 写失败横幅；Schema 升级纪律 |
| C | CI workflow 注释 |
| A | `PlatformMotion` 覆盖主业务动画入口 |
| M | `scanText` + youth 词表；UGC 主路径 |
| D | 部署目标维持 26.5 |
| S | Split-A…J（见 GiantFileSplitPlan） |
| 续 | 审计 §7–§9：种子诚实、离线发送失败、`LocalMediaLibrary`、Ledger DI、原生 a11y |

**本方案编码完成**。提审前人工项见 §12；后端见 §8。

# 坐标系 · 上线工程开发方案

> **依据**：[ReleaseReadinessAudit.md](ReleaseReadinessAudit.md)（2026-09-27）  
> **定位**：正式产品（真实后端、支付、Sign in with Apple）  
> **原则**：审计 §13「不要动」的 Tab / Navigation / Domain UseCase / Repository 四层结构保持不动；按批次交付，每批可独立合入。  
> **版本**：2026-09-29

---

## 0. 目标与约束

| 目标 | 说明 |
|------|------|
| 清除全部 **P0** | 不修不能上架 |
| 完成关键 **P1** | 持久化三项 + 发布配置 |
| 后端 / 第三方并行 | 批次 3–5 依赖服务端，客户端先做接口与开关 |

**不要动**（审计明确）：

- Tab / `NavigationStack` / `navigationDestination` helper  
- Domain UseCase 与现有测试  
- 系统 alert、语义字体、PhotosPicker 写法、strict concurrency  
- 账号注销流程、权限请求时机  
- Repository 四层结构（接后端后会用）

---

## 1. 总览：7 个工程批次

```text
批次 1  数据安全与崩溃     纯客户端 · 可立刻开工
批次 2  审核合规与发布配置  纯客户端 + 托管隐私政策页
批次 3  真实登录与会话      依赖后端 Auth
批次 4  支付与退款          依赖支付通道 + 后端订单
批次 5  陪玩供给 + 实时消息  依赖后端 / IM
批次 6  体验与无障碍       纯客户端
批次 7  P2/P3 成熟度        可并行穿插
```

建议日历（1 iOS + 后端并行）：**批次 1–2 ≈ 1–1.5 周** → **3–5 ≈ 4–8 周** → **6–7 穿插**。

---

## 2. 批次 1 — 数据安全与崩溃（P0 #1–#3 + P1 持久化）

**目标**：冷启动不再闪退 / 静默清空用户数据；演示行程不再污染真实账号。  
**依赖后端**：否。

### 2.1 任务清单

| ID | 改动 | 主要落点 | 验收 |
|----|------|----------|------|
| B1-1 | SwiftData 容器失败降级 | `坐标系App.swift` | 失败时内存容器 + 可恢复错误页；禁止 `fatalError` |
| B1-2 | 快照解码失败不覆盖 | `DomainSnapshotModelActor` · `LocalSnapshotFileStore` | 解码失败先备份；不写种子覆盖；有用户可见提示或遥测 |
| B1-3 | 补迁移骨架 | `AppSwiftDataSchema*` + `SchemaMigrationPlan`（若尚无） | 字段变更走迁移，而非 silent reset |
| B1-4 | 移除演示行程注入 | `AppModel` · `PassDemoBootstrap` · `ActivitiesModel+DemoJourney` · `ActivityPaymentFlow` | Release / 正式用户路径无「剧本杀」静默报名与假已支付订单；`#if DEBUG` 可保留演示入口 |
| B1-5 | 落盘错误上抛 | `ActivitiesModel` · `BuddiesModel` · `CommunityModel` 等 `try?` | 关键写失败有提示；可重试 |
| B1-6 | 保存竞态 | `SwiftDataSnapshotStore` | 改用 `MainActorPersistence.chained`（或等价 generation 串联） |
| B1-7 | 进后台 flush | `ContentView` / `坐标系App` `scenePhase` | `.background` 时强制落盘 |

### 2.2 实现要点

1. **容器失败**：`do/catch ModelContainer` → 降级 `isStoredInMemoryOnly`；设 `persistenceRecoveryNeeded` 驱动全屏恢复 UI。  
2. **解码失败**：读失败时把坏文件移到 `*.corrupt.<timestamp>`；返回空或上次成功缓存；**禁止** `save(seed)`。  
3. **演示注入**：`bootstrapDemoJourney` / PassKit demo 仅 `#if DEBUG` 或显式 Debug 菜单触发；Release 二进制零调用。

### 2.3 测试

- 单元：坏 JSON / 缺字段解码不覆盖；chained 保存顺序。  
- 手工：杀进程前改数据 → 进后台 → 杀 → 重启仍在；无演示活动。

---

## 3. 批次 2 — 审核合规与发布配置（P0 #4、#10 + 发布项）

**目标**：过 App Review 基础门槛；可复现基线。  
**依赖后端**：否（隐私政策需网页托管）。

| ID | 改动 | 落点 | 验收 |
|----|------|------|------|
| B2-1 | 删除会员「本地演示开通」 | `ProfileAccountCommercialViews` | Release 仅 StoreKit / `SubscriptionStoreView` |
| B2-2 | 新建 `PrivacyInfo.xcprivacy` | 工程根 / target 资源 | 声明 UserDefaults（`CA92.1`）及收集类型；可上传 ASC |
| B2-3 | 正式 Bundle ID | `project.pbxproj` | 反向域名，非 `coordinate.---` |
| B2-4 | 去掉明文 ATS / 硬编码 IP | `Info.plist` · `APIConfiguration` | Release 仅 HTTPS 域名；Debug 可用 xcconfig |
| B2-5 | 隐私政策 / 用户协议 URL | `LocalAuthSheet` 等 | 可打开托管页（非仅 App 内长文） |
| B2-6 | 提交 CI workflow | `.github/workflows/ios-test.yml` | runner / 模拟器与部署目标匹配 |
| B2-7 | 分批提交 + 基线 tag | git | 可复现审计后代码基线 |

**产品同步**：付费陪玩 + 外貌标签的审核类目文案（审计 P1 政策项）需产品确认，可与本批并行出说明稿。

---

## 4. 批次 3 — 真实登录与会话（P0 #7 + Keychain）

**目标**：假 Apple / 微信 / 固定验证码退出正式路径。  
**依赖后端**：是（identity token 校验、短信、refresh）。

| ID | 改动 | 落点 | 验收 |
|----|------|------|------|
| B3-1 | Sign in with Apple | `LoginView` · entitlements · `AuthenticationServices` | 真 `SignInWithAppleButton`；`getCredentialState`；无自绘假按钮 |
| B3-2 | 短信走远程 | `LocalAuthSession` → `RemoteAuthAPI` | 无固定 `123456`（Debug 假码需显式开关） |
| B3-3 | 微信（可选一期） | 官方 SDK | 或一期隐藏入口，避免假按钮 |
| B3-4 | Token 进 Keychain | `AuthTokenStore` | 不用 `UserDefaults` 存 JWT；使用 `expiresIn` |
| B3-5 | 401 refresh 重放 | `APIClient` | refresh 失败清会话回登录 |

**后端对齐**：`/auth/sms/*`、`token/refresh`、Apple identity 校验（见后端 `LaunchModulesPlan` B1）。

---

## 5. 批次 4 — 支付与退款（P0 #5、#6）

**目标**：去掉假 Apple Pay / 假充值；钱以服务端为准。  
**依赖后端**：是。

| ID | 改动 | 落点 | 验收 |
|----|------|------|------|
| B4-1 | 活动 / 陪玩支付 | `ActivityJoinConfirmSheet` · `WalletPayment` · `ActivityPaymentFlow` | 无 `Task.sleep` 假成功；展示方式与真实通道一致 |
| B4-2 | 钱包充值 | `ProfileAccountCommercialViews` | 数字商品不走余额买 IAP；线下服务走合规通道 |
| B4-3 | 退款 | `RefundFlow` | 去掉两段 sleep 自动完成；服务端状态 + 轮询/推送 |
| B4-4 | 会员 | 已有 StoreKit | 接 App Store Server Notifications / 收据校验（后端） |
| B4-5 | 去掉 `walletStore!` | `ActivityPaymentFlow` · `AppDomainServices` | 注入失败可失败，不强制解包崩溃 |

**客户端诚实门控（本批已落地，无真实 PSP 前）**：

- `CommercePaymentPolicy`：Release 仅钱包余额结账；外部方式不可选且 `charge`/`topUp` 拒绝假成功。
- 退款：Release 保持「已提交」，不 sleep 自动完结；DEBUG 仍可本地演示完结。
- 会员：Release 仅 `SubscriptionStoreView`；`applyDemoEntitlement` 仅 DEBUG。
- **仍待后端**：真实 Apple Pay / 微信 / 支付宝、服务端订单回调、退款回调、ASN。

**产品决策（开工前必须定）**：

- 活动 / 预约：Apple Pay vs 微信/支付宝（中国区）  
- 钱包余额能否买什么（避免 3.1.1）

---

## 6. 批次 5 — 陪玩供给 + 实时消息（P0 #8、#9）

**目标**：无虚构接单、无自动回复。  
**依赖后端 / IM**：是。

| ID | 改动 | 落点 | 验收 |
|----|------|------|------|
| B5-1 | 关 Release 模拟接单 | `FeatureFlags.simulateBookingCompanionAcceptance` | Release 恒 `false` |
| B5-2 | 陪玩目录远程 | `BuddiesModel+Browse` · `RemoteBuddiesRepository` | 非 `SampleData` 主路径 |
| B5-3 | 预约状态机服务端推进 | `BuddiesModel+Bookings` · booking API | 与 Domain UseCase 对齐；超时由服务端 / Worker |
| B5-4 | 删除自动回复 | `MessagesModel` | 无 `Task.sleep` 伪造对方消息 |
| B5-5 | IM / WebSocket + APNs | `chat/token` · Messages | 双端互发；离线推送 |
| B5-6 | 发送失败态 + 重发 | `MessagesModel` | `.failed` 可见可重试 |
| B5-7 | 消息分页 | `MessagesModel+ConversationDetail` | 不全量塞进内存 |

**客户端诚实门控（本批已落地，无真实供给 / IM 前）**：

- `useSampleBuddiesCatalog` Release 恒 `false`；发现页空态「真人供给接入中」。
- Release `useRemoteBuddies` / `useRemoteMessages` 恒 `true`（尝试同步；失败保留本地空）。
- 邀约 / 接单 sleep 模拟仅 `#if DEBUG`；预约确认超时仍走 Domain UseCase。
- `MessagingDeliveryPolicy`：Release 不自动回复、不假已读、发送保持「已发送」。
- `ChatDeliveryStatus.failed` + 重发；会话详情本地分页窗口（默认 80）。
- **仍待后端**：陪玩目录 API、接单推进、WebSocket / APNs、服务端消息回执。

---

## 7. 批次 6 — 体验与无障碍（其余 P1）

**依赖后端**：否。

| ID | 改动 | 落点 |
|----|------|------|
| B6-1 | 社区空 / 错分离 + `.refreshable` | `CommunityModel` · `CommunityView` |
| B6-2 | 跳过反馈 / 复盘持久化 | `ActivitiesModel+ParticipationJourney` 调用 `skipActivityFeedback` / `skipActivityRecap` |
| B6-3 | `accessibilityReduceTransparency` | `PlatformSurface` 等 glass / material 统一降级 |
| B6-4 | `reduceMotion` 覆盖动画入口 | ContentView 等 37 处收敛到 helper |
| B6-5 | 聊天图异步解码 | `PlatformMessagesChrome` |
| B6-6 | 图片选择失败提示 | `ConversationDetailView` · `CommunityComposeSheet` |
| B6-7 | `signOut` 清理钱包等旁路状态 | 与 `deleteLocalAccount` 对齐策略 |
| B6-8 | `onTapGesture` → `Button`；44pt | 审计点名处 |

**本批落地**：

- B6-1：`loadErrorMessage` + 空/错分态 + `.refreshable`
- B6-2：复盘「跳过」写入 `skipActivityRecap`（详情 / 发帖 Sheet）
- B6-3：`platformThinMaterialBackground` + glass CTA 在降低透明度时退化为 bordered
- B6-4：`platformAnimation` / `PlatformMotion`；ContentView 与气泡时间切换已接
- B6-5：`PlatformAsyncFileImage` + `NSCache`
- B6-6：选图失败 `platformFeedbackAlert`
- B6-7：`signOutLocally` 清钱包 / Pass / 订单 / 会员本地态
- B6-8：协议勾选改 `Button` + 44pt；语音角标扩大命中区

---

## 8. 批次 7 — P2 / P3 成熟度（可穿插）

| 优先级 | 项 |
|--------|-----|
| 高 | `PassPackageBuilder` 去掉危险 `main.sync`；活动文字搜索；iPad 策略（适配或只上 iPhone） |
| 中 | 拆分 >600 行文件（`BuddyPaidMarketViews`、`ConversationDetailView`）；伪造在线 / 点赞 / 排行改为真实或标注「示例」 |
| 中 | `APIClient` timeout / 重试 / 取消 / `NWPathMonitor`；内容过滤增强 |
| 低 | 死代码清理、`print`、单例可测化、部署目标是否下调 |

**本批落地**：

- Pass 打包改为 `@MainActor` 渲染，删除 `DispatchQueue.main.sync`
- 活动 `.searchable` + Domain `searchText` 过滤（标题 / 地点 / 主办 / 标签）
- 首发只上 iPhone：`TARGETED_DEVICE_FAMILY = 1`
- `APIClient`：自定义 timeout、运输层重试、取消检查、`NWPathMonitor` / `APIError.offline`
- 点赞列表不再 SampleData 补人；榜单标注「示例榜」；角标去哈希抽签
- 广告 impression 去掉 `print`

**巨型文件拆分**：见 [GiantFileSplitPlan.md](GiantFileSplitPlan.md)（Split-A BuddyPaid / Split-B ConversationDetail 已落地，待编译确认）。

**剩余客户端缺口（可独立开工）**：见 [RemainingReleaseClientPlan.md](RemainingReleaseClientPlan.md)（隐私托管 URL、Gateway 写串行、CI/tag、reduceMotion、文本过滤、巨型文件 Split-C…）。

**未做（可后续 / 见剩余方案）**：内容过滤增强、部署目标决策（默认维持 26.5）；其余巨型文件按同规则穿插。

**仍依赖后端（本方案不做）**：真支付/退款、真 IM、远程陪玩目录、Apple identityToken 服务端校验。

---

## 9. 工程落地节奏（建议 PR 切分）

| PR | 内容 | 风险 |
|----|------|------|
| PR-A | B1-4 演示注入移除（最先、最小） | 低 |
| PR-B | B1-1～B1-3 容器与解码安全 | 中（持久化） |
| PR-C | B1-5～B1-7 落盘韧性 | 中 |
| PR-D | B2 合规与配置（xcprivacy、Bundle ID、ATS、假会员入口） | 低–中 |
| PR-E | B3 登录 + Keychain（可 Feature Flag 灰度） | 高 |
| PR-F | B4 支付（按通道拆多个 PR） | 高 |
| PR-G | B5 陪玩 + 消息 | 高 |
| PR-H | B6 体验无障碍 | 低 |

每 PR：**编译**（你明确要求时再跑）→ 相关 Feature 回归 → 确认未破坏导航 helper / Domain 测试。

---

## 10. 与后端工作的对应

| 客户端批次 | 后端应对（`坐标系后端/docs`） |
|------------|------------------------------|
| 批次 3 | 真短信 / Apple 校验 / refresh（B1-AUTH） |
| 批次 4 | `commerce` 订单 / 回调 / 退款（B4） |
| 批次 5 | `booking` 模块 + 真 `ImProvider`（B2） |
| 全阶段 | HTTPS、关 demo 开关、Admin 审核 |

客户端 **批次 1–2 不阻塞** 后端；应与后端 B0/B1 **并行**。

---

## 11. 完成定义（上线门禁）

对照审计 §12，全部打勾才可提审：

- [x] 无启动演示行程注入  
- [x] 解码失败不覆盖用户数据；容器失败不闪退  
- [x] 无会员绕过 IAP；无假充值 / 假 Apple Pay 文案（客户端门控；真通道仍待 PSP）  
- [x] 真 Sign in with Apple（或隐藏入口）；无固定验证码正式路径  
- [x] 有 `PrivacyInfo.xcprivacy`；隐私政策 URL 已接线（`LegalDocumentURLs`；**托管页须公网可达后再提审**）  
- [x] Release 无模拟接单、无聊天自动回复、无 SampleData 陪玩交易主路径  
- [ ] 支付 / 退款以服务端为准（客户端已诚实门控；服务端订单/回调未接）  
- [ ] 真 IM / 陪玩供给 API（客户端已空态 + 远程开关；通道未接）  
- [x] 后台落盘；关键写失败有提示  
- [x] Bundle ID / HTTPS / CI 基线就绪（iPhone 首发；真支付 / IM / 供给 API 仍待）
- [x] 活动文字搜索；Pass 打包无 `main.sync`；APIClient 具备 timeout / 重试 / 离线检测  
- [x] 部署目标维持 26.5（见 RemainingReleaseClientPlan Wave-D）
- [x] Release 种子无静默报名；repair 不并回 seed `joinedIDs`；离线发送标失败可重试  

---

## 12. 下一步（提审前）

客户端批次 1–7 与 Remaining Wave 编码已收口。优先：

1. **后端并联**：Auth identity 校验 · 订单/PSP · IM/APNs · 陪玩供给（见 §10）  
2. **托管页**：隐私 / 协议 HTTPS 公网可达（`LegalDocumentURLs`）  
3. **工程**：`git tag` 基线 · 真机走完 §11 · 提审前编译与抽检  
4. **产品**：付费陪玩审核类目说明  

历史「第一刀」B1-4 / B1-1 / B1-2 / B2-1+B2-2 **已完成**，见 §13。

---

## 13. 落地进度（2026-09-29）

| 项 | 状态 |
|----|------|
| B1-4 演示行程 `#if DEBUG` | ✅ |
| B1-1 容器降级 + 恢复横幅 | ✅（原有降级 + `PersistenceRecoveryBanner`） |
| B1-2 解码失败备份不覆盖 | ✅（补全 `backupCorruptPayload`） |
| B1-5 落盘失败提示 | ✅（Activities / Buddies 等） |
| B1-7 后台 flush | ✅（`scenePhase` → `flushPersistenceForBackground`） |
| B2-1 假会员开通 Release 隐藏 | ✅ |
| B2-2 `PrivacyInfo.xcprivacy` | ✅ |
| B2-3 Bundle ID → `app.zuobiaoxi.coordinate` | ✅（提审前可再改正式域名） |
| B2-4 ATS 去测试机明文 IP；Release HTTPS baseURL | ✅ |
| Release 关模拟接单 / demo 审核代理 | ✅ |
| 聊天自动回复仅 DEBUG | ✅ |
| 反馈「跳过」持久化 | ✅ |
| 钱包假充值 Release 禁用 | ✅ |
| **B3-1 Sign in with Apple** | ✅ `SignInWithAppleButton` + entitlement + 凭证吊销检查 |
| **B3-2 远程短信** | ✅ Release `useRemoteAuth=true`；获取验证码；本地码仅 DEBUG |
| **B3-3 微信假按钮** | ✅ Release 隐藏；DEBUG 保留演示 |
| **B3-4 Keychain Token** | ✅ `AuthTokenStore` + `expiresIn`；迁移旧 UserDefaults |
| **B3-5 401 refresh** | ✅ `APITokenRefreshing` + `auth/token/refresh` |
| **B4-1 活动/陪玩支付** | ✅ `CommercePaymentPolicy`；Release 仅钱包；外部假到账拒绝 |
| **B4-2 钱包充值** | ✅ Release「暂不可用」+ `topUp` 硬门控 |
| **B4-3 退款** | ✅ Release 不 sleep 自动完结，保持「已提交」 |
| **B4-4 会员** | ✅ Release 仅 StoreKit；demo entitlement 仅 DEBUG |
| **B4-5 walletStore!** | ✅ optional + `requireWallet()` 失败返回 |
| **B5-1 模拟接单** | ✅ Release 恒关；模拟逻辑 `#if DEBUG` |
| **B5-2 陪玩目录** | ✅ Release 禁用 SampleData 发现；空态诚实文案 |
| **B5-3 预约推进** | ✅ 无远程时不假接单；确认超时仍本地 Domain |
| **B5-4 自动回复** | ✅ `MessagingDeliveryPolicy` Release 关闭 |
| **B5-5 IM 通道** | ⚠️ 客户端尝试远程快照；WebSocket / APNs 未接 |
| **B5-6 失败重发** | ✅ `.failed` + `retrySend` UI |
| **B5-7 消息分页** | ✅ 本地窗口分页（默认 80） |
| **B6-1 社区空/错** | ✅ `loadErrorMessage` + refreshable |
| **B6-2 跳过复盘** | ✅ 详情 / Compose 接入 `skipActivityRecap` |
| **B6-3 降低透明度** | ✅ material / glass CTA 降级 |
| **B6-4 减弱动态** | ✅ `platformAnimation` helper（入口已接；其余可逐步迁移） |
| **B6-5 聊天图异步** | ✅ `PlatformAsyncFileImage` |
| **B6-6 选图失败** | ✅ 聊天 / 发帖 alert |
| **B6-7 退登清钱包** | ✅ `clearCommerceSideStateOnSignOut` |
| **B6-8 点击可达** | ✅ 协议勾选 Button + 语音角标 44pt |
| **B7 Pass main.sync** | ✅ `@MainActor` 渲染，去掉 sync |
| **B7 活动搜索** | ✅ `.searchable` + Domain `searchText` |
| **B7 iPhone 首发** | ✅ `TARGETED_DEVICE_FAMILY = 1` |
| **B7 APIClient** | ✅ timeout / 重试 / 取消 / NWPathMonitor |
| **B7 社交诚实** | ✅ 点赞不补 SampleData；榜「示例」；角标去抽签 |
| **B1-3 迁移骨架** | ✅ 已有 `AppSwiftDataSchemaV1` + `MigrationPlan` |
| **B1-6 Model chained** | ✅ Feature Model + Gateway chained；写失败横幅 |
| **B1-5 全域写失败** | ✅ Community / Messages / Wallet / Orders / Refund / TrustLedger → `PersistenceWriteFailureReporter` |
| **旅程种子诚实** | ✅ Release 种子无静默用户态；repair 不并回 seed `joinedIDs`；离线发送 `.failed` |
| **原生规范 / a11y** | ✅ SIWA 官方按钮；glass/material 降透明度；头图 `Button`；Launch token |
| **媒体分层** | ✅ Feature 经 `LocalMediaLibrary`；`TrustBehaviorLedger` AppComposition 注入 |
| **调试签名** | ✅ Debug 无 SIWA entitlement（个人 Team）；Release 保留 SIWA |

**仍依赖后端（未做）**：真支付/退款、真 IM（WebSocket/APNs）、远程陪玩人设目录、Apple identityToken 服务端校验。

**客户端剩余人工项**：基线 git tag；托管隐私页公网可达；真机 / 编译抽检（见 [RemainingReleaseClientPlan](RemainingReleaseClientPlan.md) §12）。

**批次 3 注意**：开发者账号需开启「Sign in with Apple」并与 Bundle ID `app.zuobiaoxi.coordinate` 关联；个人 Team 仅 Debug（无 SIWA entitlement）。

**批次 4 注意**：无真实 PSP 前 Release 仅钱包付线下服务；充值入口不可用直至合规通道就绪。

**批次 5 注意**：Release 搭子发现为空直至供给 API；离线消息为「失败」可重试。

**客户端批次 1–7 诚实门控已收口**；提审前仍需后端真通道 + 真机走完 §11 + 托管页可达。

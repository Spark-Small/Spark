# 坐标系 · 上线准备度审计（Release Readiness Audit）

> 审计日期：**2026-09-27**（只读基线）  
> **落地对照：2026-09-29**（按当前代码推断；未宣称已跑全量 UI 回归）  
> 上线定位：**正式产品（真实后端、支付、Sign in with Apple）**  
> 基线：`main` @ `6ad408f`（审计时）；工程进度见 [ReleaseEngineeringPlan.md](ReleaseEngineeringPlan.md) §11–§13。  
> **读法**：**§0–§1 为当前结论**；§2–§6 保留审计原文发现（路径/行号以审计时为准），条目状态以 §0 为准。

---

## 0. 落地进度总表（2026-09-29）

### 0.1 P0（审计 §2）

| # | 主题 | 客户端状态 | 说明 |
|---|---|---|---|
| 1 | 容器 `fatalError` | ✅ | 内存降级 + `AppPersistenceHealth` / 恢复横幅 |
| 2 | 解码覆盖用户数据 | ✅ | 备份坏 payload、不写种子覆盖；Schema 迁移纪律已定 |
| 3 | 演示「剧本杀」静默注入 | ✅ | `#if DEBUG`；Release 种子无 `joinedIDs`；repair 不并回 seed 报名 |
| 4 | 会员绕过 IAP | ✅ | Release 仅 StoreKit；演示开通仅 DEBUG |
| 5 | 假充值 UI | ✅* | Release 充值「暂不可用」；真 PSP ⏳ |
| 6 | 假外部支付成功 | ✅* | `CommercePaymentPolicy`；Release 拒假到账；真通道 ⏳ |
| 7 | 假 Apple / 微信 / 固定验证码 | ✅* | 真 `SignInWithAppleButton`；微信仅 DEBUG；Release 远程短信；Apple token **服务端校验** ⏳ |
| 8 | 模拟接单 / SampleData 陪玩 | ✅ | Release 关模拟；发现空态直至供给 API |
| 9 | 聊天自动回复 | ✅* | Release 关闭；离线发送 `.failed`+重试；真 IM/APNs ⏳ |
| 10 | `PrivacyInfo.xcprivacy` | ✅ | 已入库；声明与 API 需提审前再核对 |

\* = 客户端诚实门控完成；完整商业/会话闭环仍依赖 §11 后端。

### 0.2 P1（审计 §3）· 客户端关键项

| 主题 | 状态 |
|---|---|
| 落盘吞错 / chained / 后台 flush | ✅ `PersistenceWriteFailureReporter` + `scenePhase` |
| 消息失败态 / 社区空错刷新 / 跳过反馈 | ✅ |
| Keychain + refresh / Bundle ID / ATS HTTPS | ✅ |
| 隐私政策 URL 接线 | ✅（**托管页须公网可达**） |
| reduceMotion / 降低透明度 / 异步图 | ✅ |
| CI workflow | ✅（destination 说明已补） |
| 基线 git tag | ⚠️ 需人工打 tag |
| 陪玩审核类目文案 | ⚠️ 产品确认 |

### 0.3 架构 / 原生 / 旅程（审计 §7–§9）

已按 Apple 分层与 HIG 收口：错误汇入 `AppPersistenceHealth`；Feature 媒体经 `LocalMediaLibrary`；`TrustBehaviorLedger` 组合根注入；登录/支付/无障碍见 §8；旅程断点见 §9。钱进 Repository、真 IM 仍延期。

---

## 1. 总体结论

**⚠️ 客户端诚实门控与数据安全已收口；提审仍阻塞在真实后端通道与托管页。**

相对 2026-09-27 审计：原 10 个 P0 的**客户端可修项均已落地或诚实关闭假路径**；剩余上线阻塞主要为：

1. **真支付 / 退款**（服务端订单与 PSP 回调）  
2. **真 IM + APNs**、远程陪玩供给目录  
3. **Apple identityToken 服务端校验**、隐私政策 **公网页可达**、人工基线 tag / 真机抽检  

| 规模（约，2026-09-29） | 数值 |
|---|---|
| App Swift 文件 | ~401 |
| CoordinateKit Swift 文件 | ~81 |
| 测试函数 | ~102（Domain + Networking + App；**无 UI 测试**） |
| 巨型文件拆分 | Split-A…J 已落地（见 GiantFileSplitPlan） |

工程批次进度：[ReleaseEngineeringPlan §13](ReleaseEngineeringPlan.md) · 剩余客户端 Wave：[RemainingReleaseClientPlan](RemainingReleaseClientPlan.md)。

---

## 2. P0 — 不修不能上线（审计原文 · 2026-09-27）

> 下表为审计时发现；**当前状态见 §0.1**。行号可能已漂移。

| # | 文件:行 | 问题 | 用户影响 | 修复方案（正式产品） |
|---|---|---|---|---|
| 1 | `坐标系/坐标系App.swift:22-26` | SwiftData 容器创建失败时 `fatalError` | 磁盘满或库损坏时每次启动闪退 | 失败时降级到内存容器 + 可恢复错误页；上报 |
| 2 | `坐标系/Services/Persistence/DomainSnapshotModelActor.swift:44-58`、`Packages/CoordinateKit/Sources/CoordinateData/LocalSnapshotFileStore.swift:16-22` | 快照解码失败时用种子数据覆盖写回 | 模型字段变更后，用户报名 / 消息 / 预约被清空且无提示 | 解码失败先备份原数据、不覆盖；补 `SchemaMigrationPlan` 迁移阶段；接入后端后以服务端为准重新拉取 |
| 3 | `坐标系/Services/AppModel/AppModel.swift:197` → `Services/PassKit/PassDemoBootstrap.swift:16-36`、`Features/Activities/ActivitiesModel+DemoJourney.swift:13-36`、`Features/Activities/ActivityPaymentFlow.swift:202-228` | 每次启动静默报名演示活动「剧本杀」，伪造 **Apple Pay 已支付** 订单并排提醒通知 | 用户取消后下次启动又被报上；出现从未支付的订单 | 从 Release 移除（`#if DEBUG` 或删除） |
| 4 | `Features/Profile/ProfileAccountCommercialViews.swift:222-230, 323-338` | Release 可见「本地演示开通（钱包扣款）」绕过 IAP | 违反审核指南 3.1.1 | 删除；会员只走 StoreKit（`SubscriptionStoreView` 已接好） |
| 5 | `Features/Profile/ProfileAccountCommercialViews.swift:609-661`（622 行页脚） | 充值展示 Apple Pay / 微信 / 支付宝，约 700ms 后直接加余额 | 违反 3.1.1、2.3.1 | 接入真实支付通道（见 §11 依赖）；数字商品不得用余额购买 |
| 6 | `Features/Activities/ActivityJoinConfirmSheet.swift:276-286`、`Services/WalletPayment.swift:197-225, 558-567` | 活动 / 陪玩「支付」为 `Task.sleep` + 本地记账，却显示 Apple Pay 等方式 | 用户以为已付款 | 线下服务类支付接 Apple Pay（PassKit `PKPaymentRequest`）或第三方支付 SDK，由服务端下单 / 回调确认 |
| 7 | `Features/Launch/Views/LoginView.swift:137-145`、`Services/LocalAuthSession.swift:137-155`、`坐标系/坐标系.entitlements`（为空） | 「使用 Apple 登录」「微信登录」是假的；验证码固定 `123456`（`LocalAuthSession.swift:39,106-114`） | 冒用 Apple 登录按钮（审核指南 4.8 / HIG） | 接入 `AuthenticationServices` + `SignInWithAppleButton`，开启 entitlement；微信接官方 SDK；短信走 `RemoteAuthAPI` |
| 8 | `Packages/CoordinateKit/Sources/CoordinateFeatureFlags/FeatureFlags.swift:68-78`（Release 返回 `true`）、`Features/Buddies/BuddiesModel+Bookings.swift:363-378`、`Features/Buddies/BuddiesModel+Browse.swift:96-99` | Release 中陪玩预约约 4 秒自动接单；陪玩列表来自 `SampleData` | 用户和虚构人设交易 | Release 关闭模拟接单；陪玩目录、接单、状态推进改由服务端下发 |
| 9 | `Features/Messages/MessagesModel.swift:314-340` | 对方回复由 `Task.sleep` 自动生成 | 伪造真人回复 | 删除自动回复；接入实时消息通道（WebSocket / IM SDK）+ APNs |
| 10 | 仓库中无 `PrivacyInfo.xcprivacy` | 使用 `UserDefaults`（需声明理由 API）约 160 处，并申请 ATT | App Store Connect 拒收上传 | 新建隐私清单，声明 `NSPrivacyAccessedAPICategoryUserDefaults`（`CA92.1`）及数据收集类型 |

---

## 3. P1 — 强烈建议上线前修（审计原文 · 2026-09-27）

> 下表为审计时发现；**当前状态见 §0.2**。

| 文件:行 | 问题 | 用户影响 | 修复方案 |
|---|---|---|---|
| `Features/Activities/ActivitiesModel.swift:226`、`Features/Buddies/BuddiesModel.swift:246`、`Features/Community/CommunityModel.swift:169` | 落盘 `try?` 吞错 | 显示成功，重启后丢失 | 上报 + 重试；关键操作失败给提示 |
| `Services/Persistence/SwiftDataSnapshotStore.swift:65-69` | 保存 fire-and-forget，未与 generation 串联 | 连续操作时旧写入覆盖新数据 | 改用 `MainActorPersistence.chained` |
| 全局（无 `scenePhase`） | 进入后台不落盘 | 杀 App 丢最后一次操作 | `.background` 时 flush |
| `Features/Messages/MessagesModel.swift:233-254` | 发送必定成功，无 `.failed` | 断网看不出未发出 | 失败态 + 重发 |
| `Features/Community/CommunityModel.swift:124`、`Features/Community/CommunityView.swift` | 加载失败 = 空列表；无 `.refreshable` | 误以为没人发帖 | 区分空 / 错误；加下拉刷新 |
| `Features/Activities/ActivitiesModel+ParticipationJourney.swift:77-88` | `skipActivityFeedback` / `skipActivityRecap` 零调用 | 点「跳过」后提示又出现 | 跳过按钮调用两者 |
| `Services/RefundFlow.swift:428-448` | 退款两段 `sleep` 后自动完成 | 退款看似真实 | 随支付一起改为服务端退款 + 状态回调 |
| `Services/API/AuthTokenStore.swift:17-36` | JWT 存 `UserDefaults`，`expiresIn` 未使用，无 refresh | 接入远程后有泄露与过期问题 | 存 Keychain；401 时 refresh 并重放请求 |
| `坐标系/Info.plist:11-16`、`Services/API/APIConfiguration.swift:24-25` | ATS 对 `123.56.118.242` 放开 HTTP；Base URL 硬编码 IP | 明文传输；审核追问 | HTTPS 域名；按 Debug / Release 配置分环境；删除 ATS 例外 |
| `Features/Launch/LocalAuthSheet.swift:11-87` | 隐私政策 / 用户协议仅 App 内文字 | App Store Connect 需要隐私政策 URL | 托管网页并在 App 内链接 |
| `坐标系.xcodeproj/project.pbxproj:406` | Bundle ID 为 `coordinate.---` | 占位值 | 改为正式反向域名 |
| 全局（`accessibilityReduceTransparency` 0 处） | glass 按钮 14 处、material 19 处不响应「降低透明度」 | 设置无效 | 在 `PlatformSurface` 统一降级为不透明底 |
| `ContentView.swift:65-67` 等 | 37 处动画仅 5 个文件判断 `reduceMotion` | 前庭敏感用户不适 | 动画入口统一判断 |
| `Design/PlatformMessagesChrome.swift:399` | `body` 中同步 `UIImage(contentsOfFile:)` | 聊天长列表卡顿 | 异步解码 + 缓存 |
| `.github/workflows/ios-test.yml` | 未提交；runner `macos-15` + iPhone 16 Pro，部署目标 26.5 | 按 runner 默认 Xcode 推断编不过，实际无 CI | 提交 workflow，换 Xcode 26 runner 与对应模拟器 |
| 仓库状态 | 323 个文件未提交 | 上线基线不可复现 | 分批提交并打基线 tag |
| 产品政策 | 付费「陪玩」+ 外貌标签（`Features/Buddies/BuddyPaidMarketViews.swift:298-303`） | 可能被判定为约会 / 陪侍类服务 | 产品层重新定位文案与类目；准备审核说明 |

---

## 4. P2 — 影响成熟度

- **巨型文件**：16 个超过 600 行；`BuddyPaidMarketViews.swift`（1059 行）混排行打分与 UI，`ConversationDetailView.swift`（799 行）偏大。
- **崩溃隐患**：`Features/Activities/ActivityPaymentFlow.swift:65` `static var walletStore: WalletStore!`（注入于 `Services/AppDomainServices.swift:27`，注入前访问即崩）；`Services/PassKit/PassPackageBuilder.swift:138` `DispatchQueue.main.sync` 有死锁风险。
- **伪造在线状态 / 社交数据**：`Features/Messages/MessagesModel+FriendRequests.swift:45,71` 强制在线；`Features/Community/CommunityPostActionSheets.swift:38-44` 用 `SampleData` 补点赞人；`BuddyPaidMarketViews.swift:248-329` 哈希生成排行分；`Features/Activities/ActivityDetailContent.swift:349` 占位天气。
- **图片选择失败无提示**：`Features/Messages/ConversationDetailView.swift:754`、`Features/Community/CommunityComposeSheet.swift:247-250`。
- **活动无文字搜索**：仅分类、快捷筛选、筛选面板。
- **交互**：`Design/PlatformMessagesChrome.swift:234`、`Features/Profile/ProfileComplianceOpsViews.swift:148` 可操作元素用 `onTapGesture`；`Features/Buddies/BuddyDetailSections.swift:236` 按钮 22×22pt。
- **退出登录不清理**：钱包与演示商业状态残留（`signOut` 与 `deleteLocalAccount` 行为不对称）。
- **网络层**：`Packages/CoordinateKit/Sources/CoordinateNetworking/APIClient.swift` 用 `URLSession.shared`，无 timeout、重试、取消策略、离线检测（`NWPathMonitor`）、分页。
- **iPad**：声明 `TARGETED_DEVICE_FAMILY = 1,2`，仅活动详情做了尺寸类适配。要么补适配，要么首发只上 iPhone。
- **硬编码布局**：Feature 目录 110 处数值，集中在 Launch、Profile。
- **内容过滤**：`ContentModeration.swift:8-15` 仅 5 个关键词；举报工单只做本地模拟推进。
- **消息无分页**：`MessagesModel+ConversationDetail.swift:12-24` 返回整段会话。
- **部署目标 26.5**：排除 26.0–26.4 用户。

## 5. P3 — 后续迭代

- 死代码：`Packages/CoordinateKit/Sources/CoordinateDomain/SnapshotFileActor.swift`。
- `print` 残留：`ProfileMembershipAdImpression.swift:54,69`。
- 单例：`TrustBehaviorLedger.shared` 等不利于测试。
- `Design/PlatformMetrics.swift:29,56` 的 `nonisolated(unsafe)` 缓存。
- 宽高比 token 同值异名（`activityCardAspectRatio` / `continueCardAspectRatio` 等）。
- 格式器写死 `zh_CN`、无 String Catalog（仅中国区可接受）。
- ~~文档漂移：`Docs/README.md` 写 `CoordinateDomainTests` 11 例~~（2026-09-27 已改为 Domain 50 / 合计 101）。

---

## 6. Feature 完整性

「真实闭环」= 在当前代码中真实生效、不依赖模拟。

| Feature | 真实闭环 | 核心缺陷 | 阻塞上线 |
|---|---|---|---|
| 活动（浏览→详情→报名→行程→结束→反馈，含主办方流程） | 16/18 | 支付模拟；无搜索；跳过不生效 | 支付部分阻塞 |
| 登录与账号 | 2.5/4 | Apple / 微信登录是假的；验证码固定 | 是 |
| 消息 | 2/6 | 自动回复、通话、转账模拟；无发送失败 | 是 |
| 社区 | 3.5/5 | 错误与空状态不分；无刷新；审核本地模拟 | 否（P1） |
| 陪玩 | 1/5 | 目录、接单、支付、退款均模拟 | 是 |
| 我的与设置 | 2/3 | 充值模拟；会员可绕过 IAP | 是 |

活动主流程逐步核对：浏览 ✅、搜索 ⚠️（无文字搜索）、详情 ✅、报名 ✅、支付 ❌（模拟）、成功反馈 ✅、状态同步 ✅、取消报名 ✅、状态恢复 ✅、候补 ✅、活动群 ✅、我的行程 ✅、活动结束 ✅、反馈 / 复盘 ⚠️（跳过不持久化）、发起 ✅、发布 ✅、管理 ✅、主办取消 ✅。

---

## 7. 架构评审

> 对照日期：**2026-09-29**（相对审计原文的架构改进）。

```text
View (Features)
  ↓
@Observable Model（AppModel + 各域 Model，@MainActor）
  ↓
UseCase（CoordinateDomain：报名 / 候补 / 预约状态机 / 浏览筛选）
  ↓
Repository：Remote* → SwiftData 快照（默认） → Local JSON（回退）
  ↘ 旁路（仍非 Repository，但写失败已汇入 AppPersistenceHealth）：
     WalletStore / RefundFlow / ActivityPaymentStore JSON、
     LocalMediaLibrary → CommunityPhotoStore、TrustBehaviorLedger（AppComposition 注入）
```

| 项 | 状态 | 做法（对齐 Apple） |
|---|---|---|
| 分层 / Domain / `@ModelActor` / strict concurrency | ✅ 保持 | 审计「不要动」：导航 helper、UseCase、四层 Repository **不删不扩** |
| 错误向上传递 | ✅ | 域 Model `persist` → `PersistenceWriteFailureReporter` +（有则）`flash`；钱 / 信任 / 媒体写失败同通道 → `AppPersistenceHealth` 横幅 |
| 网络韧性 | ✅ | `APIClient` timeout / 重试 / 取消 / `NWPathMonitor`；消息离线 `.failed` |
| 生命周期落盘 | ✅ | `scenePhase == .background` → `flushPersistenceForBackground` |
| 钱相关 Repository | ⏳ | 暂不新建第五套 Repository；真订单以服务端为准后再上 SwiftData commerce |
| View → 磁盘 | ✅* | Feature 写路径改经 `LocalMediaLibrary` / Model；Design 展示层可读文件 URL |
| 单例 | ✅* | `TrustBehaviorLedger` 由 `AppComposition` 注入 `TrustService`；进程级 monitor 仍可 `shared` |
| 过度设计约束 | ✅ | 不新增 Policy / Remote 空壳，直至真实后端域落地 |

\* 完整「钱进 Repository」与真 IM 媒体管线仍见 §11。

---

## 8. Apple 原生规范

> 对照日期：**2026-09-29**（相对审计原文已落地客户端改动）。

| 项目 | 结论 | 依据 |
|---|---|---|
| Tab | ✅ | 系统 `TabView` + `Tab`；每 Tab 独立 `NavigationStack(path:)` |
| Navigation | ✅ | 无自造返回按钮；目的地由 helper 统一注册 |
| Sheet / Alert | ✅ | `presentationDetents`；反馈走系统 alert，无自造 toast |
| List / Form | ✅ | 系统 List / Form；`ContentUnavailableView` |
| Button | ✅ | 头图相册等可点媒体改为 `Button`；地图选点 / 气泡点按仍用手势（交互语义） |
| Toolbar | ✅ | Photos 式 glass；降低透明度时退化为 bordered |
| Typography | ✅ | 语义字体为主 |
| Spacing | ✅ | Launch 登录页已迁 `PlatformMetrics`；Profile / 票面个别构图比仍可继续收口 |
| Safe Area | ✅ | 输入栏 `safeAreaInset`；聊天 `defaultScrollAnchor(.bottom)` |
| Accessibility | ✅ | `platformThin/UltraThin/BarMaterial*` + glass helper 响应降低透明度；`PlatformMotion` 响应减弱动态效果 |
| 登录按钮 | ✅ | 正式路径用系统 `SignInWithAppleButton`；未勾选协议时不自绘 Apple 品牌按钮 |
| 支付 | ✅* | Release 无假 Apple Pay / 假充值成功；真 PSP 与服务端对账仍待（见 §11） |

\* 支付「原生规范」项指**不再伪造系统支付 UI**；完整商业闭环见批次 4。

---

## 9. 用户旅程断点

> 对照日期：**2026-09-29**。下列「✅」为客户端已按 Apple / 审核诚实实践落地；「⏳」仍依赖后端真通道。

```text
新用户：信封引导(可跳过✅)
  → 登录✅（真 SignInWithAppleButton；微信仅 DEBUG；Release 短信走远程，无固定 123456）
  → 欢迎引导✅ → 首页浏览✅（.searchable）→ 详情✅
  → 报名✅*（Release 拒假外部支付；真 PSP ⏳）
  → 成功页+触感✅ → 我的行程✅
  → 我的✅（Release 种子无静默「剧本杀」报名；演示注入仅 DEBUG）

老用户：冷启动✅（容器失败→内存降级+横幅；解码失败备份不覆盖）
  → 自动恢复登录✅
  → 首页✅ → 参与✅
  → 社区✅（loadError + refreshable；Release 空 feed 不灌 SampleData）
  → 消息✅*（Release 无自动回复；离线发送→.failed + 重试；真 IM/APNs ⏳）
  → 设置 → 退出✅（清钱包等商业旁路）/ 注销本地账号✅
  → 杀 App 重启✅（scenePhase 后台 flush；repair 不再把 seed joined 并回用户态）
```

\* 付费 / 即时消息的**完整商业闭环**仍见 §11 后端依赖；客户端侧已消除「假成功 / 假在线」断点。

权限时机正确：定位在点「附近」时请求，通知在报名成功后请求，ATT 仅从设置进入；Info.plist 权限文案齐全。

---

## 10. 量化评分

分数 = 通过项 ÷ 总项，部分通过记 0.5。  
**2026-09-27 审计分**（历史）→ **2026-09-29 对照分**（按代码推断，客户端诚实门控后）。

| 维度 | 审计分 | 对照分 | 备注 |
|---|---|---|---|
| Feature Complete | 66% | **~78%** | 假支付/假 IM 改为诚实空态或门控；真通道未接仍扣分 |
| Production Readiness | 21% | **~55%** | P0 客户端项收口；后端/托管页未完成 |
| Architecture Health | 54% | **~72%** | 错误通道、flush、媒体门面、Ledger DI |
| UI Consistency | 79% | **~82%** | Launch token；巨型文件拆分 |
| Accessibility | 59% | **~85%** | reduceMotion / 降低透明度 / 44pt |
| Error Handling | 36% | **~70%** | 写失败横幅、离线发送失败、社区错误态 |
| Testing | 50% | **~52%** | 仍无 UI 测试；Domain 用例略增 |

未覆盖测试的关键模块（仍有效）：活动支付、钱包记账、登录会话、社区 Model、快照解码失败 / 迁移、内容过滤、UI 流程。

---

## 11. 正式产品所需的后端与外部依赖

以下 P0 不是纯客户端能改完的，需要服务端或第三方配合：

| 能力 | 客户端 | 服务端 / 外部 |
|---|---|---|
| Sign in with Apple | `SignInWithAppleButton`、entitlement、凭证状态监听（`getCredentialState`） | 校验 identity token、签发会话、撤销处理 |
| 短信 / 微信登录 | `RemoteAuthAPI` 已有骨架；微信 SDK | 短信网关、微信开放平台 |
| 会话 | Keychain 存储、401 refresh 重放 | refresh token 接口、过期策略 |
| 活动 / 陪玩支付 | Apple Pay 或支付 SDK；支付结果以服务端为准 | 下单、支付回调、对账 |
| 退款 | 状态展示与轮询 / 推送 | 退款接口与回调 |
| 会员 | 仅 StoreKit 2（已接） | App Store Server Notifications、收据校验 |
| 聊天 | WebSocket / IM SDK、发送失败态、分页 | 消息服务、离线推送（APNs） |
| 陪玩目录与接单 | 移除 `SampleData` 与模拟接单 | 供给端 App / 后台、状态机推进 |
| 内容审核 | 举报 / 拉黑 UI（已有） | 审核后台、关键词与图像审核服务 |
| 隐私政策 / 协议 | App 内链接 | 托管网页 |

---

## 12. 最该先解决的问题（2026-09-29）

1. **后端**：支付 / 退款订单与回调；IM + APNs；陪玩供给 API；Apple identity 校验（§11）。  
2. **托管**：隐私政策 / 用户协议公网页可达（`LegalDocumentURLs` 已接线）。  
3. **工程**：人工基线 tag；真机走完 [ReleaseEngineeringPlan §11](ReleaseEngineeringPlan.md) 门禁；提审前编译与抽检。  
4. **产品**：付费陪玩审核类目与文案说明。  
5. ~~演示注入 / fatalError / 假登录 / 无 xcprivacy~~ → **已客户端收口**（见 §0）。

---

## 13. 修复计划（待确认后执行）

### 分类

- **必须修**：全部 P0；P1 中持久化三项与发布配置（Bundle ID、ATS、隐私政策 URL）。
- **建议修**：其余 P1；P2 中崩溃隐患（`walletStore!`、`main.sync`）与图片失败提示。
- **不要动**：Tab / NavigationStack 结构与导航 helper；Domain UseCase 及测试；系统 alert 反馈方案；语义字体；PhotosPicker 写法；strict concurrency 配置；账号注销流程；权限请求时机；Repository 四层结构（接后端后会用上）。
- **架构问题**：解码失败覆盖数据、`try?` 吞错、钱相关状态不经 Repository、单例、网络韧性。
- **UI 问题**：降低透明度、减弱动态效果、`onTapGesture`、44pt 点击区域、同步解码图片、Launch / Profile 硬编码间距、iPad 适配。
- **产品体验问题**：模拟支付 / 登录 / 回复 / 接单；演示数据注入；伪造在线与点赞；无搜索；跳过不生效；退出登录不清理。

### 建议批次

| 批次 | 内容 | 是否依赖后端 |
|---|---|---|
| 1 | P0 #1、#2、#3（数据与崩溃）+ P1 持久化三项 | 否 |
| 2 | P0 #4、#10 + Bundle ID、ATS、隐私政策 URL、CI、提交基线 | 否（隐私政策需托管网页） |
| 3 | P0 #7 登录 + Keychain 会话 + refresh | 是 |
| 4 | P0 #5、#6 支付与退款 | 是 |
| 5 | P0 #8、#9 陪玩供给与实时聊天；消息失败态 / 分页 | 是 |
| 6 | 其余 P1（社区错误态、跳过、无障碍、图片解码） | 否 |
| 7 | P2 / P3 | 否 |

每批完成后：编译、检查编译错误与 Preview、回归相关 Feature、确认未引入新依赖问题、确认未破坏已有行为。

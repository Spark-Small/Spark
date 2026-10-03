# 06 · Apple 原生平台规范（Platform Spec）

---

## 1. 硬性平台选择

| 项 | 本仓规定 |
|----|----------|
| UI 框架 | SwiftUI First；UIKit 仅探针 / 系统能力缺口 |
| 导航 | `NavigationStack` + `navigationDestination`；Zoom 用官方 matched transition |
| 容器 | `TabView`、`Form`、`List`、`Sheet`、`confirmationDialog` |
| 图标 | SF Symbols；按钮必须有 accessibility label |
| 购买 | StoreKit / 系统按钮；禁止伪装 Apple Pay 成功 |
| 登录 | Sign in with Apple 可用时优先系统能力；视觉上避免伪造官方按钮合规形态 |
| 通行 | PassKit：`AddPassToWalletButton`；主 CTA 不抢「分享纪念票」 |

最低部署：iOS **26.5**（无书面要求不下调）。

---

## 2. HIG 对齐清单（开发自检）

- [ ] 主操作清晰，破坏性有确认  
- [ ] 适当使用 `.borderedProminent` / glass，不自造 CTA 体系  
- [ ] Sheet 尺寸语义正确（`.platformSheet(.form/.confirm/.browser)`）  
- [ ] 尊重 Safe Area；发现精选沉浸有意为之  
- [ ] Dynamic Type 下货架可切 stacked  
- [ ] Reduce Motion / Transparency 有退化路径  

---

## 3. App Store Review 相关（客户端可控）

| Guideline | 本仓做法 |
|-----------|----------|
| 2.3.1 准确 | Release 支付 / 供给诚实门控 |
| 3.1.1 支付 | 无假外部到账；真 PSP 未接前不宣称 |
| 5.1.1 隐私 | Privacy Manifest + 可外开政策 URL |
| 4.0 设计 | 系统控件优先；登录品牌底可接受，勿扩展成整 App 皮肤 |

---

## 4. 并发与 MainActor

- 所有 UI / UIKit 探针在 MainActor（见历史 DevelopmentGuide §7）。  
- 持久化写：`MainActorPersistence.chained`；失败上报 `AppPersistenceHealth`。  
- PhotosPicker / 媒体：经 `LocalMediaLibrary`，注意 Sendable。

---

## 5. Feature Flags（Release 默认）

| Flag | Release | 含义 |
|------|---------|------|
| `useRemoteAuth` | true | 远程登录 |
| `useRemoteCatalog` | false | 活动远程目录 |
| `useLocalCatalogBootstrap` | true | 本地种子合并 |
| `useRemoteBuddies` | true | 搭子 snapshot / 预约同步 |
| `useRemoteBuddiesWrite` | false | 邀约 / 俱乐部远程写（契约已备） |
| `useSampleBuddiesCatalog` | false | 陪玩样例 |
| 模拟外部支付 | false | `CommercePaymentPolicy` |

DEBUG：`enableReadPathRemoteIntegration()` 开读路径（含搭子）并关 bootstrap / Sample / 演示接单；`restoreLocalBuddiesSampleCatalog()` / 关搭子远程可恢复样例货架；`enableBuddiesRemoteIntegration()` 另开写 Flag。远程搭子开着但 `discoverCatalog` 空时，DEBUG 货架回落 Sample（Release 仍诚实空态）。

Flag 增删与尸旗清理见 [21_ENGINEERING_WORKFLOW](21_ENGINEERING_WORKFLOW.md) §4。

---

## 6. Apple 生态扩展（V1 非必须 · 接入纪律）

| 能力 | V1 | 接入前必须 |
|------|-----|------------|
| Universal Links / URL Scheme | 深链排队见 `11`；正式域名关联待定 | AASA、登录后消费、与 `17` 屏契约一致 |
| Widget / Live Activities | 未作为软启动范围 | 独立轻量数据面；禁止拉全量 Snapshot |
| App Intents / Shortcuts | 未作为软启动范围 | 只暴露已诚实可用的动作（勿暴露假支付） |
| Spotlight | 可选 | 索引字段最小化（`14`） |
| Push (APNs) | 正式闭环阻塞见 `16` | 权限非开屏连环要；与真 IM 同期 |

未就绪前：**文档可写契约，客户端勿做半套伪装入口**。

---

## 7. 性能与主线程

预算与禁止项见 [19_PERFORMANCE_SPEC](19_PERFORMANCE_SPEC.md)。  
并发：UI / 探针 MainActor；持久化链式写失败上报。

---

*下一篇：[07_ARCHITECTURE.md](07_ARCHITECTURE.md)*

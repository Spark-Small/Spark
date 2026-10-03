# 坐标系 · 活动模块（附录）

> **裁决**：现行规范与软启动真相以 [`Project/`](../Project/README.md) 为准（产品 `01`、流程 `02`、架构 `07`、数据 `08`、API `09`、状态 `10`、导航 `11`、上线 `16`、屏 `17`）。  
> **本文角色**：活动代码地图 / 文案落点的**深读附录**；与 Project 冲突时以 Project 为准。  
> **同步**：2026-09-30（按代码推断）  
> 相关短桩：[SoftLaunchConventions.md](SoftLaunchConventions.md) · [ReleaseBlockers.md](ReleaseBlockers.md)

---

## 1. 软启动数据真相（先读）

| 能力 | 现状 | 后端 |
|------|------|------|
| 浏览目录 | 本地快照；`useLocalCatalogBootstrap` 控制种子合并（已接线） | `GET activities/catalog` + **MergeRemote**（禁止整包覆盖）；Release `useRemoteCatalog == false` |
| 参加 / 候补 / 收藏 | Domain UC；`hostUserID` / `participantUserIDs` + 显示名双轨 | **写 API 契约已声明**（`APIEndpoint+ActivitiesWrite`），未开远程写 |
| 发起 / 编辑 / 取消 / 改期 | Domain `ActivitiesHostingUseCases`；Feature 只做副作用 | 同上 |
| 支付 / 退款 | `ActivityPaymentStore` 本地订单 + 设备 `WalletStore` | 外部通道未接；Release 仅钱包 |
| 表现态 | `ActivitiesPresentationStore`（Sheet / toast） | — |

**结论**：登录后可测发现 / 详情 / 本机报名 UX；远程写路径待后端；联调读路径用 `FeatureFlags.enableReadPathRemoteIntegration()`（关本地种子 + 开远程目录）。

---

## 2. 用户路径（参加者 / 发起人）

```
活动 Tab（须已登录 + 兴趣完成）
  ├─ 发现：货架 / Hero / 筛选 Menu / 下一场 Banner（欢迎后 + 7 天窗口）
  ├─ Zoom / Push → 详情 Form
  │     ├─ 参加 → IdentityAccessGate（核验）→ JoinConfirm →（付费则本机支付）→ Success
  │     ├─ 候补 / 转正 / 取消参加
  │     └─ 主办人 → HostManage / 内容编辑 / 群聊
  └─ 发起：Compose Draft → Publish Preview → 本地 publish
```

欢迎引导：半屏 Sheet，可跳过；**不替代**兴趣硬门（见 Auth 文档）。

---

## 3. 代码地图

```
Features/Activities/
  ActivitiesView.swift              Tab 根：货架编排
  ActivitiesModel.swift             目录 / 报名快照门面
  ActivitiesPresentationStore.swift Sheet / toast 表现态
  ActivitiesModel+Browse.swift
  ActivitiesModel+Participation.swift
  ActivitiesModel+ParticipationJourney.swift
  ActivitiesModel+Hosting.swift     → Domain Hosting UC
  ActivitiesModel+DemoJourney.swift   #if DEBUG

  ActivityBrowse*.swift             发现 chrome / shelf / feed / copy
  ActivityFilterMenu.swift          即时筛选（无独立 Filter Sheet）
  ActivityCards / CardStyle         发现卡 + ActivityCardStatus 文案表
  ActivityDetail*.swift             详情 Form、决策卡、内容块、Blueprint
  ActivityCompose*.swift            发起草稿 / 预览 / 文案
  ActivityJoin*.swift               确认 / 成功
  ActivityPaymentFlow.swift         订单 Sheet（无独立 PaymentSheet）
  ActivityHostManageView.swift
  …
```

Domain（`CoordinateDomain/Activities/`）：参加 UC + **Hosting UC**（Publish/Update/Cancel/Capacity/Reschedule）+ MergeRemoteCatalog / Repair。

写 API 契约：`Services/API/APIEndpoint+ActivitiesWrite.swift`（未默认开启远程写）。

Feature Model 只编排副作用与 `persist`；**不**内联主办业务规则。

---

## 4. 文案 Token（禁止旁路硬编码）

| 枚举 | 用途 |
|------|------|
| `ActivityCardStatus` | 发现 / 详情共用动作词：参加、已满、免费、打开活动群… |
| `ActivityDetailCopy` | 详情、支付披露、主办管理、评论、冲突 |
| `ActivityComposeCopy` | 发起 / 编辑 / 预览清单 |
| `ActivityBrowseCopy` | 空态、货架 meta；`Empty.action` → `ComposeCopy.createTitle` |
| `ActivityFilterCopy` | 筛选 Menu |
| `ActivityFeedbackCopy` / `ActivityExperienceFeedbackCopy` | 轻反馈 |

规则：

- 「免费」统一 `ActivityCardStatus.free`（Compose 的 `feeKindFree` / `feeResolvedFree` 为其别名）。
- `waitlistPromotionTitle` → `ActivityCardStatus.waitlistSpotOpen`。
- 新 CTA 先加 Token，再接线 UI。

---

## 5. Design / HIG 约定（活动域）

完整规范：[DESIGN_SYSTEM.md](../DESIGN_SYSTEM.md)。活动相关要点：

| 表面 | 做法 |
|------|------|
| 发现货架 | `DiscoverBrowse*` + `PlatformMetrics`；页边用 `discoverBrowseContentInset`，禁止双重 inset |
| 详情 / 主办 / 支付 Sheet | 系统 `Form` / `List`；默认不手写整页 padding |
| 全宽媒体 Form 行 | `platformFullBleedMediaFormRow()` |
| 相关活动横滑 | `platformFormRelatedRailRow()` |
| 主 CTA | `activityPrimaryCTA` / 系统 `borderedProminent`（按现行 chrome） |
| 反馈 | `platformFeedbackAlert` / confirmationDialog；**禁止自定义 Toast** |
| Zoom | 仅 `activityZoomNavigationDestination`；勿在二级再注册同类型 |
| Sheet 内自有栈 | `independentNavigationSheetChrome()` 清继承标记 |

刻意边距必须走 token：

- `PlatformMetrics.mediaChromeInset` / `avatarStackSpacing` / `successIllustration*`
- `PlatformSurface.tertiaryFill` / `accentSoftFill`
- 地图浮层列表：`platformOverlayMaterialFill()`

---

## 6. 支付与诚实披露

`CommercePaymentPolicy`：

| | DEBUG | Release |
|--|-------|---------|
| 外部支付模拟到账 | 允许 | **禁止** |
| 可选方式 | 全部 | **仅钱包** |
| 退款自动完结 | 本地 sleep 模拟 | 保持处理中，等服务端 |
| 文案 | 明确「演示扣款」 | 「设备本地账本」+ 外部通道未开放 |

订单 UI：`ActivityOrdersSheet`；参加确认内创建订单失败文案 → `ActivityDetailCopy.orderCreateFailed`。

---

## 7. 身份门禁（非登录）

参加 / 部分社交前：`AppModel.requireIdentityAccess()` → `IdentityAccessGate`：

1. 认证照齐全  
2. 摄像头人脸核验通过  

`FeatureFlags.requireIdentityVerification`：Release 恒 true。  
**这不验证 JWT**；未登录用户根本进不了活动 Tab。

---

## 8. 导航与 Sheet 清单

| 场景 | 机制 |
|------|------|
| 发现 → 详情 | `ActivityZoomNavigationLink` / Zoom route |
| 详情 → 主办管理 | Push `ActivityHostManageView` |
| 详情 → 相关俱乐部 | `CircleBrowseRoute`（勿与 Zoom 混用） |
| 参加确认 / 成功 / 支付订单 / 地图 / 反馈 / 举报 / 内容编辑 | Sheet + `.platformSheet(...)` |
| 活动群 | `prepareActivityGroupChatRoute` → 消息栈 |

目的地注册规则见 `.cursor/rules/navigation-destination.mdc`。

---

## 9. 改动规范

1. 先更新本文件 §1 真相表，再改「像已接后端」的文案或 Flag。
2. 不恢复已删：`ActivityFilterSheet`、`ActivityFavoritesView`、独立 `ActivityPaymentSheet`、活动 Tab 完整待办卡。
3. 报名身份将来接后端时：以 `LocalUserIdentity` / JWT subject 替换显示名键；同步改 Model 与 PRD。
4. 新分区标题走 `ActivityDetailCopy`（`feeSectionTitle` / `joinNoticesHeader` / `timelineEditorTitle`）；类别差异化 plan/prep 标题可留在 Blueprint。
5. 改完不主动 `xcodebuild`（见仓库规则）；公共 API / 导航 / 新文件结尾请人工编译。

---

## 10. 软启动测试矩阵

| # | 场景 | 期望 |
|---|------|------|
| B1 | 未登录 | 看不到活动 Tab |
| B2 | 登录 + 兴趣后进发现 | 有货架；数据可为 SampleData |
| B3 | 免费参加（已核验） | 本机 joined；成功 Sheet；群 / 行程 CTA |
| B4 | 付费参加 Release | 仅钱包；披露本地账本；无假外部到账 |
| B5 | 满员候补 → 放名额 | 转正 Banner / 确认路径 |
| B6 | 发起活动 | 预览诚实「待补充」；发布后本地可见 |
| B7 | 主办改期 / 取消 | 本地状态 + 文案；付费取消走退款申请态 |
| B8 | 开 `useRemoteCatalog`（DEBUG） | 远程目录合并；失败保留本地 |

后端联调前勿关闭本地种子冒充「空供给已上线」。

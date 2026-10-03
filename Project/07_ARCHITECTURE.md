# 07 · 技术架构（Architecture）

---

## 1. 分层

```
┌─────────────────────────────────────────┐
│ Features/*     View + @Observable Model │
├─────────────────────────────────────────┤
│ Services/*     AppModel、Auth、API、Store │
├─────────────────────────────────────────┤
│ Design/*       Platform chrome（无业务）  │
├─────────────────────────────────────────┤
│ CoordinateDomain   UseCase / 协议         │
│ CoordinateModels   Codable 实体 / Snapshot│
│ CoordinateData     Local Repository       │
│ CoordinateNetworking  APIClient / Endpoint│
│ CoordinateFeatureFlags                    │
└─────────────────────────────────────────┘
```

| 层 | 允许 | 禁止 |
|----|------|------|
| Features | Models、Domain UC、注入 Store | `CoordinateData`、直连 `AppComposition`、乱写 UserDefaults |
| Design | SwiftUI、平台语义 | 业务状态（白名单文件除外） |
| Domain | 纯逻辑、协议 | SwiftUI、具体网络 |
| Data | 本地 I/O | UI |

---

## 2. 组合根

- `AppComposition`：装配 Repository / 远程装饰器 / 共享 Store  
- `AppDependencies`：Features 注入门面  
- `ContentView`：会话门闸 + **延后**构造 `AppModel`（首帧不解码全量目录）

---

## 3. 活动写路径（现行最佳实践落点）

```
View
 → ActivitiesModel（门面） / presentation（UI 态）
 → Domain Hosting / Participation UseCases（inout 快照字段）
 → repository.replaceAsync(ActivitiesSnapshot)
```

远程目录：`RemoteActivitiesRepository.syncRemoteCatalogIfEnabled` → `MergeRemoteActivitiesCatalogUseCase`（禁止整包覆盖）。

远程写：契约在 `APIEndpoint+ActivitiesWrite`；**默认不启用**。

---

## 4. 认证架构

```
LoginView → LocalAuthSession
         → Auth*UseCase
         → RemoteAuthAPI / Demo
         → AuthSessionStore (Keychain) + AuthTokenStore (JWT)
```

401 → refresh；失败 → `AuthSessionEvents.remoteSessionInvalidated` → 登出。

---

## 5. 通知双轨

```
UNUserNotification（排程 / 权限 / 系统列表）
  → AppNotificationRouter（深链 + willPresent/didReceive）
  → InAppNotificationStore（站内收件箱、未读 Badge、去重）
  → NotificationsCenterView（「我的」铃铛）
```

偏好仍由 `NotificationPreferencesStore` + `SettingsNotificationsView` 管理；站内历史与系统投递同步，不伪装远程推送已达。  
广场远程读：`RemoteCommunityRepository` → `MergeRemoteCommunitySnapshotUseCase`（与活动目录 / 搭子快照同纪律）。

---

## 6. 持久化

- 主路径：SwiftData 快照 Gateway（可 Flag 回退 JSON）  
- Schema 变更必须 VersionedSchema + MigrationPlan  
- `scenePhase == .background` flush  
- 写失败：横幅，不 silent  

---

## 7. 文件与类型纪律

- 一文件一主类型；Feature 大屏拆子 View / `+Browse` / `+Sections` 扩展  
- Model 扩展按 concern：`+Browse` / `+Participation` / `+Hosting`；搭子另有 `+Bookings` / `+Organization` 等  
- **Features / Design 生产 Swift 硬上限 ≤ 400 行**（数据袋 / Sample / 纯 Copy 表除外）；超标必须先拆再加功能（见 `21` DoD、`.cursor/rules/official-sample-file-discipline`）  
- 气质对齐 Apple sample-food-truck：系统 `List`/`Form`/`searchable`/`ContentUnavailableView` + `platform*` chrome；禁止单文件堆多 Sheet/多 Copy/多职  
- 单屏职责表：[17](17_SCREEN_SPEC.md)；PR / Flag 纪律：[21](21_ENGINEERING_WORKFLOW.md)  
- 搭子表现态：`BuddiesPresentationStore`；预约流程 Sheet 拆为 Wait / Submitted / Success 等独立文件
- 搭子身份：`BuddyIdentityMatching` + `userID` / `inviteeUserID` / `companionUserID`；发现目录 DTO `BuddiesDiscoverCatalog`（B4 待后端）
- 搭子远程：始终 `RemoteBuddiesRepository`（Flag 只控 sync）；预约跟 `useRemoteBuddies`；邀约/俱乐部写跟 `useRemoteBuddiesWrite`（默认关）
- 搭子写意图契约：`BuddiesWriteCommand` / `BuddiesWritePathPolicy`（Domain 预留；当前 Sync 仍按 Flag 直连，未强制经此枚举）
- 搭子 UI chrome 文案：独立 `Buddy*Copy` / `CircleGroup*Copy` 文件，与货架/详情 View 分离

---

*下一篇：[08_DATA_MODEL.md](08_DATA_MODEL.md)*

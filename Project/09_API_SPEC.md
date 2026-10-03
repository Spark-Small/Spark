# 09 · 前后端 API 规格（API Spec）

> **客观现状**：客户端有完整 Endpoint 声明与部分已接读路径；活动写 / 真支付等后端未默认接通。  
> 本文件区分：**已接** / **契约已备** / **未做**。

---

## 1. 传输约定

- HTTPS（Release ATS）  
- `APIClient.shared`；JSON Codable  
- 认证：Bearer access token；401 尝试 refresh；refresh 失败 → 会话失效登出  
- 路径相对 API 根配置  
- 日期：优先 ISO-8601 / `Date` Codable 策略与后端书面对齐；时区以 UTC 存储、本地展示  
- 请求体：写操作 JSON；空体用既定 `EmptyJSONBody`（或等价）  

### 1.1 错误信封（目标契约）

后端应稳定返回可解码结构（字段名可与实现对齐，语义不可缺）：

| 字段 | 含义 |
|------|------|
| `code` | 稳定机器码（如 `activity_full`） |
| `message` | 可读说明（客户端可再映射 `*Copy`） |
| HTTP | 401 未授权；403 禁止；404 不存在；409 冲突；422 校验；429 限流；5xx 重试策略见下 |

客户端：**禁止**仅凭模糊字符串分支业务；Domain 失败枚举 ← HTTP/code 映射表（接通时补进本文件）。

### 1.2 重试 / 幂等 / 分页

| 项 | 约定 |
|----|------|
| 读 | 可有限次退避重试；失败保留本地 |
| 写（报名/发布） | 默认不盲目重试；需 `Idempotency-Key`（或业务幂等键）后再自动重试 |
| 分页 | catalog 现阶段可整包；上量后 `cursor` / `limit`；客户端禁止假设「一次即全集」除非 Flag 标明 |

---

## 2. 认证（已接客户端）

| Method | Path | 状态 |
|--------|------|------|
| POST | `auth/sms/send` | 已接 |
| POST | `auth/sms/login` | 已接 |
| POST | `auth/apple/login` | 已接（**服务端校验闭环仍欠**） |
| POST | `auth/wechat/login` | 已接契约；SDK 未配置则无入口 |
| POST | `auth/token/refresh` | 已接 |

DEBUG：`useRemoteAuth == false` 时演示码登录，**不 mint JWT**。

---

## 3. 快照读路径

| Path | Flag | 行为 |
|------|------|------|
| GET `activities/catalog` | `useRemoteCatalog` | 成功 → **Merge** 入本地；失败保留本地 |
| GET `profile` | `useRemoteProfile` | 装饰器同步 |
| GET `messages/snapshot` | `useRemoteMessages` | Release 倾向开 |
| GET `community/snapshot` | `useRemoteCommunity` | 成功 → **Merge**（`MergeRemoteCommunitySnapshotUseCase`：远程帖 upsert、本机独有帖与赞/藏/转并集保留）；失败保留本地；**禁止** `local.save(remote)` 整包覆盖 |
| GET `buddies/snapshot` | `useRemoteBuddies` | 成功 → **Merge**（`MergeRemoteBuddiesSnapshotUseCase`）；失败保留本地；可选字段 `discoverCatalog`（`BuddiesDiscoverCatalog`）为发现货架契约，客户端可映射；**未下发真人数据前 B4 仍未清** |

活动目录、搭子快照与广场快照：**禁止** `local.save(remote)` 整包覆盖（均经 Merge UC）。

### 广场写路径（契约未备 · 默认关）

| 能力 | 状态 |
|------|------|
| 发帖 / 赞 / 评 / 转 / 藏 / 举报 | **本机 Snapshot + Domain UC**；无默认远程写 Flag |
| POST `community/posts` 等 | **未接**；不得勾 `16` B；禁止 UI 假装「已全网可见」 |

接通前：本地乐观写 + `platformFeedback*`；远程若日后加 Flag，须经 Repository，禁止 View 直打 API。

搭子发现：Release 关 `useSampleBuddiesCatalog`；有 `discoverCatalog` 则映射展示，无则诚实空态（不得用 Sample 冒充）。DEBUG：远程目录空时可回落 Sample，或调 `restoreLocalBuddiesSampleCatalog()`。

---

## 3.1 搭子 API（读 / 预约 / 写契约）

### 已接（跟 `useRemoteBuddies`）

| Method | Path | 行为 |
|--------|------|------|
| GET | `buddies/snapshot` | Merge 入本地；含 invites / bookings / clubs / joined* / 可选 `discoverCatalog` |
| POST | `buddies/bookings` | 提交预约；本地先落盘，失败诚实 Toast，继续轮询 |
| GET | `buddies/bookings/{id}` | 陪玩接单/拒单对账（`ReconcileRemoteBookingRecordUseCase`） |

`discoverCatalog` schema（可选）：

```json
{
  "freeBuddies": [{ "id", "userID?", "nickname", "gender", "age", "city", "bio", "tags", "circleName", "topic", "isOnline", "availability", "lastActiveText", "lookingFor", "distanceKM", "scheduleSlots", "relatedActivityTitles" }],
  "paidCompanions": [{ "id", "userID?", "nickname", …, "serviceType", "specialty", "hourlyPrice", "pricingUnit", "orderCount", "isAvailable", "isVerified", "responseTime", … }]
}
```

### 契约已备 · 默认未开（`useRemoteBuddiesWrite`）

实现：`APIEndpoint+BuddiesWrite.swift` + `RemoteInviteSyncService` / `RemoteClubSyncService`

| Method | Path | 用途 |
|--------|------|------|
| POST | `buddies/invites` | 提交邀约 |
| POST | `buddies/clubs` | 创建俱乐部 |
| POST | `buddies/clubs/{id}/join` | 加入 |
| POST | `buddies/clubs/{id}/leave` | 退出 |

接通顺序：后端就绪 → DEBUG `FeatureFlags.enableBuddiesRemoteIntegration()` 或 `setUseRemoteBuddiesWrite(true)` → 本地仍先落盘，远程失败用 `BuddyFeedbackCopy.remote*Failed`，**禁止**伪装对方已收到。

### 未做（阻塞正式供给）

| 能力 | 对应 B |
|------|--------|
| 真人发现目录运营下发 | B4 |
| 邀约 / 私聊真达对方（IM/APNs） | B5 |
| 外部支付 | B1 |

演示接单：`simulateBookingCompanionAcceptance` 仅 DEBUG 且远程预约未开时可用；联调一键关。

---

## 4. 活动写（契约已备 · 默认未开）

实现文件：`Services/API/APIEndpoint+ActivitiesWrite.swift`

| Method | Path | 用途 |
|--------|------|------|
| POST | `activities` | 发布 |
| PUT | `activities/{id}` | 更新 |
| DELETE | `activities/{id}` | 取消 |
| POST | `activities/{id}/join` | 参加 |
| POST | `activities/{id}/leave` | 取消参加 |
| POST | `activities/{id}/reschedule` | 改期 |
| POST | `activities/{id}/capacity` | 名额 |

当前真相源：Domain UC + 本地 Snapshot。接通后端时：先远程再 reconcile，或乐观本地 + 对账；**不得**绕过 Domain 规则在 View 里直接打 API。

---

## 5. 其他

| 域 | 状态 |
|----|------|
| Buddies bookings | 已接 submit/detail（跟 `useRemoteBuddies`） |
| Buddies invites / clubs | 契约已备；`useRemoteBuddiesWrite` 默认关 |
| Community snapshot 读 | Merge；`useRemoteCommunity` |
| Community 写 | **本机 only**；远程写契约未备 |
| Media moderation / identity reverify | 有 Endpoint；代理/远程由 Flag |
| 真支付 PSP / IM | **未做**客户端正式通道 |

---

## 6. 联调开关

```
FeatureFlags.enableReadPathRemoteIntegration()
// 开 catalog/community/profile/buddies/auth；关 bootstrap、Sample 搭子、演示接单

FeatureFlags.enableBuddiesRemoteIntegration()
// 另开 useRemoteBuddiesWrite（邀约/俱乐部）；需后端写 API 已通
```

不自动开启活动远程写；不自动勾 `16` B4/B5/B1。

---

## 7. 接通写路径时的客户端顺序

1. Domain UC 规则保持唯一  
2. Repository / Writer 先打远程，成功再 reconcile 本地；或乐观本地 + 对账任务  
3. 更新本文件「已接」列与 `16` 阻塞项  
4. 补错误码 → UI 文案映射与 Domain 测试  

---

*下一篇：[10_STATE_SPEC.md](10_STATE_SPEC.md)*

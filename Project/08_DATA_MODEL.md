# 08 · 数据模型（Data Model）

> 权威定义在 `Packages/CoordinateKit/Sources/CoordinateModels`。本文件只列域关系与演进规则。

---

## 1. 快照域

| Snapshot | 主要内容 | 仓储 |
|----------|----------|------|
| `ActivitiesSnapshot` | activities、joined/favorite/waitlist IDs、participationProgress、feedbackTagCounts | `ActivitiesRepository` |
| `ProfileSnapshot` | `AppUser`（墙/认证照/意图/Prompt/`occupation`/`meetRadius`/`mbti`/`zodiac`（星座：有 `birthDate` 时推导优先）、**实名**：`isRealNameVerified`·`birthDate`·`realNameDocumentKind`（身份证/护照）·证件指纹脱敏·身份证正反面或护照资料页本机文件名；性别年龄由实名写入；遗留 `lookingFor`）、兴趣等；完成度见 `ProfileCompletion` | Profile repo；远程经 **`MergeRemoteProfileSnapshotUseCase`**；本机媒体与实名字段在远程为空时保留；`useRemoteProfile` Release 默认关 |
| 发现目录 DTO | `BuddiesDiscoverBuddyDTO` / `CompanionDTO` 可选 `galleryImageURLs`、`intents` | 映射入 `BuddyProfile.galleryRemoteURLs` / `intents`；缺省回落种子图 |
| `MessagesSnapshot` | 会话与消息；`friendRemarks` / `friendGroups` / `friendGroupCatalog`（自建分组） | Messages repo |
| `BuddiesSnapshot` | invite/booking、clubs、joined*、membershipPrefs、可选 `discoverCatalog` | Buddies repo；远程经 `MergeRemoteBuddiesSnapshotUseCase` |
| `CommunitySnapshot` | 帖子 | Community repo |
| Engagement / RecentBrowse | 互动；最近浏览（`RecentBrowseKind`：activity / buddy / companion / club；无广场；每类封顶） | `ProfileRecentBrowseStore` + SwiftData `RecentBrowseItem` |

加载修复：活动种子经 `RepairActivitiesSnapshotUseCase`（保留用户自建与 previous 报名态，不把 seed 报名并回）。

---

## 2. 核心实体：Activity

关键字段：`id`、`title`、`category`、`location`、`date`、`capacity`、`joined`、`hostName`、`fee`、`summary`、`tags`、坐标、封面。

**身份演进（现行）：**

| 字段 | 用途 |
|------|------|
| `hostName` / `participantNames` | 展示与旧数据兼容 |
| `hostUserID` / `participantUserIDs` | 稳定用户 id（`LocalUserIdentity`）；主办校验优先 id |

新发布必须写入 `hostUserID`。旧快照缺省时回退昵称比较。

---

## 2.1 搭子身份（现行）

| 字段 | 用途 |
|------|------|
| `BuddyProfile.nickname` / 邀约·预约昵称 | 展示与旧数据兼容 |
| `BuddyProfile.userID` | 稳定用户 id |
| `BuddyInviteRecord.inviteeUserID` | 被邀约人 id |
| `BuddyBookingRecord.companionUserID` | 陪玩 id |
| `BuddiesModel.currentUserID` | 本机用户（`LocalUserIdentity`） |

匹配规则：业务走 `ParticipantIdentity.matches`（底层 `BuddyIdentityMatching`）——两边都有 userID 时只比 ID；否则昵称大小写不敏感。Sample 人设用 `stableUserID(forNickname:)` 写入可复现 id。当前用户 id 读口：`ParticipantIdentity.currentUserID`。

`BuddiesSnapshot.discoverCatalog`（`BuddiesDiscoverCatalog`）为远程发现目录契约；服务端未下发时客户端保持诚实空态，**不得**用 Sample 冒充 Release 供给（B4 仍待后端真人数据）。

---

## 3. 会话与身份

| 概念 | 存储 |
|------|------|
| 登录会话 | Keychain `AuthSessionStore` |
| JWT | `AuthTokenStore` |
| 本机用户 UUID | `LocalUserIdentity`（远程登录可 `adopt`） |
| 协议同意版本 | `LegalConsentPreference` |
| 兴趣完成 | `AppUser` / AppModel 标志 |

---

## 4. 订单与钱包

- `ActivityOrder` + 本地 `ActivityPaymentStore`  
- 设备 `WalletStore`：本地账本投影；`useRemoteWallet` 时权威在服务端 `WalletAccountDTO` / ledger  
- Domain Money UC：`ChargeWalletUseCase` / `ApplyWalletCreditUseCase` / `CreateWalletTopUpIntentUseCase`  
- DTO：`WalletCommerceDTOs`（账户、流水页、充值意图、扣款、退款案）  
- Release：外部支付方式不可选（除非远程充值 Flag + 真通道）；退款保持处理中直至服务端  
- Release **无**开户赠送假充值；DEBUG 可有欢迎金演示  
- 优惠券 / 积分字段已移除（二期另立）  
- 会员：`MembershipStore` 本机投影（`storekit` / DEBUG `demo` 分键）；权威交易来自 StoreKit 2 Transaction；**无**会员服务端对账  

---

## 5. 模型变更纪律

1. Codable 新字段必须 `decodeIfPresent` + 默认值  
2. SwiftData schema **升版本 + migration stage**，禁止 silent reset  
3. 种子合并不得复活用户已取消的报名（Repair 规则）  
4. 远程合并用 Merge UC，保留 user-created  

---

## 6. Schema / 迁移登记（模板）

每次 SwiftData 或快照形变在本表追加一行（版本号以代码 `VersionedSchema` 为准）：

| Schema 版本 | 变更摘要 | Migration stage | 风险 |
|-------------|----------|-----------------|------|
| （现行） | Activities 含 `hostUserID` / `participantUserIDs` 等 | 按代码 | 旧包缺省回退昵称主办校验 |
| （现行） | Buddies 含 `inviteeUserID` / `companionUserID` / 可选 `discoverCatalog` | `decodeIfPresent` | 旧包缺省回退昵称匹配；catalog 缺省=未下发 |

**禁止**：为图省事 deleteStore / 清空用户报名态当「迁移」。

---

## 7. 本地 vs 远程冲突策略

| 场景 | 策略 |
|------|------|
| 远程 activities catalog 拉取成功 | `MergeRemoteActivitiesCatalogUseCase`：保留 user-created 与本机报名/收藏/候补集合 |
| 远程 buddies snapshot 拉取成功 | `MergeRemoteBuddiesSnapshotUseCase`：保留本地俱乐部 / 预约 / 邀约；joined* 并集；`discoverCatalog` 远程有则采信（含空目录）、缺字段保留本机缓存；禁止整包覆盖 |
| 远程拉取失败 | 保留本地；更新 sync 状态；不空窗恐吓 |
| `useLocalCatalogBootstrap` | 仅允许种子**合并**；不得无条件整包覆盖用户态 |
| 活动写 API 未开 | 本机 Snapshot 为真相；接通后「先远程再 reconcile」或「乐观本地 + 对账」，规则仍经 Domain |
| 同 id 字段冲突（接通后） | 服务端权威字段白名单（标题/时间/名额等）vs 客户端权威（本机草稿未提交）；白名单进 `09` 同期更新 |

身份：主办 / 参与判断优先 `hostUserID` / `participantUserIDs`，缺省回退展示名。搭子匹配优先 `userID` / `inviteeUserID` / `companionUserID`，缺省回退昵称。

---

## 8. 删除与注销

用户注销 / 登出拆模型时：行为账本、本机身份、会话按 `14` 清空约定执行；活动快照是否保留设备匿名态由产品口径决定并写进本表备注，禁止 silently 留 JWT。

---

*下一篇：[09_API_SPEC.md](09_API_SPEC.md)*

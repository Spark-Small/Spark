# 坐标系 · 广场模块完善方案（完整版）

> **裁决**：现行规范以 [`Project/`](../Project/README.md) 为准（`01` 产品 · `03` IA · `07` 架构 · `09` API · `11` 导航 · `16` 上线 · `17` 屏 · `21` DoD）。  
> **本文角色**：广场 **完整完善方案 + 代码地图附录**；与 Project 冲突时以 Project 为准。  
> **范围声明**：本方案**不收窄**——覆盖产品主职、信息架构、交互、Domain/Data、远程、通知衔接、工程拆分与验收；执行时仍按 `21` **一 PR 一意图**拆批落地，但目标集是整模块旗舰闭环，不是单点修补。  
> **参考源**（借鉴切片，禁止整包换皮 / 换后端）：  
> - Apple：[sample-food-truck](https://github.com/apple/sample-food-truck)、[Adding a search interface](https://developer.apple.com/documentation/SwiftUI/Adding-a-search-interface-to-your-app)、HIG Social / Notifications  
> - 开源：[threads_swiftui](https://github.com/sergio11/threads_swiftui)、[Threads-Clone](https://github.com/garretthanberg/Threads-Clone)、[InstagramClone](https://github.com/dmakarau/InstagramClone)、[text-social-app](https://github.com/Pranshu640/text-social-app)（Service 分层）  
> **同步**：互动通知只在「我的·铃铛」；**取消赞 / 取消转发撤销同键通知**，删帖清帖向通知；通知带 `communityPostID` 深链回帖。真机仍须勾 `15`。

---

## 0. 一句话目标

把「广场」做成 **活动种草 / 复盘分享的浏览主场**：顶栏与五 Tab 同套、Feed 行与详情可转化到活动、关注与内容库诚实闭环、站内动态与系统通知双轨对齐；远程读经 Merge、写默认关；**不**做成 Threads/Instagram 换皮，**不**替代活动发现货架。

---

## 1. 产品主职与边界（不可退让）

| 维 | 必须 | 禁止 |
|----|------|------|
| 主职 | 浏览分享（种草 / 路线 / 复盘）→ 弱转化活动 | 发现货架几何；履约 checklist；假支付 |
| Tab | 五 Tab 之一；顶栏 `platformTabRoot*` | 爱心/动态独立 Tab 抢「我的·通知」 |
| 内容库 | 收藏 / 赞过 / 我的分享 / 转发 / 公约 →「我的」 | 广场顶栏「更多」菜单回潮 |
| 搜索 | 系统 `searchable` + **bottomBar** `DefaultToolbarItem.search` + `.minimize` + 轻量 `searchSuggestions`；**不**自管 `isPresented`；**不**把 minimize 搜索放顶栏 trailing | 顶栏 trailing + minimize（关闭死循环）；自定义放大镜；dismiss 清 text |
| 动态 | 推荐置顶 / 发现作者；**互动通知仅「我的」铃铛** | 广场内嵌第二套收件箱 /「新通知」预览轨 |
| 视觉 | `Platform*` / AccentColor；分类 chip = List 首段随滚 glass；顶栏与五 Tab 同套 soft edge | 黑白 Threads 皮肤；手写 `.shadow`；灰底 bordered；sticky chip 第二顶栏 |
| 数据 | 本地 Snapshot + 可选远程 Merge | `local.save(remote)` 整包覆盖；Release 假远程已达 |

跨模块：

```
广场 ──弱转化──► 活动 Zoom / 详情
     ──关注/作者──► 搭子 Zoom 或 Author Sheet
     ──私信──────► 消息（经 AppModel）
     ──库/通知──► 我的（内容库 / 通知中心）
```

---

## 2. 落地对照（相对方案基线）

| 域 | 基线缺口 | 现状 |
|----|----------|------|
| `17` 子屏 | 无表 | 已有 §5.2 |
| Feed 骨架 | 推荐另起炉灶 | `.feed` / `.teaser` 同卡 |
| 互动通知 | 未写回 | 赞/评/回复/转发 → `InAppNotificationStore` + dedupe |
| PresentationStore | 无 | 已有 |
| Domain UC | 无 | Engagement / Moderation / Merge / BrowseFiltering |
| 远程 | 整包风险 | Merge only；写契约未备（见 `09`） |
| 关注 | 空态弱 | 空态 CTA + 会话内「已关注」保留 |
| 搜索 | 无历史 | 按钮搜索 + ≤5 历史（onSubmit 写入）；**不**在 dismiss 清 text |
| 楼中楼 | 独立 PR | 已接（二级扁平 + 展开态共享） |
| a11y / 性能 | 未系统做 | Copy/Label、chip 横滑、Feed `.equatable()`；真机待勾 |
| 测试 | 缺 | Domain 测例 + `15` C1–C14 |

---

## 3. 目标信息架构

```
广场 Tab
├─ 顶栏：发分享 ·（静音铃仅 denied）；底栏系统搜索按钮（minimize）；与五 Tab 同套 soft edge
├─ 筛选：List 首 Section glass 分类 chip（随内容滚动；对齐通知中心）
├─ 推荐置顶 1 条（无 Section 小字；长按 Suggest Less；未「少看」时）
├─ 主 Feed（筛选 + 搜索交集；「发现作者」= 未关注作者内容，帖卡关注；**无**独立推荐关注人轨）
│
│   └─ PostCard（系统 glass 关注；作者副文发布时间 conversationListTime；媒体双击点赞→互动栏 bounce；正文进详情；无关联活动条）
├─ 下拉刷新（本地 ± 远程 Merge）
└─ 底栏：通知权限关闭提示（可关；互动收件在「我的·铃铛」）

二级
├─ Post Detail（评论、楼中楼、大图、关联活动、举报）
├─ Author Profile（关注、私信、搭子主页）
├─ Compose Sheet（.platformSheet(.form)）
└─（库页在「我的」栈）
```

筛选语义（已定，须保持互斥）：

| 档 | UI | 含义 |
|----|-----|------|
| 全部 | 全部 | 可见帖时间序（置顶优先） |
| 关注 | 关注 | 已关注作者 |
| 发现作者 | 发现作者 | **未**关注作者的发现向供给（与「关注」互斥） |
| 对话 | **热议** | 有评论的帖（非私信） |
| 提及 | **与我相关** | 关联我参加/主办的活动，或正文提到我 |

Chip 顺序：全部 → 关注 → 发现作者 → 热议 → 与我相关。每档有 VoiceOver hint 与诚实空态 CTA。

---

## 4. 目标分层（对齐 `07` / 活动 · 搭子）

```
CommunityView / FeedStack          编排（+Feed / +Dynamics / +Toolbar）
CommunityModel                     快照门面（读 + 委托写）
CommunityPresentationStore         Sheet / toast / pendingCompose*
CommunityModel+Browse/+Engagement/+Compose/+Moderation
        ↓
Domain
  CommunityEngagementUseCases
  CommunityEngagementNotificationKeys
  CommunityModerationUseCases
  CommunityBrowseFiltering
  MergeRemoteCommunitySnapshotUseCase
        ↓
CommunityRepository                Local / Remote 装饰（读 Merge）
```

**Features 禁止**：`import CoordinateData`、直连 `AppComposition`、View 内写 Snapshot。

---

## 5. 完善工作包（完整集 · 勾选状态）

> 下列为**完整目标集**。代码侧勾选 ≠ 真机验收完成。

### P0 · 契约与诚实 — ✅ 客户端

### P1 · 表现态与 Copy — ✅

### P2 · Feed 旗舰 IA — ✅（真机手感待勾）

### P3 · 互动与站内通知 — ✅

### P4 · 关注与发现 — ✅（互关披露：无反向关注图，未做假「互相关注」）

### P5 · 搜索 — ✅

### P6 · Compose — ✅

### P7 · 详情与评论 / 楼中楼 — ✅

### P8 · 远程读 / 写分档 — ✅ 读 Merge；写未接不得勾 B

### P9 · 动态区治理 — ✅（无广场通知预览；推荐 Suggest Less；无推荐关注人轨）

### P10 · 工程洁癖与测试 — ✅（`check-imports`：Circle 导航白名单；CredentialArt strip 去 Models）

### P11 · 无障碍与性能 — ✅ 代码侧；⏳ 真机 VO / Dynamic Type / 滑动

---

## 6–7. 借鉴对照 / 通知合同

（同前版；单一 Store：`InAppNotificationStore`。）

---

## 8. 验收标准

| # | 标准 | 客户端代码 | 真机/授权 |
|---|------|------------|-----------|
| 1 | `17` 一致；无更多/常驻搜索 | ✅ | ⏳ |
| 2 | 五筛选互斥 + 空态 | ✅ 可测 | ⏳ |
| 3 | 主卡/推荐同骨架 | ✅ | ⏳ |
| 4 | 赞评转通知同源 | ✅ | ⏳ |
| 5 | Compose + platformFeedback | ✅ | ⏳ |
| 6 | 远程读 Merge | ✅ | ⏳ Flag |
| 7 | check-imports / 无假远程 | ✅ | — |
| 8 | `15` 手工清单 | ✅ 已列 | ⏳ 勾选 |

未完成真机勾选前：**不得**对外宣称「广场已旗舰上线」。

---

## 9. 批次回顾

A–F + P7 楼中楼 + P11 代码收口已执行完毕。

---

## 10. 代码地图

```
Features/Community/
  CommunityLayout.swift（间距契约）
  CommunityCrossModuleLinks.swift（作者/搭子 → 活动·帖详情）
  CommunityView.swift / +Feed / +Dynamics / +Toolbar / +Search
  Community*Copy.swift
  CommunityPostCard / Detail / Compose / Routes / CommentRow / RelatedActivityLink
  CommunityActionSheet + Comments / Share / RepostDetail / Bookmark
  CommunityModel*.swift
Activities/
  ActivitiesBrowseRoute.communityFeed → CommunityFeedStack(embedded, 无嵌套栈)
Buddies/
  CircleBuddyDetail / PaidCompanionDetail → CommunityAuthorRecentPostsSection
Design/
  PlatformConversationListChrome / PlatformReviewsCommentsHost
Domain/
  Merge / Engagement / Moderation / BrowseFiltering / NotificationKeys
```

---

## 11. 风险与非目标

同前。**非目标**：独立动态 Tab、Stories/Reels、地图广场、付费帖、活动发现迁入广场、无反向图时的假「互相关注」。

---

*维护：代码变更同步本同步条与 `Project/15`·`17`·`09`；冲突以 `Project/` 为准。*

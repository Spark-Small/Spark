# 11 · 导航规格（Navigation / Sheet / Deep Link）

> 与 `.cursor/rules/navigation-destination.mdc` 一致；SwiftUI 同栈同类型重复 `navigationDestination` 只认最靠近根的一份。

---

## 1. Tab 根栈

每个 Tab：

```swift
@State private var navigation = TabNavigationState()
NavigationStack(path: $navigation.path) { … }
  .tabNavigationState(navigation)
```

成员 Push 用 `CircleMemberNavigationLink`，避免 LazyVGrid 多层 `NavigationLink`。

---

## 2. 目的地注册（唯一入口）

| 场景 | Helper | 路由类型 |
|------|--------|----------|
| 活动 Zoom | `activityZoomNavigationDestination` | 活动 Zoom 路由 |
| 搭子 Zoom | `buddyZoomNavigationDestination` | `BuddyZoomRoute` |
| 圈子浏览 | `circleBrowseNavigationDestination` / `circleBrowseStackChrome` | `CircleBrowseRoute` |
| Sheet 内成员 | `circleMemberSheetNavigationDestination` | 成员 |

Environment 标记：`hasCircleBrowseDestination` 等向下传递；**已注册则跳过**。

## 2.1 Tab 根顶栏（五 Tab 统一）

契约实现：`Design/PlatformTabRootChrome.swift`。

| 元素 | API / Helper |
|------|----------------|
| 标题 | `navigationTitle` + `.toolbarTitleDisplayMode(.inlineLarge)` |
| 顶边 | `.scrollEdgeEffectStyle(.soft, for: .top)` |
| 栏材质 | `.toolbarBackground(.automatic)` + `.toolbarBackgroundVisibility(.automatic)` |
| Trailing | `platformTabRootToolbar`；`ToolbarItemGroup` + `ToolbarSpacer` 分组；图标 `.platformNavigationBarItemChrome()` |
| Badge | 筛选生效数、通讯录请求、通知未读、Tab（消息未读 / 搭子待办预约） |
| 标题菜单 | 仅活动分类：`platformTabRootTitleMenu`（`toolbarTitleMenu`）；搭子模式改 Trailing Menu |

说明：`.inlineLarge` 下滚动后标题多为 **leading**（系统行为）；带 `toolbarTitleMenu` 的活动 Tab 尤其如此。勿手绘第二套 NavigationBar。

| Tab | Trailing 分组（现行） | 备注 |
|-----|----------------------|------|
| 活动 | 分类菜单在标题；筛选等见活动规范 | — |
| 搭子 | 筛选 → 模式 Menu（找搭子 / 约陪玩 / 俱乐部 / 最近浏览） | 无系统搜索框；创建在「我的 · 我的俱乐部」；Tab Badge = 待确认/待支付 |
| 广场 | 发帖 | 收藏/赞过/我的分享/转发/公约 →「我的」；顶栏搜索 / `searchable` |
| 消息 | 筛选 → 发起聊天 → 通讯录（`ToolbarSpacer` 分组） | Badge = 好友请求；筛选含陌生人信箱 |
| 我的 | 通知 · 设置 | Badge = 站内未读；`ProfileRoute.notifications` / `.settings` 同栈 push（含 tip「去设置」）；身份区获赞系统 alert / `socialGraph` 列表 |

| Tab | 菜单 | 行为 |
|-----|------|------|
| 活动 | 分类 | 切换目录；滚动回顶 |
| 搭子 | 找搭子 / 约陪玩 / 俱乐部 / 最近浏览 | Trailing 模式 Menu 写 `BuddiesModel.filter.kind`（或进最近浏览）；切换独立货架；滚动回顶 |

搭子 Trailing 顺序：筛选 → **模式 Menu**（无系统搜索框）；筛选条件按找搭子 / 约陪玩 / 俱乐部分流。`CircleComposeSheet` 由「我的 · 我的俱乐部」呈现（`ProfileRoute.myClubs`）。标题只显示当前表面，**不用** `toolbarTitleMenu`。  
「最近浏览 / 最近看过」为同级临时表面（非 push）：Trailing 文本「返回」退出，回到进入前的模式/分类（进入时不改写 `filter.kind` / `selectedCategory`）。

---

## 3. Sheet 陷阱（必查）

Sheet **继承**呈现方 Environment。若呈现方已标记「已注册」，Sheet 内栈会误跳过注册 → `NavigationLink(value:)` 无响应。

```swift
NavigationStack(path: $navigation.path) {
  content.circleMemberSheetNavigationDestination()
}
.tabNavigationState(navigation)
.independentNavigationSheetChrome()
```

半屏成员卡若栈内也注册目的地：`resetMemberSheetDestination: true`。

---

## 4. Sheet 语义

使用 `.platformSheet(.form / .confirm / .browser)`，勿随意硬编码 detent 却不统一。

| 场景 | 倾向 |
|------|------|
| 发起 / 编辑 / 设置 | `.form` |
| 参加确认 / 短确认 | `.confirm` |
| 成功 / 地图浏览感 | `.browser` 或既有约定 |

---

## 5. Zoom 与路由分流

- 活动卡 → 活动 Zoom，勿与圈子路由混用  
- 搭子墙卡 → `BuddyZoomRoute`，勿裸传 item  
- 圈子信息 / 成员 → `CircleBrowseRoute.circle` / `.member`  
- 广场帖 → `CommunityPost`（Tab 根或活动栈注册）；软启动合并时 **禁止** 再套一层 `NavigationStack`（`CommunityFeedStack(registersStackDestinations: false)`）  
- 广场 → 活动：详情 `CommunityRelatedActivityLink`（有 Zoom NS 则 Zoom，否则 push `ActivityDetailView`）  
- 广场 → 搭子：作者 `communityAuthorSheet`（有卡 → `BuddyDetailRouteView`，否则 `CommunityAuthorProfileView`）  
- 搭子 / 作者资料 → 广场：`CommunityAuthorRecentPostsSection`；→ 活动：`CommunityHostedActivityLinkRow` / `DetailRelatedActivitiesRail`  
- 活动 → 广场：软启动 `ActivitiesBrowseRoute.communityFeed`；分享 `CommunityComposeSheet` + `pendingRelated*`  

---

## 6. Deep Link / Pending

### 6.1 行为规则

- `AppModel` pending activity / map navigation 等在根消费  
- 打开活动：优先进活动 Tab 再 push/zoom  
- 打开广场帖：一律 `openCommunityPost`（合并 Tab → 活动栈 + `CommunityPendingPostNavigationModifier`；缺帖先 reload）  
- 活动行程赴约四件套含可选约陪玩：`openPaidCompanionBrowse()` → `BuddiesRoute.paidBrowse` → 搭子 Tab `showPaidPage()`  
- 登录门闸未过：深链**排队**，登录 + 兴趣完成后再消费  
- 协议待签 / 兴趣硬门：不丢 pending，也不绕过门闸  

### 6.2 URL 契约（目标表 · 实现时填齐）

| URL / 模式 | 意图 | 未登录 | 已登录 |
|------------|------|--------|--------|
| `https://<host>/activities/<id>`（Universal Link 目标） | 打开活动详情 | 排队 → 登录后详情 | 活动 Tab + zoom/push |
| 自定义 scheme（若保留）`coordinate://activities/<id>` | 同上 | 同上 | 同上 |
| `…/join` 类动作链 | 打开详情并意图参加 | 排队；核验仍走 Gate | 详情 + 触发参加意图（非静默报名） |

**纪律**：正式域名、AASA、Team ID 变更时同步本表与 `06` §6；禁止未登记的旁路 scheme 进生产。  
现状：客户端有 pending 消费能力；**公网 Universal Links 托管与路径最终形以联调时落地值为准**，落地后把「目标」改「已接」。

---

## 7. 工具栏与 Tab Bar

- Push 次级页：`.toolbarVisibility(.hidden, for: .tabBar)`（或项目既有 helper）；**Tab 根不**再强制 `.visible`（交系统随 pop 恢复）  
- 搭子 / 活动栈已注册 `PeerChatRoute` 时：私聊走 `NavigationPath`（`peerContactDestination` 认 `hasActivityPeerChatDestination` **或** `hasCirclePeerChatDestination`），勿并行 `navigationDestination(item:)` 推同一路由  
- 详情底栏 CTA：`safeAreaBar(.bottom)` / 项目 `activityDetailBottomBarChrome`  

---

## 8. 返回与打断

- 破坏性编辑离开：确认（系统 Dialog）  
- 核验 Gate 取消：回到详情，不假装已参加  
- 登出：拆栈与 `AppModel`，深链 pending 策略与会话绑定（失效则清或重登后无效化）

---

*下一篇：[12_COMPONENT_SPEC.md](12_COMPONENT_SPEC.md)*

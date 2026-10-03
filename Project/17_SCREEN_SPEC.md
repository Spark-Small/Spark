# 17 · 页面职责契约（Screen Spec）

> 补齐「模块边界」之下的**单屏契约**。`03` 定模块；本文件定每屏：主职、输入、输出、状态、导航、禁止。  
> 未列出的次要 Sheet 遵循同模块主屏纪律；新增主路径屏必须先入本表。

---

## 1. 契约模板（新增屏必填）

| 字段 | 说明 |
|------|------|
| 主职 | 该屏唯一主要目的（一句话） |
| 入口 | 谁 push / present |
| 输入 | 路由参数、注入 model、Environment |
| 输出 | 写哪些领域态 / 表现态 / 跨模块事件 |
| 四态 | Loading / Empty / Error / Content 怎么呈现（见 `10`） |
| 导航 | Push / Sheet / Zoom / Dialog；目的地是否已在栈根注册 |
| 禁止 | 不得承担的职责（防膨胀） |

---

## 2. 会话门闸面

| 屏 | 主职 | 输入 | 输出 | 禁止 |
|----|------|------|------|------|
| `LoginView` | 完成登录并建立会话 | 无 Tab；`LocalAuthSession` | 会话入 Keychain/JWT；进兴趣或 Tab | 报名、发现、访客旁路 |
| `LegalConsentGate` | 协议版本重签 | 已登录但协议过期 | 同意版本写入 | 替代登录 |
| `InterestOnboardingView` | 兴趣硬门槛 | 已登录、未完成兴趣 | `AppUser` 兴趣；放行 Tab | 可跳过、与欢迎混流 |
| 欢迎 Sheet | 意图说明（可跳过） | Tab 已就绪且未看过 | `WelcomeGuideStore` | 替代兴趣；挡参加 |

冷启动模型未就绪：启动屏占位（见 `02` / `10`），**不是**独立业务屏。

---

## 3. 活动主路径

| 屏 | 主职 | 关键输出 | 禁止 |
|----|------|----------|------|
| `ActivitiesView` | 发现货架 + 发起入口；标题菜单含「最近看过」（有足迹才出现，非分类） | 筛选态、打开 Compose/详情 | 履约 checklist、支付结账、Keychain；新用户顶栏强推「下一场」；**底栏行程附件**；「最近看过」做成 ActivityCategory |
| `ActivityDetailView` | 决策是否参加 + 读懂局；右上「更多」含分享 / **收藏活动**；**举报**下方分隔后为 **我的收藏**库 | CTA → 核验门闸（`activityJoin`）→ 确认；主办入口 | 堆履约待办；自造第二套导航目的地；发现主页挂收藏 |
| `ActivityComposeSheet` | 起草 / 编辑活动 | Draft → Domain Hosting UC | 直接打远程写 API；旁路文案硬编码主 CTA |
| Publish Preview | 发布前诚实预览 | 确认发布 | 伪装「已全网可见」若写路径仍本地 |
| Join Confirm | 冲突 / 须知 / 付费披露 | 参加 / 候补 / 结账意图 | 假外部支付成功 |
| Join / Publish Success | 单一主后续（行程或群） | dismiss + 深链/ Tab 跳转意图 | 多主 CTA 并列；交叉推销搭子 |
| `ActivityHostManageView` | 名额 / 改期 / 取消 / 完善说明 | Hosting UC + 确认 Dialog | 参与者侧报名逻辑 |
| Filter Menu | 即时筛选 | 浏览过滤条件 | 独立「设置页」式长表单（除非产品改口径） |
| Map Picker | 选点 | 坐标 / 地名回写 Draft | 整页自定义地图壳替代系统能力无必要处 |
| Feedback / Report | 反馈或举报 | 提交后 light feedback | 自定义 Toast |

详情内嵌块（决策卡、Hero、相关轨、评论）：**从属**详情屏契约，不单独占 Tab；破坏性仍走 Dialog。

---

## 4. 核验 / 支付 / 履约（打断或下游）

| 屏 | 主职 | 与活动关系 |
|----|------|------------|
| `IdentityAccessGate` / 认证照 | 报名或预约前核验；`IdentityGateSource` 区分文案 | 打断主 CTA；通过后回到原意图 |
| 支付 / 钱包结账面 | 按 `CommercePaymentPolicy` 收款 | Release 仅钱包 + 披露；不进发现首屏 |
| 我的行程 / 凭证 | 履约唯一主页 | 参加成功可去；**不**回流活动发现堆 checklist |
| 活动群（消息） | 履约沟通 | 由参加/发布编排打开 |

---

## 5. 其他 Tab 根（摘要契约）

| 屏 | 主职 | 禁止（相对活动） |
|----|------|------------------|
| 搭子根 | 找搭子 / 约陪玩 / 俱乐部；顶栏与五 Tab 同套 `platformTabRoot*`；三模式筛选分流（社交 / 服务·可约 / 主题·城市）；生效换顶栏图标为当前主条件，无角标 | 「我的预约」顶栏条；创建俱乐部入口；三模式共用同一套筛选条件；双 Hero 同滚；segmented principal；Release 塞 Sample 交易 |
| 广场根 | 分享浏览为主；顶栏与五 Tab 同套 soft edge；发分享 + 系统 `searchable`；筛选 chip 在 List 首 Section（随滚）；推荐置顶（非通知）；通知权限底栏提示 | 顶栏「更多」内容库；手绘黑白 Threads 皮肤；常驻搜索框；自定义放大镜并列；广场「新通知」预览轨；替代活动发现货架；sticky chip 第二顶栏 |
| 消息根 | 会话列表；筛选 Menu（全部/未读/群聊 + **陌生人信箱**）；文案拆 `MessagesCopy` / `+Friend` / `+Conversation` / `+AttachSocial`；Model 收发在 `+SendReceive` | 陌生人消息混进好友请求；假外部支付；宣称真 IM；Copy/Model 重复声明 |
| 好友请求 Sheet | 仅好友申请 + 等待验证；列表无行副标题；点进受限预览接受/删除 | 混入陌生人消息；行内按钮墙；假外部支付 |
| 陌生人信箱 Sheet | 仅陌生人聊天会话（`isMessageRequest` 且非好友申请来源）；点进打开会话线程；滑动移入收件箱/删除 | 与好友请求混页；用好友申请决策页冒充会话 |
| 会话详情「更多」 | 私聊：资料 / 置顶 / 免打扰 / 清空 / 删除；**群详情**对齐俱乐部信息骨架（成员网格·邀请·改名/二维码·公告·群管理·免打扰细项·本群昵称·清空/退群）；活动群可另开关联活动；退群·解散亦在「更多」保留 | 群详情仅扁平名单；堆通话转账；活动群 Menu 再堆置顶举报 |
| 会话点顶栏/头像资料 | 已好友 → `FriendProfileDetailView`（标题「好友资料」；顶区头像+名/身份副行+认证徽章按钮进信任档案+奖章格+社交三列+简介；备注行内编辑；分组可新建；底栏发消息/通话）；未好友 → 发现详情 | 无标题；顶区仅姓名；备注再弹 Sheet；好友仍进发现卡「加好友」 |
| 群聊打开活动详情 Sheet | `ActivityBrowserSheet`：左关闭、右更多（收藏在更多内）；已结束无行动用 `ContentUnavailableView` | 右上「完成」叠更多；自绘已结束通知条；发现主页挂收藏入口 |
| 我的根 | 身份（徽章点进认证）；**待办**（有下一场才显示）；**服务**（开通会员/会员中心·钱包·订单）；**我的内容**四行（活动与行程 / 陪玩预约 / 俱乐部 / 广场内容 → 二级 Hub）；顶栏通知+设置；**无**顶栏促销胶囊；**无**最近浏览（归活动/搭子标题菜单） | 根上最近浏览轨；根上摊广场五项；成为陪玩与钱包同级；顶栏会员促销条 |
| 通知中心 | `PlatformFilterChip` + `PlatformListTextColumn` / 未读点；Menu 全部已读/清空；深链；同步系统已投递 | 伪装远程推送已达；假转化 Toast |

子页（设置、钱包充值、成员 Sheet 等）遵循 `11` Sheet 栈规则与各 Feature 既有 Copy。

---

## 5.1 搭子子屏（现行）

| 屏 | 主职 | 输入 / 输出 | 禁止 |
|----|------|-------------|------|
| `BuddiesView` | 标题菜单：找搭子 / 约陪玩 / 俱乐部 + **最近浏览**（俱乐部下、有足迹才出现）；单模式货架；**各模式独立 L1 Menu + 深筛选**；空态诚实；人像卡封面多图系统 `TabView` 分页 | `BuddiesModel.filter.kind` + 浏览 + `presentation` Sheet | 同滚双 Hero；最近浏览做成 BuddyKind；三模式共用筛选；创建俱乐部顶栏；「我的预约」顶栏条；履约 checklist；Release 虚构花名册交易 |
| `BuddyDetail*` / Zoom | 读懂人 → 打招呼 / 邀约 / 预约；头图多图系统 `TabView` 分页；**无**点图/计数芯片全屏预览 | `BuddyZoomRoute` | 与 `CircleBrowseRoute` 混用 |
| `BuddyBookingSheet` + Flow Sheets | 下单 / 待确认 / 支付 / 成功 | Domain 预约 UC；`presentation.pending*` | 假外部支付成功；绕过 `IdentityAccessGate` |
| `BuddyInviteSheet` | 邀约参加活动 | invite records | 伪装对方已接受（Release） |
| 俱乐部详情 / 加入 / 邀请 | 组织资料与成员 | 会话成员优先；Sample 仅 Flag 开 | Release 绑 `SampleData` 成员 |
| 创建俱乐部 Compose | 用户自建俱乐部 | Hosting 本地 clubs | 伪装已全网可见供给 |

表现态统一在 `BuddiesPresentationStore`（toast / Sheet / pending*），不进 `BuddiesSnapshot`。  
发现列表：Sample Flag 开（或 DEBUG 远程目录空回落）→ 静默样例供给（界面无「演示」披露）；Release 否则映射 `discoverCatalog`（无则诚实空态 +「去逛活动 / 去我的创建」CTA）。身份匹配优先 `userID`。  
创建俱乐部 Compose 挂在「我的」俱乐部区（及我的俱乐部列表 trailing）；搭子空态仅深链切到「我的」并打开同一 Sheet。  
邀约：打开与发送均走 `requireIdentityAccess`；无活动时引导去活动 Tab。组织邀请：Sample 外用本机好友通讯录补候选。  
界面规范：主路径 UI chrome 文案进独立 `Buddy*Copy` / `CircleGroup*Copy` 文件（含 a11y、Alert、组织骨架）；色板用系统 `AccentColor` / `PlatformStatus`；创建俱乐部 Sheet 走 `.platformSheet(.form)`；详情底栏与预约提交补 `accessibilityHint`。界面不出现「演示 / 示例 / 模拟」字样；catalog/SKU 供给数据与 chrome Copy 分放。  
发现货架：顶栏与五 Tab 同套 `platformTabRoot*`（`.inlineLarge` + 模式 `toolbarTitleMenu`）；人模式单 Hero；首屏辅轨 ≤1（语音厅）；陪玩榜 Top3+查看全部；约陪玩卡 meta/角标突出**价格与可约**；空态文案主诉「找可约的人」；主动词「预约」；**无**系统 `.searchable`；筛选分流——找搭子（排序/性别/兴趣·距离）、约陪玩（排序/可约/服务类型/性别·距离）、俱乐部（排序/主题/城市）；俱乐部海报网格（创建仍归「我的」）；身份门闸打断页写清下一步。
大屏文件按 concern 拆分（`BuddiesView+Browse`、`BuddyOrgInfoScaffold+*`、预约 Sheet 分文件、`BuddyBrowseCopy` / `BuddyBookingFlowCopy` 等文案文件）；单文件目标见 `07`。

> 开发阶段无后端时：上述为客户端可闭环体验。**B4 真人目录 / B5 IM / B1 真支付仍未清**，不得在元数据中宣称已上线。

---

## 5.2 广场子屏（完善目标 · 详见 Docs/CommunityModule）

> 完整完善方案（不收窄）：[`Docs/CommunityModule.md`](../Docs/CommunityModule.md)。下表为屏级契约摘要。

| 屏 | 主职 | 输入 / 输出 | 禁止 |
|----|------|-------------|------|
| `CommunityView` / FeedStack | 浏览分享；筛选 + 系统搜索；推荐置顶 ≤1；发现作者=未关注作者内容筛选（帖卡关注，**无**独立推荐关注人轨）；Suggest Less | `CommunityModel` + Filter；写互动仍进 `InAppNotificationStore`（UI 只在我的） | 顶栏「更多」；常驻搜索抽屉；Threads 换皮；替代活动发现；广场「新通知」预览；独立多看少看问卷卡；广场做人货架「推荐关注」 |
| `CommunityPostCard` / Detail | 读懂分享 → 互动 → 弱转化活动；详情评论楼中楼（二级） | 赞评转藏；Zoom 关联活动；回复展开态 | 发现货架；履约 checklist |
| `CommunityComposeSheet` | 发种草 / 复盘 | Draft + 媒体 + 可选关联活动 | 假「已全网可见」 |
| Author Profile | 关注 / 私信 / 进搭子 | `toggleFollow`；消息深链 | 与 Zoom 路由混用 |
| 内容库（我的栈） | 收藏 / 赞过 / 我的分享 / 转发 / 公约 | `CommunityLibraryDestination` | 再挂回广场顶栏 |
| 通知中心（我的） | 全量站内收件箱 | 与广场预览同一 Store | 广场自建第二套历史 |

表现态：`CommunityPresentationStore`；远程读：`MergeRemoteCommunitySnapshotUseCase`（禁止整包覆盖）；写：本机 Snapshot，远程写契约未备（见 `09`）。

---

## 6. 页面膨胀检查（PR 自检）

新增或大改屏时勾选：

- [ ] 主职是否仍一句话？是否偷偷多了一职？
- [ ] 领域写是否只经 Model → Domain UC？
- [ ] Sheet / Zoom 是否复用栈根目的地（`11`）？
- [ ] 文案是否走 `*Copy` / `ActivityCardStatus`（`04` / `20`）？
- [ ] 空错态是否符合 `10`？
- [ ] 是否需更新本表一行？

---

*下一篇：[18_ANALYTICS_SPEC.md](18_ANALYTICS_SPEC.md)*

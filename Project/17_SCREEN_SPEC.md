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
| `InterestOnboardingView` | 兴趣硬门槛；内嵌 `InterestTaxonomyFormEditor`（`showsSelectionProgress: false`）+ 底栏文案/CTA | 已登录、未完成兴趣 | `AppUser` 兴趣；放行 Tab；草稿 `InterestSelectionDraftStore` | 可跳过、与欢迎混流；顶栏再叠计数 |
| `InterestTaxonomyFormEditor` | 多选喜好（编辑资料 push / 引导共用） | `Binding<Set<String>>`；分类目录 `ActivityTaxonomy` | 写选中集；自定义标签分区本机持久化 | 进度 Form 卡；等宽网格截断；假远程同步 |
| 欢迎 Sheet | 意图说明（可跳过） | Tab 已就绪且未看过 | `WelcomeGuideStore` | 替代兴趣；挡参加 |

冷启动模型未就绪：启动屏占位（见 `02` / `10`），**不是**独立业务屏。

---

## 3. 活动主路径

| 屏 | 主职 | 关键输出 | 禁止 |
|----|------|----------|------|
| `ActivitiesView` | 发现货架 + 发起入口；标题菜单含「最近看过」（有足迹才出现，非分类；竖列 `ActivityDiscoverCard`；Trailing「返回」退出回进入前分类）；深链 / `focusActivitiesDiscoverBrowse` 走 `landOnActivitiesDiscoverRoot`（退最近看过 + reset 栈 + 清成功 Sheet）；软启动空态仍可进内嵌广场；候补名额开放时发现卡主 CTA 为「候补名额已开放」（与 `quickJoin` 转正同源）；筛选空态文案提示顶栏菜单可调条件 | 筛选态、打开 Compose/详情 | 履约 checklist、支付结账、Keychain；候补转正只藏详情；深链卡在最近看过；跨 Tab「去发现」叠在详情上 |
| `ActivityDetailView` | 决策是否参加 + 读懂局；右上「更多」含分享 / **收藏活动**；**举报**下方分隔后为 **我的收藏**库；满员退出候补需确认；成员 Sheet 头为「名单 N 人」（与报名人数不一致时脚注说明） | CTA → 核验门闸（`activityJoin`）→ 确认；主办入口 | 堆履约待办；自造第二套导航目的地；发现主页挂收藏；退出候补一键无确认；成员头「共 N」与名单长度矛盾 |
| `ActivityComposeSheet` | 起草 / 编辑活动 | Draft → Domain Hosting UC | 直接打远程写 API；旁路文案硬编码主 CTA |
| Publish Preview | 发布前诚实预览 | 确认发布 | 伪装「已全网可见」若写路径仍本地 |
| Join Confirm | 冲突 / 须知 / 付费披露 | 参加 / 候补 / 结账意图 | 假外部支付成功 |
| Join / Publish Success | 参加：**主 CTA 行程**，次要日历/群；发布：**主 CTA 群**，次要日历 | dismiss + 深链/ Tab 跳转意图 | 多主 CTA 并列；交叉推销搭子；参加成功把群做成主按钮 |
| `ActivityHostManageView` | 名额 / 改期 / 取消 / 完善说明；付费场订单笔数可点开 `ActivityOrdersSheet` | Hosting UC + 确认 Dialog | 参与者侧报名逻辑；订单笔数不可点 |
| Filter Menu | 即时筛选 | 浏览过滤条件 | 独立「设置页」式长表单（除非产品改口径） |
| Map Picker | 选点 | 坐标 / 地名回写 Draft | 整页自定义地图壳替代系统能力无必要处 |
| Feedback / Report | 反馈或举报；`Form` + `platformFormTextInput(.report)`；收键盘走 `PlatformTextInputChrome` | 提交后 light feedback | 自定义 Toast；List 旁路输入皮；Messages 底栏写举报 |

详情内嵌块（决策卡、Hero、相关轨、评论）：**从属**详情屏契约，不单独占 Tab；破坏性仍走 Dialog。

---

## 4. 核验 / 支付 / 履约（打断或下游）

| 屏 | 主职 | 与活动关系 |
|----|------|------------|
| `IdentityCapability` / 认证照 | 报名或预约前核验（`Features/Identity`）；`IdentityGateSource` 区分文案；根 Sheet 呈现 | 业务手拼实名/认证照；绕过 `requireIdentityAccess` |
| 支付 / 钱包结账面 | 按 `CommercePaymentPolicy` 收款 | Release 仅钱包 + 披露；不进发现首屏 |
| 活动行程 / 凭证 | 履约唯一主页；下一步 **双列** 赴约四件套（约陪玩可选 / 群聊 / 导航 / 签到）；运动户外·城探·手工·娱乐有内容时扩展装备/注意事项；无障碍单列；结束后反馈复盘 | 强制约陪玩；扩展格空壳；双列挤无障碍字阶 |
| 活动群（消息） | 履约沟通 | 由参加/发布编排打开 |

---

## 5. 其他 Tab 根（摘要契约）

| 屏 | 主职 | 禁止（相对活动） |
|----|------|------------------|
| 搭子根 | 找搭子 / 约陪玩 / 俱乐部；顶栏与五 Tab 同套 `platformTabRoot*`；Trailing：筛选 → **模式 Menu**（创建俱乐部在「我的俱乐部」）；三模式筛选分流；生效换筛选图标为当前主条件，无角标；深筛 Sheet：**取消**关单、**重置**草稿、**完成**应用；**软启动定位不硬筛货架**（空态文案与 `matchesBrowseLocation` 同源；手动选城才按城过滤）；加入成功「查看资料」工会可进详情；接受活动邀约经 `onOpenActivityAfterInvite` 跨 Tab 打开；待确认/待支付凭证用「撤回预约」；Tab Badge = `pendingBookingAttentionCount` | 「我的预约」顶栏条；顶栏再挂创建；深链卡在最近浏览/叠栈；假「已邀请」；空态谎称 GPS 同城硬筛；取消位误触重置；工会查看 no-op；Badge 含已支付履约；标题菜单切模式；Release 塞 Sample 交易 |
| 广场根 | 分享浏览为主；顶栏与五 Tab 同套 soft edge；Trailing：发帖；筛选 chip 在 List 首 Section（随滚）；推荐置顶（非通知）；通知权限底栏提示 | 顶栏「更多」内容库；顶栏搜索 / `searchable`；手绘黑白 Threads 皮肤；广场「新通知」预览轨；替代活动发现货架；sticky chip 第二顶栏 |
| 消息根 | 会话列表；筛选 Menu（全部/未读/群聊 + **陌生人信箱**）；Trailing **通讯录**（无顶栏「发起聊天」）；深链只存会话 ID；搜索遵循当前筛选；筛选空态可看全部/去活动/找搭子；仅屏蔽可见空态单独文案；Tab 角标含陌生人未读（静音不计）；行内静音不显未读点；左滑删除走确认；`focusMessageID` 按会话分桶；文案拆 `MessagesCopy` / `+Friend` / `+Conversation` / `+AttachSocial`；底栏语音：录音→预览试听→发送（保键盘，本机 m4a） | 陌生人消息混进好友请求；「退出群聊」误取消报名；Sheet 发消息劫持 Tab path；孤儿 pendingCall；假积分拉新；假外部支付；宣称真 IM |
| 好友请求 Sheet | 仅好友申请 + 等待验证；列表无行副标题；点进受限预览接受/删除；空态可「通过 UID 添加」 | 混入陌生人消息；行内按钮墙；假外部支付 |
| 陌生人信箱 Sheet | 仅陌生人聊天会话（`isMessageRequest` 且非好友申请来源）；点进打开会话线程；滑动移入收件箱/删除 | 与好友请求混页；用好友申请决策页冒充会话 |
| 会话详情「更多」 | 私聊：资料 / 置顶 / 免打扰 / 清空 / 删除；**群（活动/俱乐部/同伴）**：群详情 + **置顶 / 免打扰**（与群详情 Toggle 同源 `isPinned`/`isMuted`）+ 清空 + 退出·解散；俱乐部可进圈子信息；活动群「退出群聊」**仅退群**（不取消报名）；圈子退群同步 `leaveCircle` | 群详情仅扁平名单；活动群「更多」缺免打扰；「退出群聊」误取消报名；圈子只删会话仍留会籍；堆通话转账 |
| 会话点顶栏/头像资料 | 已好友 → `FriendProfileDetailView`（标题「好友资料」；顶区头像+名/身份副行+认证徽章按钮进信任档案+奖章格+社交四列（获赞数/互关/关注/粉丝数）+简介；**本人**且有 `galleryLocalNames` 时展示照片墙；备注行内编辑；分组可新建；底栏发消息/通话）；未好友 → 发现详情 | 无标题；顶区仅姓名；备注再弹 Sheet；好友仍进发现卡「加好友」；Sample 灌假生活照 |
| 群聊打开活动详情 Sheet | `ActivityBrowserSheet`：左关闭、右更多（收藏在更多内）；`.independentNavigationSheetChrome` + peerChat / Zoom / circleBrowse；已结束无行动用 `ContentUnavailableView` | 右上「完成」叠更多；继承 Tab destination 致问发起人/俱乐部死链；自绘已结束通知条 |
| 我的根 | 身份（账户头副文：`@账号 · MBTI · 星座` 有则拼；下接社交四列；进个人资料）→ **照片**（Ins 三列 `ProfileLifePhotosGrid`）→ **服务** → **我的内容**；形象认证在个人资料；顶栏通知+设置；**无**根上订单/待办/促销/最近浏览 | 生活照片塞进个人资料 Form；副文堆长文案；根上订单/待办；MBTI 当官方测评 |
| `ProfileMembershipView` | **无后端**：StoreKit Configuration 闭环。未开通→`SubscriptionStoreView`；商品加载失败→诚实空态+恢复/重试；已开通→方案/到期/来源+管理订阅/恢复购买；DEBUG 演示权益不被 refresh 冲掉且可关闭；青少年拦截 | `MembershipStore`（storeKit∥demo） | 刷新清掉演示会员；Release 钱包开通冒充 IAP；假服务端对账；自绘第二套付费皮肤 |
| 通知中心 | `PlatformFilterChip` + `PlatformListTextColumn` / 未读点；Menu 全部已读/清空；深链（含待支付/待确认等到活动行程或陪玩凭证）；同步系统已投递；**活动邀约进度写入本收件箱**（不进「我的活动」） | 伪装远程推送已达；假转化 Toast；活动邀约挂「我的活动」；再挂平行「我的订单」催办入口 |
| `ProfileMyActivitiesView` | 「我的活动」：`ProfileLibraryCategoryMenu` **文字**分类；库合集含报名/候补/发起；「我报名的」含候补；横卡页边对齐发现竖列；空态 `ProfileLibraryEmptyView`；角标与 `ActivityCardStatus` 看齐；报名→行程 | `ActivitiesModel` + `ProfileLibraryChrome` | Menu 用 Label 被收成图标；候补从库里消失；自造待出发/已报名词表；角标写约陪玩；页内 segmented |
| `ProfileMyCompanionsView` | 「我的陪玩」：`ProfileLibraryCategoryMenu` **筛选图标**；**双列**人像小卡；空态共用 chrome；角标用 `BookingOrderStatus`；点进 `BookingCredentialExpandedView`（商务条 `+Commerce`；履约 `+Fulfillment`） | `BuddiesModel` + `ProfileLibraryChrome` | 活动跟进大横卡；文字分类按钮；再挂平行「我的订单」 |
| `ProfileMyPostsView` | 「我的发帖」：有内容 `List`；空态独立铺页 `ContentUnavailableView`（短说明 + 裸 Button actions）；搜索 `.search(text:)`；Trailing **草稿箱**与**发帖**分两组（`ToolbarItemGroup` + `ToolbarSpacer`）；**无**分类 Menu（广场库「转发」深链仍可按 Category 过滤） | `CommunityModel` + `ProfileMyPostsCopy` / `ProfileMyPostsDraftsView`；Compose 走 `CommunityComposeSheet` | UIKit 空态封装旁路；自挂 `.font` / `.borderedProminent`；页内 segmented；顶栏再挂分类 Menu；两枚图标糊同一组 |
| `ProfileMyClubsView` | 「我的俱乐部」：海报网格；Trailing **筛选 Menu** 与 **创建** 分两组（`ToolbarItemGroup` + `ToolbarSpacer`）；空态共用 chrome；点进 `CircleBrowseRoute` | `BuddiesModel` + `ProfileLibraryChrome` + `BuddyPosterShelfCard` | 纯文字 List；两枚图标糊同一组；创建入口仍挂搭子 Tab 顶栏；假「已全网可见」 |
| `ProfileWalletView`（`Features/Wallet`） | 「我的钱包」；入口仍可挂在「我的」Tab；首卡；余额卡头右上；Trailing 充值（通道未开则禁用）；**账户 Form**（默认支付/等级，**无**会员中心）→ **最近 3 条**（行首 kind 图标）+「查看全部」；无 footer 小字；无提现/开票行 | `WalletStore` + `WalletPaymentCardFace` | 首屏堆全量流水；钱包再挂会员入口；假 Visa；Release 假充值；实现回堆 Profile |
| `ProfileWalletLedgerAllView`（`Features/Wallet`） | 全部交易：按月分节 + `.searchable`；`.task`/下拉拉远程首页；空态按 Flag 诚实披露（远程：服务端暂无流水） | `WalletStore.refreshFromRemoteIfEnabled` | 扁平无限长 List 无分区；假「已全网同步」 |
| `WalletTopUpSheet` | DEBUG 本机演示充值；`useRemoteWallet` 走 topups 意图+轮询+账户/流水投影；否则暂不可用 | `RemoteWalletClient` + Domain TopUp / Merge Ledger UC | 未确认到账本地加款；Release 假 Apple Pay 成功 |
| 获赞说明 | 身份区点获赞 → 系统 `.alert`；标题「名」共获得 N 个赞；诚实说明仅统计分享获赞；「我知道了」 | `ProfileSocialCopy` | Sheet / 自绘居中卡；冒充未接入作品类型 |
| `ProfileSocialGraphView` | 互关 / 关注 / 粉丝：`List` + `.searchable`；行头像用可知边真图（搭子封面）否则字标；行进好友资料或作者页；关注/互关可滑取消关注；粉丝空态诚实（无反向图） | `ProfileSocialAvatarResolver` + `ProfileSocialStats.names` | 注 Sample 粉丝/关注/假脸；自造第二套通讯录表 |
| `EditProfileSheet` | 个人资料 Form：`flushTop` + 头区 inset；基本资料含身高体重数字+单位、身份/半径/MBTI `.navigationLink`、星座（有生日只读推导否则 Picker）、UID；**无**生活照片（在「我的」根墙）；**无** Section footer；业务二级页仅实名 OCR / 防欺诈 / 绑手机；MBTI 为自填标签不背书测评 | `BindPhoneSheet` + `RealNameVerificationSheet` + `EditProfileSheet+*` | 假「公安已核验」；手改性别年龄；再挂生活照片 Form；MBTI 冒充官方测评结果 |
| 好友/作者/搭子详情 | 本人字段一律投影 `AppUser`；私聊/好友「更多」可**请对方防欺诈认证**（须自己已认证；本机发文）；完成度环=好读懂六项 | **`PublicProfileProjection`** + `ProfilePhotoVerificationRequest` + `ProfileCompletion` | 业务绕过投影；假云同步；未认证自己却请求成功 |
| `TrustPrivateDashboardView` | 私域信誉 Form；**无**重复「防欺诈认证」入口（入口在个人资料）；仍展示认证与徽章状态行 | `TrustCredentialStatusRows` + badges | 信誉页再挂第二套防欺诈入口 |
| `PhotoVerificationView` | 防欺诈认证；认证照用 **Sheet**（`PhotoVerificationPhotosEditorView`）添加/管理，不 push 下级；摄像头采集；二次复核仅联网成功显示「服务端已确认」 | Sheet + `PhotoVerificationStore` + `IdentityRemoteReverifyService` | 演示代理冒充服务端已确认；认证采集静默开相册；再 push 二级上传页 |
| `ActivityCredentialExpandedView` | 「活动行程」：票面 + **支付与退款**商务条（Discover Section + `LabeledContent`，无 elevated 卡；待支付→结账；退款进度）+ 下一步四件套 | `ActivityJourneyCommerceModels` + `ActivityJourneyCommerceSection` + `ActivityOrdersSheet` | 行程页无支付/退款入口；商务条自造第二套卡壳；根上再挂「我的订单」 |
| `ProfileSettingsView` | 设置根：账号/隐私/帮助；法律入口**各一条**（托管 HTTPS 优先，失败回落 App 内离线长文）；根 tip / 设置内产品提示「去设置」均进 `SettingsPrivacyView`（根用 `ProfileRoute.privacy`） | `LegalHostedDocument` + `ProfileRoute.settings` / `.privacy` | 并列「离线」第二行；tip 回推设置根造成环 |

子页（设置、钱包充值、成员 Sheet 等）遵循 `11` Sheet 栈规则与各 Feature 既有 Copy。

---

## 5.1 搭子子屏（现行）

| 屏 | 主职 | 输入 / 输出 | 禁止 |
|----|------|-------------|------|
| `BuddiesView` | Trailing：筛选 → 模式 Menu（找搭子 / 约陪玩 / 俱乐部 / 最近浏览）；**无**顶栏创建俱乐部；俱乐部空态 CTA →「我的俱乐部」 | `BuddiesModel.filter.kind` + 浏览 | 顶栏再挂创建；同滚双 Hero；标题菜单切模式；三模式共用筛选 |
| `BuddyDetail*` / Zoom | 读懂人 → 打招呼 / 邀约 / 预约；头图多图；Form「推荐理由」纯文 →「兴趣爱好」纯非选中胶囊（`tags`）；约陪玩分段：资料 / 服务 / 评价 / 动态；口碑只读；**写评价仅完成订单凭证**；「我的」栈亦注册 `buddyZoomNavigationDestination`（邀约详情「搭子资料」） | `BuddyZoomRoute` | 与 `CircleBrowseRoute` 混用；假口碑；详情开放直写评价；邀约详情 Zoom 死链 |
| `BuddyBookingSheet` + Flow Sheets | 下单 / 待确认 / 支付 / 成功；选档与详情共用月历（仅「可约」日可选）+ 当日时段 | Domain 预约 UC；`presentation.pending*` | 假外部支付成功；绕过 `IdentityAccessGate`；任意 DatePicker 可选无档日 |
| `BuddyInviteSheet` | 邀约参加活动 | invite records | 伪装对方已接受（Release） |
| 俱乐部详情 / 加入 / 邀请 | 组织资料与成员 | 会话成员优先；Sample 仅 Flag 开 | Release 绑 `SampleData` 成员 |
| 创建俱乐部 Compose | 用户自建；Sheet 挂「我的 · 我的俱乐部」 | Hosting 本地 clubs | 伪装已全网可见；搭子顶栏再挂创建 |

表现态统一在 `BuddiesPresentationStore`（toast / Sheet / pending*），不进 `BuddiesSnapshot`。  
发现列表：Sample Flag 开（或 DEBUG 远程目录空回落）→ 静默样例供给（界面无「演示」披露）；Release 否则映射 `discoverCatalog`（无则诚实空态 +「去逛活动 / 去我的创建」CTA）。身份匹配优先 `userID`。  
创建俱乐部 Compose 挂在「我的 · 我的俱乐部」；搭子俱乐部空态 CTA 深链到该页。
邀约：打开与发送均走 `requireIdentityAccess`；无活动时引导去活动 Tab。组织邀请：Sample 外用本机好友通讯录补候选。  
界面规范：主路径 UI chrome 文案进独立 `Buddy*Copy` / `CircleGroup*Copy` 文件（含 a11y、Alert、组织骨架）；色板用系统 `AccentColor` / `PlatformStatus`；创建俱乐部 Sheet 走 `.platformSheet(.form)`；详情底栏与预约提交补 `accessibilityHint`。界面不出现「演示 / 示例 / 模拟」字样；catalog/SKU 供给数据与 chrome Copy 分放。  
发现货架：顶栏与五 Tab 同套 `platformTabRoot*`（`.inlineLarge`；模式切换在 Trailing Menu，**无**搭子 `toolbarTitleMenu`）；人模式单 Hero；首屏辅轨 ≤1（语音厅）；陪玩榜 Top3+查看全部；约陪玩卡 meta/角标突出**价格与可约**；空态文案按模式分流（同好 / 陪玩）；主动词「预约」；**无**系统 `.searchable`；筛选分流——找搭子（排序/性别/兴趣·距离）、约陪玩（排序/可约/服务类型/性别·距离）、俱乐部（排序/主题/城市；创建在「我的俱乐部」）；俱乐部海报网格；身份门闸打断页写清下一步。
大屏文件按 concern 拆分（`BuddiesView+Browse`、`BuddyOrgInfoScaffold+*`、预约 Sheet 分文件、`BuddyBrowseCopy` / `BuddyBookingFlowCopy` 等文案文件）；单文件目标见 `07`。

> 开发阶段无后端时：上述为客户端可闭环体验。**B4 真人目录 / B5 IM / B1 真支付仍未清**，不得在元数据中宣称已上线。

---

## 5.2 广场子屏（完善目标 · 详见 Docs/CommunityModule）

> 完整完善方案（不收窄）：[`Docs/CommunityModule.md`](../Docs/CommunityModule.md)。下表为屏级契约摘要。

| 屏 | 主职 | 输入 / 输出 | 禁止 |
|----|------|-------------|------|
| `CommunityView` / FeedStack | 浏览分享；筛选 chip；推荐置顶 ≤1（会话内锁定，关注只改按钮）；发现作者=未关注筛选 + **会话内关注保留帖**；**无**独立推荐关注人轨；Suggest Less；**无**顶栏搜索 | `CommunityModel` + Filter；写互动仍进 `InAppNotificationStore`（UI 只在我的） | 顶栏「更多」；关注后立刻撕卡；顶栏搜索；Threads 换皮；广场「新通知」预览；广场做人货架「推荐关注」 |
| `CommunityPostCard` / Detail | 读懂分享 → 互动 → 弱转化活动；详情评论楼中楼（二级）；底栏语音本机发送（预览试听后落盘） | 赞评转藏；Zoom 关联活动；回复展开态 | 发现货架；履约 checklist；藏「+」/mic；宣称语音已上云 |
| `CommunityComposeSheet` | 标题「发帖」；Trailing 仅「发布」；取消/有内容退出 → 系统确认「存入草稿箱 / 不保存 / 继续编辑」；`scenePhase` 进后台静默自动存草稿箱；发布后删对应草稿元数据 | Draft + 媒体 + 可选关联活动；`CommunityPostDraftStore` 本机多草稿 | 假「已全网可见」；草稿冒充已发布；顶栏再挂「存草稿」与草稿箱入口重复 |
| `ProfileMyPostsDraftsView` | 「草稿箱」：本机草稿 List；点开续写；滑动/编辑删除；空态引导发帖 | `CommunityPostDraftStore` + `CommunityModel+Drafts` | 假同步云端草稿；草稿进广场 feed |
| Author Profile | 关注 / 私信 / 进搭子 | `toggleFollow`；消息深链 | 与 Zoom 路由混用 |
| 内容库（我的栈） | 根上仅「我的发帖」；收藏的分享 / 赞过 / 转发 / 公约仍可由广场栈 `CommunityLibraryDestination` 打开；活动收藏由详情「更多」进 `ProfileFavoriteActivitiesLibraryView` | `ProfileRoute.myPosts` / `CommunityLibraryDestination` | 根上再挂广场五项 Hub；自造平行发帖列表 |
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

# 坐标系 · 行为信用模型

> 信任来自注册→注销全生命周期行为的**衰减移动统计**，不是对人的商品式多维星级评价。  
> 本文档供实现与后续迭代；代码入口：`Services/Trust/`、`Features/Trust/`。

## 1. 原则

1. **行为信用**：事件账本 + 移动平均 / 衰减，而非公开「友好度 / 专业度」打分墙。
2. **公私分离**：对外 = 徽章 + 可解释履约事实；对内 = 等级进度 + 行为摘要 + 提升路径。
3. **人对人不互评上墙**：履约后仅私密安全确认（是否顺利 / 是否举报）；付费「服务体验」若需要，挂服务侧，与用户信用分账。
4. **安全权重大于贡献**：举报成立、放鸽子、退款羊毛 > 发帖点赞。
5. **冷启动诚实**：事件不足时展示「新伙伴 / 样本不足」，禁止用假星级填数。
6. **注销清零**：`deleteLocalAccount` 清空行为账本与等级。

## 2. 生命周期

```text
访客 → 建号 → 资料/认证 → 社交与履约 → 交易 → 治理 → 沉默/回流 → 注销
```

| 阶段 | 典型动作 | 信用作用 |
|---|---|---|
| 访客 | 继续浏览 | 弱身份基线，交易/发布受限 |
| 建号 | 手机 / Apple / 微信 | 身份跃迁 |
| 引导 | 兴趣 onboarding | 轻度正信号 |
| 资料 | 头像昵称城市场简介兴趣 | 身份强度 |
| 合规 | 隐私、青少年、公约 | 能力边界与风险偏好 |
| 履约 | 活动 / 邀约 / 预约状态机 | **主权重** |
| 社交 | 消息、好友、圈子 | 沟通与关系健康 |
| 社区 | 发帖互动举报 | 贡献与内容风险（权重小） |
| 交易 | 支付退款会员转账 | 支付纪律 |
| 治理 | 工单结果 | 强负向 / 纠错 |
| 注销 | 删号 | 账本清空 |

## 3. 事件域与命名

统一结构：`TrustBehaviorEvent`  
字段：`id / createdAt / actorKey / subjectKey? / domain / name / value / note?`

### 已实现（`TrustEventName`）

#### account
`guest_continue` · `account_created` · `sign_out` · `account_deleted` · `onboarding_completed` · `profile_completion_changed` · `privacy_changed` · `youth_mode_changed`

#### activity
`joined` · `left` · `hosted_published` · `host_cancelled` · `order_paid` · `order_refunded`

#### buddy / booking
`invite_sent` · `invite_accepted` · `invite_declined` · `booking_created` · `booking_paid` · `booking_completed` · `booking_cancelled` · `booking_refunded` · `safety_checkin_ok` · `safety_checkin_issue`

#### social / moderation
`blocked` · `unblocked` · `person_reported` · `ticket_resolved_against`

#### wallet
`top_up` · `membership_activated`

### 路线图（尚未入库）

- account：`guidelines_ack`
- activity：`waitlist_*` · `commented` · `reported` · `check_in`
- booking：`booking_accepted/declined/rescheduled` · `person_hidden`
- social：`message_sent` · `request_*` · `friend_*` · `call_missed` · `transfer_refunded`
- community：发帖互动与举报类
- org：`circle_*` · `guild_*` · `member_kicked`
- wallet：`payment` · `refund`
- moderation：`ticket_created` · `ticket_rejected`

## 4. 内部四轴（0…100，不对公开展示为「别人打的星」）

| 轴 | 含义 | 主要信号 |
|---|---|---|
| Identity | 身份强度 | 建号、手机、资料完整、非游客、会员 |
| Reliability | 守约 | 参加保留、预约完成、低取消退款、主办不放鸽子 |
| Communication | 沟通可达 | 邀约/预约响应、消息请求接受 |
| Safety | 安全健康 | 低被举报成立、低被拉黑、敏感拦截 |

综合分：

\[
S_t = \alpha S_{t-1} + (1-\alpha)\,f(E_t)
\]

默认更看近 **90 天**；严重安全事件瞬时重扣、慢恢复。

## 5. 等级

| 等级 | 条件（可调） | 对外文案 |
|---|---|---|
| guest | 未建号 | 浏览中 |
| newcomer | 建号不久或事件少 | 新伙伴 |
| trusted | 综合分与守约过阈、无未结风险 | 可信 |
| reliableHost | 成功办场达标且主办取消率低 | 靠谱发起人 |
| restricted | 风险标记 / 严重违规 | 受限（能力降级） |

## 6. 展示规范

### 对外（好友 / 作者 / 搭子 / 发起人）

- 徽章：手机已验证、形象认证、靠谱发起人、会员…
- 事实条：近 90 天参加履约 a/b · 发起履约 c% · 账号 N 天
- 可选：响应提示「通常较快回复」
- **禁止**：多维星条、评价墙、「用户 4.9 分」

### 对内（我的信誉）

- 等级 + 综合行为分
- 四轴为「行为健康」自查进度（非他人评价）
- 提升路径、安全提示、对外预览（徽章+事实）

### 履约后

- `TrustSafetyCheckInSheet`：顺利 / 不顺利（可去举报）
- 写入 `safety_checkin_*`，不产生公开人对人评价

### 形象认证（防欺诈）

- 入口：「我的信誉」→ 防欺诈认证 / `PhotoVerificationView`
- 流程：本人头像（资料）↔ 自拍；Apple **Vision** 本机做人脸检测、采集质量与关键点相似度比对
- 通过后点亮「形象认证」徽章，并写入 `PhotoVerificationStore`（本机，注销清空）
- **不**引入商业人脸 SDK；影像不上传。正式版可叠加活体（眨眼 / 转头）与服务端复核

### UI 组件（`Features/Trust/`）

| 组件 | 用途 |
|---|---|
| `TrustLevelStrip` | 公开档案等级行 |
| `TrustBadgeRow` | 认证徽章：设置风 `Label` 行 |
| `TrustFactLabeledRows` | 近 90 天事实：`LabeledContent` |
| `TrustAxisBars` | 私域四轴：`LabeledContent` |
| `TrustTipList` | 提升路径 / 安全提示 |
| `TrustPublicProfileSections` | 对外档案分区（搭子详情、好友、作者） |
| `TrustPublicPreviewView` | 「信任档案」预览页 |
| `TrustPrivateDashboardView` | 「我的信誉」：Form，对齐会员 / 账号页 |
| `TrustSafetyCheckInSheet` | 履约后私密确认 |

视觉对齐：`Form` / `insetGrouped`、语义字色、`LabeledContent`、`Label` + `platformContentSymbolStyle`；禁止自绘 pill、装饰大图标与嵌套进度条看板。

## 7. 风险规则（摘要）

- 短窗多笔退款 → Reliability↓  
- 主办取消且已有已支付报名 → 重罚  
- 高邀约低接受 → Communication↓  
- 举报成立 → Safety↓；恶意识举报 → 举报者权↓  
- 青少年模式：交易关闭，非交易行为仍可累计  
- 注销：清空账本

## 8. 代码地图

| 路径 | 职责 |
|---|---|
| `Docs/TrustBehaviorModel.md` | 本说明（迭代用） |
| `Services/Trust/TrustModels.swift` | 事件、等级、事实、公私卡片 |
| `Services/Trust/TrustBehaviorLedger.swift` | 事件持久化 |
| `Services/Trust/TrustScoring.swift` | 计分与等级 |
| `Services/Trust/TrustService.swift` | 门面：`record` / `publicCard` / `privateStatus` / `submitSafetyCheckIn` |
| `Services/Trust/TrustPublicCredentials.swift` | 公开凭证推导（徽章事实） |
| `Features/Trust/TrustComponents.swift` | 共用 UI 原子件 |
| `Features/Trust/TrustPublicSections.swift` | 对外档案 |
| `Features/Trust/TrustPrivateDashboardView.swift` | 私域看板 |
| `Features/Trust/TrustSafetyCheckInSheet.swift` | 履约后私密确认 |
| `Features/Trust/PhotoVerificationView.swift` | 形象认证流程 |
| `Services/PhotoVerification/*` | Vision 比对引擎 + 本机状态 + 自拍相机 |
| 埋点挂接 | 活动/预约/拉黑/建号等状态机旁路 `TrustService.record` |

## 9. 后续优化清单

- [ ] 真实活动签到 `check_in`
- [ ] 消息响应时延实测（非启发式）
- [ ] 工单「处理完成且成立」自动回写 `ticket_resolved_against`
- [ ] 服务侧评价与用户信用分账（若商业需要）
- [ ] 云端同步与反作弊
- [ ] Privacy Manifest / 正式实名认证

## 10. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-07-31 | 初版：行为账本取代人对人多维星级；落地 TrustService 与 UI |
| 2026-07-31 | UI 组件库定稿；移除 BuddyReview / 星级字段与遗留评价账本 |
| 2026-07-31 | Trust UI 对齐设置页：LabeledContent / Label 行，去掉 pill 与装饰大图标 |
| 2026-07-31 | 形象认证：Vision 本机头像↔自拍比对；修复信用状态 LabeledContent |
| 2026-08-03 | 文档对齐实现：`note` 字段；事件目录拆「已实现 / 路线图」；补全代码地图 |

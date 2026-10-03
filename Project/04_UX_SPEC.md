# 04 · 用户体验规范（UX Spec）

---

## 1. UX 原则（对齐 HIG + 本产品）

1. **转化优先**：详情首屏只服务「是否参加」；长文下沉。  
2. **一套节奏两套页**：发现 = 媒体货架；详情 / 设置 / 支付 = Form。  
3. **系统容器优先**：少自定义流程骨架；用 `NavigationStack` / `sheet` / `confirmationDialog`。  
4. **诚实反馈**：加载、空、错、支付边界必须可读；禁止伪装成功。  
5. **履约唯一主页**：行程 checklist 不回流活动发现首屏。  
6. **门闸可理解**：核验 / 协议 / 兴趣打断时说明「为什么」与「下一步」。

---

## 2. 关键体验标准

| 场景 | UX 要求 |
|------|---------|
| 登录 | 主路径短；社交按钮次级；协议独立勾选 |
| 兴趣 | 硬门槛但选项清晰；可稍后在资料改 |
| 发现 | 分区目的单一（一层标题）；筛选即时生效；下一场 Banner 不抢新用户注意力；Tab 根顶栏见 `11` 五 Tab 统一契约 |
| 搭子发现 | 标题菜单互切找搭子 / 约陪玩 / 俱乐部；人模式单 Hero；约陪玩卡突出价/可约；空态主诉「找可约的人」；三模式各自 L1 Menu + 深筛选（**无**系统搜索框）；俱乐部海报网格 + 主题/城市筛选；顶栏与五 Tab 同套；门闸 Sheet 写明下一步 |
| 详情 | 决策卡 > 信任 > 正文；主 CTA 单一突出；未核验时 Hint 写「完成认证后即可参加」 |
| 参加确认 | 费用 / 时间 / 冲突一眼可见；付费披露在主路径；确认前走 `IdentityGateSource.activityJoin` |
| 成功 | 一个主 CTA（行程或群）；次要日历不抢主；**不**交叉推销搭子 |
| 主办 | Form 管理；破坏性操作二次确认 |
| 空态 | `ContentUnavailableView` + 一个明确行动（找局 / 开局） |
| Tab 根顶栏 | 五 Tab 统一：`navigationTitle` + `.inlineLarge` + soft edge + 栏材质联动；不压制 compact title（无空 principal / scroll-away）；活动/搭子另加 `toolbarTitleMenu`；Trailing 分组 + Badge；下拉刷新 |
| 我的根 | 同上契约；设置在 `topBarTrailing` |
| 门闸 Sheet | 按 `IdentityGateSource` 区分活动参加 / 预约邀约 / 发消息的「为什么 / 下一步」 |

---

## 3. 文案

- 活动动作词统一走 `ActivityCardStatus` / `*Copy` 枚举，禁止旁路硬编码主 CTA。  
- 「免费」唯一词表：`ActivityCardStatus.free`。  
- Release 支付文案必须暴露「设备本地账本 / 外部通道未开放」，见 `CommercePaymentPolicy`。

---

## 4. 反馈通道（唯一）

| 允许 | 禁止 |
|------|------|
| `platformFeedbackAlert` / 系统 `.alert` | 自定义 Toast 浮层 |
| `platformLightFeedback` | 多阴影「成功胶囊」 |
| `confirmationDialog` | 用 Sheet 做二选一确认（除非内容长） |
| `ContentUnavailableView` | 空白无说明 |

---

## 5. 反模式

- 详情首屏堆日程、地址、促销、统计条  
- 同一屏多个同等权重主按钮  
- 用「演示成功」话术覆盖 Release  
- 欢迎与兴趣混成一个强迫流程  

---

*下一篇：[05_UI_SPEC.md](05_UI_SPEC.md)*

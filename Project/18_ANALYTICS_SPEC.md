# 18 · 埋点与可观测性（Analytics / Observability）

> 产品要能回答「漏在哪」；工程要能回答「坏在哪」。本文件定**事件契约与隐私边界**，不绑死某一家 SDK。

---

## 1. 原则

1. **漏斗事件少而稳**：认证、兴趣、发现曝光、详情、参加、发布；勿每点击都埋。  
2. **属性可枚举**：用稳定 `snake_case` 名；禁止把 JWT、手机号、精确 GPS、验证码写入属性。  
3. **客户端可关**：DEBUG 可打控制台；Release 仅经 `AnalyticsClient`（或后继唯一门面）。  
4. **失败可观测 ≠ 骚扰用户**：远程 sync / 持久化失败记状态与日志；UI 遵循 `10`。

---

## 2. 漏斗事件（现行应覆盖）

| 事件名（建议） | 何时 | 关键属性（示例） |
|----------------|------|------------------|
| `auth_sms_send` | 发码 | `result` |
| `auth_login_success` / `auth_login_failure` | 登录结果 | `method`（sms/apple/wechat）、`reason`（失败可枚举） |
| `auth_session_invalidated` | 401/撤销登出 | `source` |
| `interest_onboarding_complete` | 兴趣硬门通过 | `tag_count` |
| `welcome_guide_dismiss` | 欢迎跳过或完成 | `skipped` |
| `activity_impression` | 发现卡稳定曝光 | `activity_id`、`surface` |
| `activity_detail_open` | 进详情 | `activity_id`、`entry`（zoom/push/deeplink） |
| `activity_join_attempt` / `activity_join_result` | 参加 | `result`、`waitlist`、`paid` |
| `activity_publish_result` | 发布 | `result` |
| `identity_gate_shown` / `passed` | 核验打断 | `intent`（join/booking/…） |
| `commerce_checkout_blocked` | 政策挡外部支付 | `method` |
| `commerce_topup_start` | 发起充值 | `channel`、`amount_cents`、`mode`（demo_local/remote） |
| `commerce_topup_result` | 充值结果 | `channel`、`result`（禁止用演示成功冒充转化） |
| `commerce_charge_result` | 扣款结果 | `order_type`、`result`、`method` |
| `commerce_refund_submit` | 退款申请 | `order_type`、`result` |
| `commerce_withdraw_blocked` | 提现未开放 | `reason` |
| `commerce_invoice_blocked` | 开票未开放 | `reason` |

既有 `AuthAnalytics` / `InterestAnalytics` / `CommerceAnalytics` 应对齐上表语义；新增域事件先改本表再写代码。

---

## 3. 非漏斗（工程遥测）

| 信号 | 用途 | 注意 |
|------|------|------|
| 启动到首帧可交互 | 性能（见 `19`） | 不含用户 PII |
| 持久化写失败 | `AppPersistenceHealth` | 文案可本地化；日志无快照全文 |
| 远程 catalog sync 成败 | `RemoteSyncStatus` | 勿因失败弹窗刷屏 |
| 崩溃 / 非致命 | 提审后接入（如 MetricKit / 第三方） | 符号表与隐私政策同步 |

---

## 4. 禁止

- 日志或分析里打印 access token、refresh token、短信码  
- 用分析事件代替产品诚实门控（例如「演示成功」当转化）  
- 在 View 里直接调多家 SDK；必须经统一 Client  

---

## 5. 与测试 / 上线

- Domain 用例**不**依赖分析；分析在 Feature / App 编排层。  
- 软启动：至少能在 DEBUG 核对登录与参加漏斗是否打出。  
- App Store：分析 SDK 的 Privacy Manifest / 用途字符串与 `14` 一致。

---

*下一篇：[19_PERFORMANCE_SPEC.md](19_PERFORMANCE_SPEC.md)*

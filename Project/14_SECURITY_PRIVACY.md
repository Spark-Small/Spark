# 14 · 安全 / 隐私（Security & Privacy）

---

## 1. 账户与凭证

| 项 | 做法 |
|----|------|
| 会话快照 | Keychain（`AuthSessionStore`） |
| JWT | Keychain（`AuthTokenStore`）；refresh；失败登出 |
| 演示码 | 仅 DEBUG 且 `!useRemoteAuth` |
| 旧 guest | 解码规范为未登录 |
| Apple 撤销 | 冷启动刷新凭证状态 → 登出 |

---

## 2. 身份核验门禁

报名 / 预约 / 部分社交：`IdentityAccessGate`（认证照 + 人脸）。  
**不是**登录态本身；未登录进不了 Tab。

`FeatureFlags.requireIdentityVerification`：Release 恒 true。

二次复核（`IdentityRemoteReverifyService` / `identity/reverify`）：仅真实联网成功才写 `PhotoVerificationStore.remoteVerified`；演示代理、Flag 关、服务不可用回落本机时 UI 须显示「本机结果」，**禁止**冒充「服务端已确认」。分析事件 `identityRemoteVerified` 同口径。

**实名认证（居民身份证 / 护照）**：`RealNameVerificationSheet`（滚轮选证件类型）+ Vision OCR + `ParseChineseResidentIDUseCase` / `ParsePassportIdentityUseCase`（护照优先 MRZ，其次可视区）。性别/出生日期（年龄）仅由证件本机解析写入，`EditProfile` 基本资料中性别与年龄**只读**。不存证件号明文（仅 SHA256 指纹 + 脱敏尾号）；UI / 徽章文案须标明「本机识别」，**禁止**冒充公安库 / 出入境机关 / 网证已核验。远程 KYC 未接前 Merge 须保留本机实名字段（含 `realNameDocumentKind` 与护照资料页文件名）。

**分层**：形象门禁规则与文案在 `Features/Identity`（`IdentityCapability` / `IdentityAccessGate` / `IdentitySignals`）；业务 Tab 只经 `AppModel.requireIdentityAccess`；Trust / 好友卡徽章读 `app.identitySignals`，禁止手拼实名字段。钱包与身份门禁正交。

---

## 3. 隐私合规

| 项 | 状态 |
|----|------|
| `PrivacyInfo.xcprivacy` | 已入库；提审前再核对 API |
| 隐私 / 条款 | `LegalDocumentURLs` 外开 HTTPS；**托管页须公网可达** |
| 协议版本 bump | `LegalConsentGate` |
| 权限时机 | 非开屏连环要权；报名成功 / 用附近等场景再请求 |

---

## 4. 内容与未成年人

- UGC 文本扫描 / 青少年词表（既有 ContentModeration 路径）  
- 媒体审核 Flag（远程 / 演示代理）；误杀可申诉入口（产品文案）  

---

## 5. 支付诚实（安全相关审核）

- Release 禁止模拟外部支付到账  
- 钱包默认设备账本投影，须披露；`useRemoteWallet` 时以服务端为准，未确认到账禁止本地加款  
- 不收集非必要支付字段（卡号/CVV 等不进客户端）  
- 充值渠道凭证仅经服务端 Webhook；客户端只持调起载荷  
- 提现 / 开票未开放前不得伪装成功  

---

## 6. 数据最小化

- 日志避免打印 token / 验证码  
- 远程失效清会话  
- 注销路径应清空行为账本与本地身份（Trust / Profile 既有约定）  

---

*下一篇：[15_TEST_SPEC.md](15_TEST_SPEC.md)*

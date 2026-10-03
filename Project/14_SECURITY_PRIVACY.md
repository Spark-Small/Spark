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
- 钱包为设备账本，须披露  
- 不收集非必要支付字段  

---

## 6. 数据最小化

- 日志避免打印 token / 验证码  
- 远程失效清会话  
- 注销路径应清空行为账本与本地身份（Trust / Profile 既有约定）  

---

*下一篇：[15_TEST_SPEC.md](15_TEST_SPEC.md)*

# LoginView — UI spec (Spark Auth)

Canonical layout: [docs/TAB_SCREENS.md](../../../docs/TAB_SCREENS.md) L3 LoginView · typography: [docs/TYPOGRAPHY.md](../../../docs/TYPOGRAPHY.md) §认证.

## Chrome

| Modifier | Purpose |
|----------|---------|
| `Form` only | 系统分组背景 · `scrollDismissesKeyboard` · `sparkAuthLoginScreenBackground` — 无自定义 canvas / `.bar` |

## Components

| File | Role |
|------|------|
| `LoginView.swift` | Shell |
| `LoginPhoneFieldRows.swift` | Phone / OTP rows · fixed trailing slot · `sparkAuthFormCredentialRow` |
| `LoginLegalConsentSection.swift` | 协议 / 隐私勾选 |
| `LoginThirdPartySignInBar.swift` | 底部第三方圆形登录（Apple · 支付宝 · 微信） |
| `LoginPrimaryActionSection.swift` | 登录 + 取消 |
| `ForgotPasswordView.swift` | Email password reset |
| `AuthFailureAlert.swift` | Error alert |
| `AuthFormChrome.swift` | Sub-page chrome |
| `AuthViewModel.swift` | State + use cases |

## Layout

```
NavigationStack「Nexus」
Form（scrollDismissesKeyboard）
├─ Section: 协议 / 隐私勾选 · footer 新号说明
├─ Section: slogan · phone · OTP · footer 忘记密码
└─ Section: 登录 · 取消（sparkAuthFormPrimaryRow）
safeAreaInset bottom: Apple · 支付宝 · 微信（44pt 圆形 · spacing 20 · tab-bar 区域）
```

## Auth paths

1. Phone OTP — primary（新号自动注册 · footer 说明）
2. Forgot password — email reset sub-page
3. Third-party — Apple Live；微信 / 支付宝 Mock + Staging API（MODULE-H SDK 生产待接入）
4. Legal consent — 登录前勾选《用户协议》《隐私政策》（`LoginLegalConsentSection`）
5. Session — 带 Bearer 的 API `401` → `handleSessionInvalidated()` 清 Keychain

## Cancel（取消）

| 场景 | 行为 |
|------|------|
| 根登录（`SparkRootView`） | 清空手机号/验证码、重置 OTP 状态、收起键盘、`dismissFailure()` — **不**调用 `dismiss()` |
| Modal 呈现（可选 `onDismiss`） | 同上 + 调用注入的 `onDismiss` |
| 登录中 / 发送验证码中 | 取消按钮 `disabled` |

## Previews

Default · OTP expanded · Signing in · Failure · Dark · Accessibility XL

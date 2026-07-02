// Module: SparkAuth — Localized copy for LoginView.

import Foundation

enum LoginCopy {
    static let navigationTitle = String(
        localized: "auth.login.nav",
        defaultValue: "加入Nexus",
        comment: "Login navigation title"
    )
    static let subtitle = String(
        localized: "auth.login.subtitle",
        defaultValue: "认识新朋友，从一句你好开始！",
        comment: "Login subtitle"
    )
    static let phonePlaceholder = String(
        localized: "auth.login.phone.placeholder",
        defaultValue: "手机号码",
        comment: "Phone number placeholder"
    )
    static let verificationCodePlaceholder = String(
        localized: "auth.login.phoneOtp.code.placeholder",
        defaultValue: "短信验证码",
        comment: "Verification code placeholder"
    )
    static let sendVerificationCode = String(
        localized: "auth.login.phoneOtp.sendCode",
        defaultValue: "发送验证码",
        comment: "Send verification code"
    )
    static let resendVerificationCode = String(
        localized: "auth.login.phoneOtp.resendCode",
        defaultValue: "重新发送验证码",
        comment: "Resend verification code"
    )
    static func resendCountdown(seconds: Int) -> String {
        String(
            localized: "auth.login.phoneOtp.resendCountdown",
            defaultValue: "\(seconds) 秒后可重新发送",
            comment: "OTP resend countdown"
        )
    }

    /// Compact countdown shown beside the phone field (e.g. `59s`).
    static func resendCountdownCompact(seconds: Int) -> String {
        String(
            localized: "auth.login.phoneOtp.resendCountdown.compact",
            defaultValue: "\(seconds)s",
            comment: "Compact OTP resend countdown beside phone field"
        )
    }

    static let forgotPassword = String(
        localized: "auth.login.forgotPassword.link",
        defaultValue: "找回密码",
        comment: "Password recovery link"
    )
    static let forgotPasswordHint = String(
        localized: "auth.login.forgotPasswordLink.hint",
        defaultValue: "使用手机号和短信验证码重置密码",
        comment: "Forgot password hint"
    )
    static let signIn = String(
        localized: "auth.login.confirm",
        defaultValue: "登录",
        comment: "Sign in"
    )
    static let cancel = String(
        localized: "action.cancel",
        defaultValue: "取消",
        comment: "Cancel login flow"
    )
    static let cancelHint = String(
        localized: "auth.login.cancel.hint",
        defaultValue: "中止当前登录步骤并清空已输入内容",
        comment: "Cancel login flow hint"
    )
    static let appleSignIn = String(
        localized: "auth.login.apple",
        defaultValue: "通过 Apple 登录",
        comment: "Apple sign in"
    )
    static let alipaySignIn = String(
        localized: "auth.login.alipay",
        defaultValue: "支付宝登录",
        comment: "Alipay sign in"
    )
    static let weChatSignIn = String(
        localized: "auth.login.wechat",
        defaultValue: "微信登录",
        comment: "WeChat sign in"
    )
    static let providerUnavailableHint = String(
        localized: "auth.login.provider.unavailable.hint",
        defaultValue: "该登录方式即将开放",
        comment: "Third-party sign in unavailable hint"
    )
    static let errorTitle = String(
        localized: "auth.login.error.title",
        defaultValue: "无法登录",
        comment: "Login error title"
    )
    static let errorOK = String(
        localized: "auth.login.error.ok",
        defaultValue: "好",
        comment: "OK"
    )
    static let legalLead = String(
        localized: "auth.login.legal.lead",
        defaultValue: "登录即表示同意",
        comment: "Legal consent lead-in"
    )
    static let legalAnd = String(
        localized: "auth.login.legal.and",
        defaultValue: "和",
        comment: "Legal conjunction"
    )
    static let termsOfService = String(
        localized: "legal.termsOfService",
        defaultValue: "《用户协议》",
        comment: "Terms of service"
    )
    static let privacyPolicy = String(
        localized: "legal.privacyPolicy.short",
        defaultValue: "《隐私政策》",
        comment: "Privacy policy"
    )
    static let termsHint = String(
        localized: "auth.login.legal.terms.hint",
        defaultValue: "在浏览器中打开用户协议",
        comment: "Terms of service link hint"
    )
    static let privacyHint = String(
        localized: "auth.login.legal.privacy.hint",
        defaultValue: "在浏览器中打开隐私政策",
        comment: "Privacy policy link hint"
    )
}

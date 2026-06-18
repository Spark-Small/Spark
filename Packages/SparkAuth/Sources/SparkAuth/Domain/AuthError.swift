// Module: SparkAuth — Feature-specific auth errors.

import Foundation
import SparkCore

public enum AuthError: LocalizedError, Sendable, Equatable {
    case invalidCredentials
    case invalidPhone
    case invalidOTP
    case invalidEmail
    case appleSignInFailed
    case thirdPartySignInFailed(AuthThirdPartyLoginProvider)
    case thirdPartySDKNotConfigured(AuthThirdPartyLoginProvider)
    case legalConsentRequired
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "auth.error.invalidCredentials", defaultValue: "邮箱或密码不正确", comment: "Auth error")
        case .invalidPhone:
            String(localized: "auth.error.invalidPhone", defaultValue: "请输入有效的 11 位手机号", comment: "Auth error")
        case .invalidOTP:
            String(localized: "auth.error.invalidOTP", defaultValue: "验证码不正确或已过期", comment: "Auth error")
        case .invalidEmail:
            String(localized: "auth.error.invalidEmail", defaultValue: "请输入有效邮箱", comment: "Auth error")
        case .appleSignInFailed:
            String(localized: "auth.error.appleSignIn", defaultValue: "Apple 登录失败", comment: "Auth error")
        case let .thirdPartySignInFailed(provider):
            switch provider {
            case .weChat:
                String(localized: "auth.error.weChatSignIn", defaultValue: "微信登录失败", comment: "WeChat sign in error")
            case .alipay:
                String(localized: "auth.error.alipaySignIn", defaultValue: "支付宝登录失败", comment: "Alipay sign in error")
            }
        case let .thirdPartySDKNotConfigured(provider):
            switch provider {
            case .weChat:
                String(
                    localized: "auth.error.weChatSDKNotConfigured",
                    defaultValue: "微信登录尚未配置，请使用手机验证码登录",
                    comment: "WeChat SDK not configured"
                )
            case .alipay:
                String(
                    localized: "auth.error.alipaySDKNotConfigured",
                    defaultValue: "支付宝登录尚未配置，请使用手机验证码登录",
                    comment: "Alipay SDK not configured"
                )
            }
        case .legalConsentRequired:
            String(
                localized: "auth.error.legalConsentRequired",
                defaultValue: "请先阅读并同意用户协议与隐私政策",
                comment: "Legal consent required before sign in"
            )
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

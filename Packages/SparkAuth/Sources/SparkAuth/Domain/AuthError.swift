// Module: SparkAuth — Feature-specific auth errors.

import Foundation
import SparkCore

public enum AuthError: LocalizedError, Sendable, Equatable {
    case invalidCredentials
    case appleSignInFailed
    case userCancelled
    case providerNotConfigured(AuthProvider)
    case phoneOneTapUnavailable
    case weChatSignInUnavailable
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "auth.error.invalidCredentials", defaultValue: "登录失败，请重试", comment: "Auth error")
        case .appleSignInFailed:
            String(localized: "auth.error.appleSignIn", defaultValue: "Apple 登录失败", comment: "Auth error")
        case .userCancelled:
            String(localized: "auth.error.userCancelled", defaultValue: "已取消登录", comment: "Auth error")
        case let .providerNotConfigured(provider):
            providerNotConfiguredMessage(for: provider)
        case .phoneOneTapUnavailable:
            String(
                localized: "auth.error.phoneOneTapUnavailable",
                defaultValue: "本机号码一键登录不可用，请检查蜂窝网络或 SIM 卡后重试",
                comment: "Auth error"
            )
        case .weChatSignInUnavailable:
            String(
                localized: "auth.error.weChatSignInUnavailable",
                defaultValue: "无法唤起微信，请确认已安装微信",
                comment: "Auth error"
            )
        case let .underlying(appError):
            appError.errorDescription
        }
    }

    private func providerNotConfiguredMessage(for provider: AuthProvider) -> String {
        switch provider {
        case .wechat:
            String(
                localized: "auth.error.providerNotConfigured.wechat",
                defaultValue: "微信登录尚未配置，请尝试其他方式",
                comment: "Auth error"
            )
        case .phoneOneTap:
            String(
                localized: "auth.error.providerNotConfigured.phoneOneTap",
                defaultValue: "本机号码一键登录尚未配置，请尝试其他方式",
                comment: "Auth error"
            )
        case .phoneOtp:
            String(
                localized: "auth.error.providerNotConfigured.phoneOtp",
                defaultValue: "手机号验证码登录尚未配置，请尝试其他方式",
                comment: "Auth error"
            )
        case .alipay:
            String(
                localized: "auth.error.providerNotConfigured.alipay",
                defaultValue: "支付宝登录尚未配置，请尝试其他方式",
                comment: "Auth error"
            )
        case .apple:
            String(
                localized: "auth.error.providerNotConfigured.apple",
                defaultValue: "Apple 登录不可用",
                comment: "Auth error"
            )
        }
    }
}

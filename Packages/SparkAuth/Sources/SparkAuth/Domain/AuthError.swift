// Module: SparkAuth — Feature-specific auth errors.

import Foundation
import SparkCore

public enum AuthError: LocalizedError, Sendable, Equatable {
    case invalidCredentials
    case emailAlreadyRegistered
    case invalidEmail
    case appleSignInFailed
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "auth.error.invalidCredentials", defaultValue: "邮箱或密码不正确", comment: "Auth error")
        case .emailAlreadyRegistered:
            String(
                localized: "auth.error.emailAlreadyRegistered",
                defaultValue: "该邮箱已注册，请直接登录",
                comment: "Auth error"
            )
        case .invalidEmail:
            String(localized: "auth.error.invalidEmail", defaultValue: "请输入有效邮箱", comment: "Auth error")
        case .appleSignInFailed:
            String(localized: "auth.error.appleSignIn", defaultValue: "Apple 登录失败", comment: "Auth error")
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

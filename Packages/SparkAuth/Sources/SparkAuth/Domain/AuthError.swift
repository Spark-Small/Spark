// Module: SparkAuth — Feature-specific auth errors.

import Foundation
import SparkCore

public enum AuthError: LocalizedError, Sendable, Equatable {
    case invalidCredentials
    case appleSignInFailed
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "auth.error.invalidCredentials", defaultValue: "邮箱或密码不正确", comment: "Auth error")
        case .appleSignInFailed:
            String(localized: "auth.error.appleSignIn", defaultValue: "Apple 登录失败", comment: "Auth error")
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

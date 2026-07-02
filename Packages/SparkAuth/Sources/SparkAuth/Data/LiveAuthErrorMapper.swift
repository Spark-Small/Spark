// Module: SparkAuth — Map APIClient errors to AuthError for Live auth flows.

import Foundation
import SparkCore

enum LiveAuthErrorMapper {
    static func mapPhoneOTP(_ error: Error) -> Error {
        if let authError = error as? AuthError { return authError }
        if let appError = error as? AppError {
            switch appError {
            case .server(let statusCode, _) where statusCode == 400:
                return AuthError.invalidPhone
            case .server(let statusCode, _) where statusCode == 429:
                return AuthError.otpRateLimited
            default:
                return AuthError.underlying(appError)
            }
        }
        return AuthError.underlying(.unknown(message: error.localizedDescription))
    }

    static func mapPhoneVerification(_ error: Error) -> Error {
        if let authError = error as? AuthError { return authError }
        if let appError = error as? AppError {
            switch appError {
            case .unauthorized:
                return AuthError.invalidVerificationCode
            case .server(let statusCode, _) where statusCode == 400:
                return AuthError.invalidPhone
            case .server(let statusCode, _) where statusCode == 429:
                return AuthError.otpRateLimited
            default:
                return AuthError.underlying(appError)
            }
        }
        return AuthError.underlying(.unknown(message: error.localizedDescription))
    }
}

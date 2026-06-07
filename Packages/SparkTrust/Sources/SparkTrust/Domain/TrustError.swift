// Module: SparkTrust — Trust feature errors.

import Foundation
import SparkCore

public enum TrustError: LocalizedError, Sendable, Equatable {
    case verificationFailed
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .verificationFailed:
            String(
                localized: "trust.error.verification",
                defaultValue: "认证未通过，请重试",
                comment: "Trust verification failed"
            )
        case .underlying(let error):
            error.errorDescription
        }
    }
}

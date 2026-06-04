// Module: SparkCommunity — Community errors.

import Foundation
import SparkCore

public enum CommunityError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

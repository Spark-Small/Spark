// Module: SparkCommunity — Community errors.

import Foundation
import SparkCore

public enum CommunityError: LocalizedError, Sendable, Equatable {
    case emptyInput
    case fieldTooLong
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            String(localized: "community.error.empty", defaultValue: "内容不能为空", comment: "Empty input")
        case .fieldTooLong:
            String(localized: "community.error.tooLong", defaultValue: "内容过长", comment: "Field too long")
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

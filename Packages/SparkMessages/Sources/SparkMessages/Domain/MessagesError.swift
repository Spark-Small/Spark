// Module: SparkMessages — Feature-specific errors.

import Foundation
import SparkCore

public enum MessagesError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

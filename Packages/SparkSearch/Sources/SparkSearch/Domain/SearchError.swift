// Module: SparkSearch — Search errors.

import Foundation
import SparkCore

public enum SearchError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case let .underlying(appError):
            appError.errorDescription
        }
    }
}

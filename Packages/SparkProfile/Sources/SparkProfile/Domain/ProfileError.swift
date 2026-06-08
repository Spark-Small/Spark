// Module: SparkProfile — Profile boundary errors.

import Foundation
import SparkCore

public enum ProfileError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)
}

extension ProfileError {
    public var errorDescription: String? {
        switch self {
        case let .underlying(error):
            error.localizedDescription
        }
    }
}

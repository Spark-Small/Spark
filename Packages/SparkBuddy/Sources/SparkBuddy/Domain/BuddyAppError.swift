// Module: SparkBuddy — AppError convenience init shared across ViewModels.

import Foundation
import SparkCore

extension AppError {
    /// Unwrap BuddyError → AppError, fall through to generic `unknown`.
    init(buddyUnderlying error: Error) {
        if let buddyError = error as? BuddyError,
           case let .underlying(appError) = buddyError {
            self = appError
            return
        }
        if let appError = error as? AppError {
            self = appError
            return
        }
        self = .unknown(message: error.localizedDescription)
    }
}

// Module: SparkLikes — Presentation-safe errors with recovery text.

import Foundation
import SparkCore

public struct LikesUserFacingError: Equatable, Sendable {
    public let message: String
    public let recoverySuggestion: String?

    public init(message: String, recoverySuggestion: String? = nil) {
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }

    public var displayText: String {
        guard let recoverySuggestion, !recoverySuggestion.isEmpty else {
            return message
        }
        let format = String(
            localized: "likes.error.display.format",
            defaultValue: "%1$@\n%2$@",
            comment: "Error message and recovery; %1$@ message, %2$@ recovery"
        )
        return String(format: format, locale: .current, message, recoverySuggestion)
    }

    public static func from(_ error: Error) -> LikesUserFacingError {
        if let likesError = error as? LikesError {
            return LikesUserFacingError(
                message: likesError.errorDescription ?? defaultMessage,
                recoverySuggestion: likesError.recoverySuggestion
            )
        }
        if let localized = error as? LocalizedError {
            return LikesUserFacingError(
                message: localized.errorDescription ?? defaultMessage,
                recoverySuggestion: localized.recoverySuggestion
            )
        }
        return LikesUserFacingError(message: error.localizedDescription)
    }

    private static var defaultMessage: String {
        String(
            localized: "likes.error.generic",
            defaultValue: "出了点问题，请稍后再试",
            comment: "Generic likes error"
        )
    }
}

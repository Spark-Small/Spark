// Module: SparkAuth — Login funnel signposts (no PII).

import Foundation
import SparkCore

public enum AuthTelemetry {
    private static let logger = SparkLog.logger(category: "AuthAnalytics")

    public static func loginStarted(method: String) {
        logger.info("auth_login_started method=\(method, privacy: .public)")
    }

    public static func loginSucceeded(method: String) {
        logger.info("auth_login_succeeded method=\(method, privacy: .public)")
    }

    public static func loginFailed(method: String, reason: String) {
        logger.info(
            "auth_login_failed method=\(method, privacy: .public) reason=\(reason, privacy: .public)"
        )
    }

    public static func sessionInvalidated() {
        logger.info("auth_session_invalidated")
    }

    public static func legalConsentAccepted() {
        logger.info("auth_legal_consent_accepted")
    }
}

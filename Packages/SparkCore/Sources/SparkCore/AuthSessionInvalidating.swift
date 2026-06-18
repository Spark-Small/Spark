// Module: SparkCore — Session expiry callback for HTTP 401 handling.

import Foundation

/// Notified when an authenticated API call receives `401 Unauthorized`.
public protocol AuthSessionInvalidating: Sendable {
    func sessionDidBecomeUnauthorized() async
}

// Module: SparkAuth — Bridges HTTP 401 to `AuthViewModel` without singletons.

import Foundation
import SparkCore

public actor AuthSessionInvalidationBroadcaster: AuthSessionInvalidating {
    private var handler: (@Sendable () async -> Void)?

    public init() {}

    public func setHandler(_ handler: @escaping @Sendable () async -> Void) {
        self.handler = handler
    }

    public func sessionDidBecomeUnauthorized() async {
        await handler?()
    }
}

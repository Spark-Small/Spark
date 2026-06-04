// Module: SparkCore — Access token source for authorized API calls.

import Foundation

/// Supplies bearer tokens for HTTP interceptors (Keychain implementation in SparkPersistence).
public protocol AccessTokenProviding: Sendable {
    func accessToken() async -> String?
}

/// No-op token provider for unauthenticated / mock flows.
public struct EmptyAccessTokenProvider: AccessTokenProviding, Sendable {
    public init() {}

    public func accessToken() async -> String? { nil }
}

// Module: SparkCore — Strongly typed user identifier.

import Foundation

/// Opaque user identifier (never use bare `String` across module boundaries).
public struct UserID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}

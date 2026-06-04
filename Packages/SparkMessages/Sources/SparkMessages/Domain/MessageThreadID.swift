// Module: SparkMessages — Strongly typed thread identifier.

import Foundation

public struct MessageThreadID: Hashable, Sendable, Codable, Equatable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

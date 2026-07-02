// Module: SparkBuddy — AI interest-match preview for browse/detail.

import Foundation

public struct BuddyMatchInsight: Equatable, Sendable {
    public let matchPercent: Int
    public let reason: String

    public init(matchPercent: Int, reason: String) {
        self.matchPercent = min(100, max(0, matchPercent))
        self.reason = reason
    }
}

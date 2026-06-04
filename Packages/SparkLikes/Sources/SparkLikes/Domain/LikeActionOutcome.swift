// Module: SparkLikes — Result of like / friend actions.

import Foundation

public enum LikeActionOutcome: String, Sendable, Equatable {
    case matched
    case pending
    case alreadyConnected
    case sent
}

public struct LikeActionResult: Sendable, Equatable {
    public let outcome: LikeActionOutcome
    public let threadID: String?

    public init(outcome: LikeActionOutcome, threadID: String? = nil) {
        self.outcome = outcome
        self.threadID = threadID
    }
}

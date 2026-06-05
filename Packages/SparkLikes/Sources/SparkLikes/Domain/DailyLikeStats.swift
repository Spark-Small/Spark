// Module: SparkLikes — Daily discover pool and spark allowance.

import Foundation

public struct DailyLikeStats: Sendable, Equatable {
    public let todaySeenCount: Int
    public let dailyPoolSize: Int
    public let sparkChargesRemaining: Int

    public init(
        todaySeenCount: Int,
        dailyPoolSize: Int,
        sparkChargesRemaining: Int
    ) {
        self.todaySeenCount = todaySeenCount
        self.dailyPoolSize = dailyPoolSize
        self.sparkChargesRemaining = sparkChargesRemaining
    }

    public var isPoolExhausted: Bool {
        todaySeenCount >= dailyPoolSize
    }
}

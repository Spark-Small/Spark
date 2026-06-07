// Module: SparkTrust — Aggregated trust profile.

import Foundation

public struct TrustProfile: Sendable, Equatable {
    public let totalScore: Int
    public let completedLevels: Set<TrustLevel>
    public let activityAttendanceCount: Int

    public init(
        totalScore: Int,
        completedLevels: Set<TrustLevel>,
        activityAttendanceCount: Int = 0
    ) {
        self.totalScore = totalScore
        self.completedLevels = completedLevels
        self.activityAttendanceCount = activityAttendanceCount
    }

    public var hasLiveness: Bool {
        completedLevels.contains(.liveness)
    }

    public var nextMVPPendingLevel: TrustLevel? {
        TrustLevel.mvpLevels.first { !completedLevels.contains($0) }
    }
}

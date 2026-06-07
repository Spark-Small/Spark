// Module: SparkTrust — Mock trust profile for previews and mock host.

import Foundation

public actor MockTrustRepository: TrustRepository {
    private var completed: Set<TrustLevel> = [.phone]

    public init(initialCompleted: Set<TrustLevel> = [.phone]) {
        completed = initialCompleted
    }

    public func fetchProfile() async throws -> TrustProfile {
        makeProfile()
    }

    public func verifyPhone() async throws -> TrustProfile {
        completed.insert(.phone)
        return makeProfile()
    }

    public func verifyRealName() async throws -> TrustProfile {
        completed.insert(.realName)
        return makeProfile()
    }

    public func verifyLiveness() async throws -> TrustProfile {
        completed.insert(.liveness)
        return makeProfile()
    }

    private func makeProfile() -> TrustProfile {
        let score = completed.reduce(0) { $0 + $1.pointValue }
        return TrustProfile(
            totalScore: score,
            completedLevels: completed,
            activityAttendanceCount: completed.contains(.activityRecord) ? 2 : 0
        )
    }
}

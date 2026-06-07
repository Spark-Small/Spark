// Module: SparkTrust — Verify a single MVP trust level.

import Foundation

public struct VerifyTrustLevelUseCase: Sendable {
    private let repository: any TrustRepository

    public init(repository: any TrustRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ level: TrustLevel) async throws -> TrustProfile {
        switch level {
        case .phone:
            try await repository.verifyPhone()
        case .realName:
            try await repository.verifyRealName()
        case .liveness:
            try await repository.verifyLiveness()
        case .career, .activityRecord, .socialEndorsement:
            try await repository.fetchProfile()
        }
    }
}

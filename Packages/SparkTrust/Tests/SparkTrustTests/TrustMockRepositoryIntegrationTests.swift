// Module: SparkTrustTests — Mock repository integration coverage.

import SparkTrust
import Testing

struct TrustMockRepositoryIntegrationTests {
    @Test func mockRepositoryVerifiesAllLevels() async throws {
        let repository = MockTrustRepository(initialCompleted: [])
        _ = try await repository.fetchProfile()
        _ = try await repository.verifyPhone()
        _ = try await repository.verifyRealName()
        let profile = try await repository.verifyLiveness()
        #expect(profile.completedLevels.contains(.liveness))
        #expect(profile.totalScore > 0)
    }
}

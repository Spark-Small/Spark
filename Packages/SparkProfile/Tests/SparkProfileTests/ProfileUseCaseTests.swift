// Module: SparkProfileTests — Profile domain UseCase coverage.

@testable import SparkProfile
import SparkTrust
import Testing

struct ProfileUseCaseTests {
    @Test func fetchProfileSummaryWrapsTrustProfile() async throws {
        let repository = MockTrustRepository(initialCompleted: [.phone])
        let summary = try await FetchProfileSummaryUseCase(trustRepository: repository)()
        #expect(summary.trustProfile.completedLevels.contains(.phone))
    }
}

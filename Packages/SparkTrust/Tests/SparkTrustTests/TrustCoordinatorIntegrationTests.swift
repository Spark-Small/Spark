// Module: SparkTrustTests — Trust coordinator and mock repository integration.

@testable import SparkTrust
import Testing

@MainActor
struct TrustCoordinatorIntegrationTests {
    @Test func mockRepositoryFetchAndVerify() async throws {
        let repository = MockTrustRepository(initialCompleted: [])
        let fetch = FetchTrustProfileUseCase(repository: repository)
        let verify = VerifyTrustLevelUseCase(repository: repository)

        var profile = try await fetch()
        #expect(profile.completedLevels.isEmpty)

        profile = try await verify(.phone)
        #expect(profile.completedLevels.contains(.phone))
    }

    @Test func verificationViewModelUsesCoordinator() async {
        let coordinator = TrustCoordinator(repository: MockTrustRepository(initialCompleted: []))
        let viewModel = coordinator.makeVerificationViewModel()
        await viewModel.load()
        #expect(viewModel.profile != nil)
    }
}

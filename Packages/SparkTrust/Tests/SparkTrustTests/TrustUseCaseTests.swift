// Module: SparkTrustTests — Trust use case and wizard coverage.

import SparkTrust
import Testing

@MainActor
struct TrustUseCaseTests {
    @Test func fetchTrustProfileUseCaseReturnsMockProfile() async throws {
        let useCase = FetchTrustProfileUseCase(repository: MockTrustRepository())
        let profile = try await useCase()
        #expect(profile.completedLevels.contains(.phone))
    }

    @Test func verifyTrustLevelUseCaseCompletesPhone() async throws {
        let repository = MockTrustRepository(initialCompleted: [])
        let useCase = VerifyTrustLevelUseCase(repository: repository)
        let profile = try await useCase(.phone)
        #expect(profile.completedLevels.contains(.phone))
    }
}

@MainActor
struct TrustVerificationViewModelTests {
    @Test func loadPopulatesProfile() async {
        let viewModel = TrustVerificationViewModel(repository: MockTrustRepository())
        await viewModel.load()
        #expect(viewModel.profile != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func verifyPhoneUpdatesProfile() async {
        let viewModel = TrustVerificationViewModel(repository: MockTrustRepository(initialCompleted: []))
        await viewModel.verify(.phone)
        #expect(viewModel.profile?.completedLevels.contains(.phone) == true)
    }
}

// Module: SparkProfileTests — Profile coordinator coverage.

import SparkProfile
import SparkSearch
import SparkTrust
import Testing

@MainActor
struct ProfileCoordinatorTests {
    @Test func coordinatorBuildsProfileViewModel() {
        let coordinator = ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository()
        )
        let viewModel = coordinator.makeProfileViewModel()
        #expect(viewModel.loadState == .idle)
    }

    @Test func coordinatorExposesSearchFactory() {
        let coordinator = ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository()
        )
        _ = coordinator.makeSearchCoordinator()
    }
}

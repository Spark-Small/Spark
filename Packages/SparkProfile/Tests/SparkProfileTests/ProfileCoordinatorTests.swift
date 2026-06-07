// Module: SparkProfileTests

import SparkProfile
import SparkSearch
import SparkTrust
import Testing

@Suite struct ProfileCoordinatorTests {
    @Test @MainActor func makeProfileViewModel() {
        let coordinator = ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository()
        )
        _ = coordinator.makeProfileViewModel()
    }

    @Test func makeSearchCoordinator() {
        let coordinator = ProfileCoordinator(
            trustRepository: MockTrustRepository(),
            searchRepository: MockSearchRepository()
        )
        _ = coordinator.makeSearchCoordinator()
    }
}

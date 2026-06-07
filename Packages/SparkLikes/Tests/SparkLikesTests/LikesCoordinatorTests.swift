// Module: SparkLikesTests — Likes coordinator coverage.

@testable import SparkLikes
import Testing

@MainActor
struct LikesCoordinatorTests {
    @Test func coordinatorBuildsFeedViewModel() {
        let coordinator = LikesCoordinator(
            repository: MockLikesFeedRepository(),
            preferencesStore: InMemoryLikesPreferencesStore(),
            onboardingPreferences: InMemoryLikesOnboardingPreferences(),
            discoverMediaImageCache: DiscoverMediaImageCache.previewInstance()
        )
        let viewModel = coordinator.makeFeedViewModel()
        #expect(viewModel.loadState == .idle)
    }
}

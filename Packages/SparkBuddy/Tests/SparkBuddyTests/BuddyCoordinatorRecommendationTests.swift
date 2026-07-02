// Module: SparkBuddyTests — Cross-tab recommendation fetch.

import SparkBuddy
import Testing

struct BuddyCoordinatorRecommendationTests {
    @Test func fetchRecommendedListingMatchesServiceFilter() async {
        let coordinator = BuddyCoordinator(repository: MockBuddyRepository())
        let recommendation = await coordinator.fetchRecommendedListing(serviceFilter: .cityWalk)
        #expect(recommendation?.listingID.isEmpty == false)
        #expect(recommendation?.title.isEmpty == false)
    }

    @Test func fetchRecommendedListingForActivityCategoryReturnsNilWhenUnmapped() async {
        let coordinator = BuddyCoordinator(repository: MockBuddyRepository())
        let recommendation = await coordinator.fetchRecommendedListing(forActivityCategory: "未知分类")
        #expect(recommendation == nil)
    }
}

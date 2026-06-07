// Module: SparkCommunityTests — Community use case coverage.

@testable import SparkCommunity
import Testing

struct CommunityUseCaseTests {
    @Test func fetchCommunityPostsUseCaseReturnsSeedPosts() async throws {
        let useCase = FetchCommunityPostsUseCase(repository: MockCommunityPostsRepository())
        let posts = try await useCase()
        #expect(!posts.isEmpty)
    }

    @Test func fetchCommunityTabExperienceUseCaseReturnsFeed() async throws {
        let useCase = FetchCommunityTabExperienceUseCase(repository: MockCommunityPostsRepository())
        let tab = try await useCase()
        #expect(!tab.feedItems.isEmpty || !tab.allCommunities.isEmpty)
    }

    @Test func fetchCommunityDetailBundleUseCaseLoadsParallelData() async throws {
        let useCase = FetchCommunityDetailBundleUseCase(repository: MockCommunityPostsRepository())
        let bundle = try await useCase(communityID: "cm_hike")
        #expect(bundle.detail.id == "cm_hike")
        #expect(!bundle.members.isEmpty)
    }

    @Test func createCommunityRecapUseCaseCreatesPost() async throws {
        let useCase = CreateCommunityRecapUseCase(repository: MockCommunityPostsRepository())
        let draft = CommunityRecapDraft(
            activityID: "act_001",
            activityTitle: "Coffee",
            scheduleLine: "Friday",
            body: "Great meetup"
        )
        let detail = try await useCase(draft)
        #expect(detail.linkedActivity != nil)
    }
}

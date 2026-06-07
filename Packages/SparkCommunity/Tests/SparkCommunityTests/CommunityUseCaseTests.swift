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

    @Test func createCommunityPostUseCaseCreatesPost() async throws {
        let draft = CreateCommunityPostDraft(title: "Hello", body: "First post")
        let post = try await CreateCommunityPostUseCase(repository: MockCommunityPostsRepository())(draft)
        #expect(post.title == "Hello")
    }

    @Test func fetchCommunityPostUseCaseReturnsDetail() async throws {
        let post = try await FetchCommunityPostUseCase(repository: MockCommunityPostsRepository())(postID: "cp_1")
        #expect(post.id == "cp_1")
    }

    @Test func createCommunityReplyUseCaseAddsReply() async throws {
        let reply = try await CreateCommunityReplyUseCase(repository: MockCommunityPostsRepository())(
            postID: "cp_1",
            body: "Nice post"
        )
        #expect(reply.body == "Nice post")
    }

    @Test func reportCommunityPostUseCaseSucceeds() async throws {
        try await ReportCommunityPostUseCase(repository: MockCommunityPostsRepository())(
            postID: "cp_1",
            reason: .spam,
            detail: nil
        )
    }

    @Test func joinCommunityUseCaseMarksJoined() async throws {
        let detail = try await JoinCommunityUseCase(repository: MockCommunityPostsRepository())(
            communityID: "cm_run"
        )
        #expect(detail.isJoined)
        #expect(detail.id == "cm_run")
    }

    @Test func feedPostsExposeAuthorAvatarURL() async throws {
        let tab = try await FetchCommunityTabExperienceUseCase(repository: MockCommunityPostsRepository())()
        let posts = tab.feedItems.compactMap { item -> CommunityFeedPost? in
            guard case .post(let post) = item else { return nil }
            return post
        }
        #expect(posts.contains { $0.authorAvatarURL != nil })
    }
}

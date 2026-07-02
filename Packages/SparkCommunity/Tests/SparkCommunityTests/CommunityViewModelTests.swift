// Module: SparkCommunityTests

import Foundation
import SparkCommunity
import Testing

@MainActor
struct CommunityViewModelTests {
    @Test func loadPopulatesPostsAndTabExperience() async {
        let viewModel = CommunityViewModel(repository: MockCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.posts.count == 3)
        #expect(!viewModel.joinedCommunities.isEmpty)
        #expect(!viewModel.homeFeedPosts.isEmpty)
        #expect(!viewModel.allCommunities.isEmpty)
        #expect(!viewModel.discoverableCommunities.isEmpty)
    }

    @Test func loadFiltersUnjoinedCommunityPosts() async {
        let viewModel = CommunityViewModel(repository: MockCommunityPostsRepository())
        await viewModel.load()
        let communityNames = viewModel.homeFeedPosts.map(\.communityName)
        #expect(!communityNames.contains("晨跑打卡"))
    }

    @Test func loadEmptySetsEmptyState() async {
        let viewModel = CommunityViewModel(repository: EmptyCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .empty)
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.homeFeedPosts.isEmpty)
    }

    @Test func loadWithCommunitiesOnlySetsLoadedState() async {
        let viewModel = CommunityViewModel(repository: CommunitiesOnlyPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.homeFeedPosts.isEmpty)
        #expect(!viewModel.joinedCommunities.isEmpty)
        #expect(!viewModel.allCommunities.isEmpty)
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = CommunityViewModel(repository: FailingCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Posts unavailable"))
    }

    @Test func toggleLikePersistsThroughRepository() async {
        let repository = MockCommunityPostsRepository()
        let viewModel = CommunityViewModel(repository: repository)
        await viewModel.load()
        guard let post = viewModel.homeFeedPosts.first else {
            Issue.record("Expected feed post")
            return
        }
        let baseCount = post.likeCount
        await viewModel.toggleLike(postID: post.id)
        #expect(viewModel.isPostLiked(post.id))
        #expect(viewModel.likeCount(for: post.id) == baseCount + 1)

        await viewModel.load()
        #expect(viewModel.isPostLiked(post.id))
        #expect(viewModel.likeCount(for: post.id) == baseCount + 1)

        await viewModel.toggleLike(postID: post.id)
        #expect(!viewModel.isPostLiked(post.id))
        #expect(viewModel.likeCount(for: post.id) == baseCount)
    }

    @Test func joinCommunityUpdatesJoinedState() async {
        let repository = MockCommunityPostsRepository()
        let viewModel = CommunityDetailViewModel(communityID: "cm_run", repository: repository)
        await viewModel.load()
        #expect(viewModel.detail?.isJoined == false)
        await viewModel.join()
        #expect(viewModel.detail?.isJoined == true)
        #expect(viewModel.joinState == .idle)
    }
}

private struct CommunitiesOnlyPostsRepository: CommunityPostsRepository, Sendable {
    func fetchPosts() async throws -> [CommunityPost] { [] }

    func fetchTabExperience() async throws -> CommunityTabExperience {
        let community = CommunitySummary(
            id: "cm_only",
            name: "Only Community",
            memberCount: 3,
            activityCount: 1
        )
        return CommunityTabExperience(
            joinedCommunities: [community],
            feedItems: [],
            allCommunities: [community]
        )
    }

    func fetchPost(id: String) async throws -> CommunityPostDetail { throw TestError() }
    func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost { throw TestError() }
    func createRecapPost(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail { throw TestError() }
    func createReply(postID: String, body: String) async throws -> CommunityPostReply { throw TestError() }
    func fetchCommunityDetail(id: String) async throws -> CommunityDetail { throw TestError() }
    func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity] { [] }
    func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember] { [] }
    func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost] { [] }
    func reportPost(postID: String, reason: CommunityReportReason, detail: String?) async throws {}
    func joinCommunity(id: String) async throws -> CommunityDetail { throw TestError() }
    func setPostLike(postID: String, liked: Bool) async throws -> CommunityPostLikeResult {
        CommunityPostLikeResult(viewerHasLiked: liked, likeCount: liked ? 1 : 0)
    }

    struct TestError: LocalizedError {
        var errorDescription: String? { "Not found" }
    }
}

private struct EmptyCommunityPostsRepository: CommunityPostsRepository, Sendable {
    func fetchPosts() async throws -> [CommunityPost] { [] }

    func fetchTabExperience() async throws -> CommunityTabExperience {
        CommunityTabExperience(joinedCommunities: [], feedItems: [], allCommunities: [])
    }

    func fetchPost(id: String) async throws -> CommunityPostDetail {
        throw TestError()
    }

    func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        CommunityPost(
            id: "cp_empty",
            title: draft.title,
            excerpt: draft.body,
            authorDisplayName: "你",
            replyCount: 0
        )
    }

    func createRecapPost(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        throw TestError()
    }

    func createReply(postID: String, body: String) async throws -> CommunityPostReply {
        throw TestError()
    }

    func fetchCommunityDetail(id: String) async throws -> CommunityDetail {
        throw TestError()
    }

    func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity] {
        []
    }

    func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember] {
        []
    }

    func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost] {
        []
    }

    func reportPost(postID: String, reason: CommunityReportReason, detail: String?) async throws {}
    func joinCommunity(id: String) async throws -> CommunityDetail { throw TestError() }
    func setPostLike(postID: String, liked: Bool) async throws -> CommunityPostLikeResult {
        CommunityPostLikeResult(viewerHasLiked: liked, likeCount: liked ? 1 : 0)
    }

    struct TestError: LocalizedError {
        var errorDescription: String? { "Not found" }
    }
}

private struct FailingCommunityPostsRepository: CommunityPostsRepository, Sendable {
    struct TestError: LocalizedError {
        var errorDescription: String? { "Posts unavailable" }
    }

    func fetchPosts() async throws -> [CommunityPost] {
        throw TestError()
    }

    func fetchTabExperience() async throws -> CommunityTabExperience {
        throw TestError()
    }

    func fetchPost(id: String) async throws -> CommunityPostDetail {
        throw TestError()
    }

    func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        throw TestError()
    }

    func createRecapPost(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        throw TestError()
    }

    func createReply(postID: String, body: String) async throws -> CommunityPostReply {
        throw TestError()
    }

    func fetchCommunityDetail(id: String) async throws -> CommunityDetail {
        throw TestError()
    }

    func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity] {
        throw TestError()
    }

    func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember] {
        throw TestError()
    }

    func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost] {
        throw TestError()
    }

    func reportPost(postID: String, reason: CommunityReportReason, detail: String?) async throws {
        throw TestError()
    }

    func joinCommunity(id: String) async throws -> CommunityDetail {
        throw TestError()
    }

    func setPostLike(postID: String, liked: Bool) async throws -> CommunityPostLikeResult {
        throw TestError()
    }
}

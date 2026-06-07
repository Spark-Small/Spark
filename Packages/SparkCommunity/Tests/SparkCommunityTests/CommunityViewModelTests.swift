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
        #expect(!viewModel.feedItems.isEmpty)
        #expect(!viewModel.allCommunities.isEmpty)
    }

    @Test func loadEmptySetsEmptyState() async {
        let viewModel = CommunityViewModel(repository: EmptyCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .empty)
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.feedItems.isEmpty)
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = CommunityViewModel(repository: FailingCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Posts unavailable"))
    }

    @Test func toggleLikeUpdatesState() async {
        let viewModel = CommunityViewModel(repository: MockCommunityPostsRepository())
        await viewModel.load()
        guard case .post(let post) = viewModel.feedItems.first else {
            Issue.record("Expected feed post")
            return
        }
        let baseCount = post.likeCount
        viewModel.toggleLike(postID: post.id)
        #expect(viewModel.isPostLiked(post.id))
        #expect(viewModel.likeCount(for: post.id) == baseCount + 1)
        viewModel.toggleLike(postID: post.id)
        #expect(!viewModel.isPostLiked(post.id))
        #expect(viewModel.likeCount(for: post.id) == baseCount)
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
}

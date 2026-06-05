// Module: SparkCommunityTests

import Foundation
import SparkCommunity
import Testing

@MainActor
struct CommunityViewModelTests {
    @Test func loadPopulatesPosts() async {
        let viewModel = CommunityViewModel(repository: MockCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.posts.count == 3)
    }

    @Test func loadEmptySetsEmptyState() async {
        let viewModel = CommunityViewModel(repository: EmptyCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .empty)
        #expect(viewModel.posts.isEmpty)
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = CommunityViewModel(repository: FailingCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Posts unavailable"))
    }

    @Test func createPostPrependsFeed() async {
        let viewModel = CommunityViewModel(repository: MockCommunityPostsRepository())
        await viewModel.load()
        let created = await viewModel.createPost(CreateCommunityPostDraft(title: "新帖", body: "正文"))
        #expect(created != nil)
        #expect(viewModel.posts.first?.title == "新帖")
        #expect(viewModel.posts.count == 4)
    }
}

private struct EmptyCommunityPostsRepository: CommunityPostsRepository, Sendable {
    func fetchPosts() async throws -> [CommunityPost] { [] }

    func fetchPost(id: String) async throws -> CommunityPostDetail {
        throw EmptyCommunityPostsRepository.TestError()
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

    func fetchPost(id: String) async throws -> CommunityPostDetail {
        throw TestError()
    }

    func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        throw TestError()
    }
}

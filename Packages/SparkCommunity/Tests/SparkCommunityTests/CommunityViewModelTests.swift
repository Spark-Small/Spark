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
}

private struct EmptyCommunityPostsRepository: CommunityPostsRepository, Sendable {
    func fetchPosts() async throws -> [CommunityPost] { [] }

    func fetchPost(id: String) async throws -> CommunityPostDetail {
        throw EmptyCommunityPostsRepository.TestError()
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
}

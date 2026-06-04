// Module: SparkCommunity — Loads community posts.

import Foundation

struct FetchCommunityPostsUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [CommunityPost] {
        try await repository.fetchPosts()
    }
}

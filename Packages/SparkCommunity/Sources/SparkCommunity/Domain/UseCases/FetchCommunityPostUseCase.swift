// Module: SparkCommunity — Loads a single community post.

import Foundation

struct FetchCommunityPostUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    func callAsFunction(postID: String) async throws -> CommunityPostDetail {
        try await repository.fetchPost(id: postID)
    }
}

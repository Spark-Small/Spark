// Module: SparkCommunity — Persist viewer like state on a community post.

import Foundation

struct SetCommunityPostLikeUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    func callAsFunction(postID: String, liked: Bool) async throws -> CommunityPostLikeResult {
        try await repository.setPostLike(postID: postID, liked: liked)
    }
}

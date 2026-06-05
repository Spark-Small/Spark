// Module: SparkCommunity — Post a reply on a community thread.

import Foundation

struct CreateCommunityReplyUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    func callAsFunction(postID: String, body: String) async throws -> CommunityPostReply {
        try await repository.createReply(postID: postID, body: body)
    }
}

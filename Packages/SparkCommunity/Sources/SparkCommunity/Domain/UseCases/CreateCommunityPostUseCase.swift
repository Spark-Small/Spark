// Module: SparkCommunity — Creates a text post (MODULE-E).

import Foundation

struct CreateCommunityPostUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    func callAsFunction(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        try await repository.createPost(draft)
    }
}

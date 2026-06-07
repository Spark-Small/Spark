// Module: SparkCommunity — Publish activity recap post.

import Foundation

public struct CreateCommunityRecapUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        try CommunityRecapDraft.validate(draft)
        return try await repository.createRecapPost(draft)
    }
}

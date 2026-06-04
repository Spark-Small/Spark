// Module: SparkLikes — Fetch users who liked the viewer.

import Foundation

struct FetchInboundLikesUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    public func callAsFunction(cursor: String? = nil) async throws -> LikesInboundPage {
        try await repository.fetchInbound(cursor: cursor)
    }
}

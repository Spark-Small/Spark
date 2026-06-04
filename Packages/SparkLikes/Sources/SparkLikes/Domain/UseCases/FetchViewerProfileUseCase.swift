// Module: SparkLikes — Viewer profile for discover gate.

import Foundation

struct FetchViewerProfileUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> LikesViewerProfile {
        try await repository.fetchViewerProfile()
    }
}

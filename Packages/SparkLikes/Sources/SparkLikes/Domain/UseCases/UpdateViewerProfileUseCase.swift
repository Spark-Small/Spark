// Module: SparkLikes — Persists viewer profile for discover gate.

import Foundation

struct UpdateViewerProfileUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile {
        try await repository.updateViewerProfile(profile)
    }
}

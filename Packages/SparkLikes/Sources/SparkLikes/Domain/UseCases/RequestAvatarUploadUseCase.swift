// Module: SparkLikes — Staging avatar upload URL (MODULE-F).

import Foundation

struct RequestAvatarUploadUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(contentType: String) async throws -> URL {
        try await repository.requestAvatarUploadURL(contentType: contentType)
    }
}

// Module: SparkLikes — Records a like action.

import Foundation
import SparkCore

struct SubmitLikeUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(_ request: SendLikeRequest) async throws -> LikeActionResult {
        try await repository.submitLike(request)
    }
}

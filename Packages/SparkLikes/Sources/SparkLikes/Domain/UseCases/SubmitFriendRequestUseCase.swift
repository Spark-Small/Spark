// Module: SparkLikes — Sends friend request.

import Foundation
import SparkCore

struct SubmitFriendRequestUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(userID: UserID) async throws -> LikeActionResult {
        try await repository.submitFriendRequest(userID: userID)
    }
}

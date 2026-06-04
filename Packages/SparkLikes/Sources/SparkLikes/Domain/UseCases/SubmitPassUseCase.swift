// Module: SparkLikes — Records pass (skip).

import Foundation
import SparkCore

struct SubmitPassUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(userID: UserID) async throws {
        try await repository.submitPass(userID: userID)
    }
}

// Module: SparkLikes — Block a discover user.

import Foundation
import SparkCore

struct BlockUserUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(userID: UserID) async throws {
        try await repository.blockUser(userID: userID)
    }
}

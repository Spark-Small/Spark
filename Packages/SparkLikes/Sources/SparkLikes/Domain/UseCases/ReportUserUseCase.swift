// Module: SparkLikes — Report a discover user.

import Foundation
import SparkCore

struct ReportUserUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(userID: UserID, reason: String, detail: String?) async throws {
        try await repository.reportUser(userID: userID, reason: reason, detail: detail)
    }
}

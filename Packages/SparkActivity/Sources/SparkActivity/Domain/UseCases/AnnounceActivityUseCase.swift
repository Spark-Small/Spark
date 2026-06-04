// Module: SparkActivity — Host broadcast to attendees.

import Foundation

struct AnnounceActivityUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, message: String) async throws {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ActivityError.emptyInput }
        try ActivityContentModeration.validatePublishableText(trimmed)
        try await repository.announceActivity(activityID: activityID, message: trimmed)
    }
}

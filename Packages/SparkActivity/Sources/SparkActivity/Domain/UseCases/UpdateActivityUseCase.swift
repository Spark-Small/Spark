// Module: SparkActivity — Host edits an existing activity.

import Foundation

struct UpdateActivityUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail {
        try CreateActivityDraft.validate(draft)
        let publishDraft = draft.normalizedForPublish()
        return try await repository.updateActivity(activityID: activityID, draft: publishDraft)
    }
}

// Module: SparkActivity — Host publishes a new activity.

import Foundation

struct CreateActivityUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(draft: CreateActivityDraft) async throws -> ActivityDetail {
        try CreateActivityDraft.validate(draft)
        let publishDraft = draft.normalizedForPublish()
        return try await repository.createActivity(publishDraft)
    }
}

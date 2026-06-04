// Module: SparkActivity — Post-event host feedback.

import Foundation

struct SubmitHostFeedbackUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, feedback: ActivityHostFeedback) async throws {
        try await repository.submitHostFeedback(activityID: activityID, feedback: feedback)
    }
}

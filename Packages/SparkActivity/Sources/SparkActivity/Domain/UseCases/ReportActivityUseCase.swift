// Module: SparkActivity — Registrant reports an activity.

import Foundation

struct ReportActivityUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult {
        try await repository.reportActivity(activityID: activityID, reason: reason)
    }
}

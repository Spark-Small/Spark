// Module: SparkActivity — Other activities by the same host.

import Foundation

struct FetchActivitiesByHostUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem] {
        try await repository.fetchActivitiesByHost(hostID: hostID, excludingActivityID: excludingActivityID)
    }
}

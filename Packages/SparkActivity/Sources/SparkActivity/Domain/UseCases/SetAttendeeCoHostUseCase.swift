// Module: SparkActivity — Host assigns co-host role to attendee.

import Foundation

struct SetAttendeeCoHostUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail {
        try await repository.setAttendeeCoHost(activityID: activityID, attendeeID: attendeeID, isCoHost: isCoHost)
    }
}

// Module: SparkMessages — Accept or decline an activity invitation from inbox.

import Foundation

struct RespondToActivityInviteUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, invitationID: String, accept: Bool) async throws {
        try await repository.respondToActivityInvite(
            activityID: activityID,
            invitationID: invitationID,
            accept: accept
        )
    }
}

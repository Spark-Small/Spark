// Module: SparkMessages — Create or fetch DM thread after mutual match.

import Foundation

struct EnsureDirectMessageThreadUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        try await repository.ensureDirectMessageThread(
            peerUserID: peerUserID,
            peerDisplayName: peerDisplayName
        )
    }
}

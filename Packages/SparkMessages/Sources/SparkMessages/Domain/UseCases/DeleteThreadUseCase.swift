// Module: SparkMessages — Soft-delete conversation for current user.

import Foundation

struct DeleteThreadUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(threadID: MessageThreadID) async throws {
        try await repository.deleteThread(threadID: threadID)
    }
}

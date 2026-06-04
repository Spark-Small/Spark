// Module: SparkMessages — Loads messages for one thread.

import Foundation

struct FetchThreadMessagesUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(threadID: MessageThreadID) async throws -> [ChatMessage] {
        try await repository.fetchMessages(threadID: threadID)
    }
}

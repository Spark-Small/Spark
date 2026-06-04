// Module: SparkMessages — Sends a message in a thread.

import Foundation

struct SendThreadMessageUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(threadID: MessageThreadID, body: String) async throws -> ChatMessage {
        try await repository.sendMessage(threadID: threadID, body: body)
    }
}

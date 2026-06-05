// Module: SparkMessages — Load DM / thread context for detail header.

import Foundation

struct FetchConversationContextUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(threadID: MessageThreadID) async throws -> ConversationContext {
        try await repository.fetchConversationContext(threadID: threadID)
    }
}

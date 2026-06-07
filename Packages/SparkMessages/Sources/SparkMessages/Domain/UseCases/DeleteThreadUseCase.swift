// Module: SparkMessages — Permanently removes a conversation thread.

import Foundation

public struct DeleteThreadUseCase: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    public func callAsFunction(threadID: MessageThreadID) async throws {
        try await repository.deleteThread(threadID: threadID)
    }
}

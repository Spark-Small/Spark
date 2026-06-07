// Module: SparkMessages — Hides a conversation from the inbox list.

import Foundation

public struct HideThreadUseCase: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    public func callAsFunction(threadID: MessageThreadID) async throws {
        try await repository.hideThread(threadID: threadID)
    }
}

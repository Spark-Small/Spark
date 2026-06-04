// Module: SparkMessages — Marks all conversations as read.

import Foundation

public struct MarkMessagesReadUseCase: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws {
        try await repository.markAllRead()
    }
}

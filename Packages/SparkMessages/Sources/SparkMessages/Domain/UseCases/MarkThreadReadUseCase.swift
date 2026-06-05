// Module: SparkMessages — Marks a single conversation thread as read.

import Foundation

public struct MarkThreadReadUseCase: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    public func callAsFunction(threadID: MessageThreadID) async throws {
        try await repository.markThreadRead(threadID: threadID)
    }
}

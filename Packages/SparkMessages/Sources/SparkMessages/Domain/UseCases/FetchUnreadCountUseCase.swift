// Module: SparkMessages — Loads unread message count.

import Foundation

public struct FetchUnreadCountUseCase: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> Int {
        try await repository.fetchUnreadCount()
    }
}

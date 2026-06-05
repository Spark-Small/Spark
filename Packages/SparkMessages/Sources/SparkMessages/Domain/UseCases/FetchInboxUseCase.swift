// Module: SparkMessages — Load unified inbox payload.

import Foundation

struct FetchInboxUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> MessagesInbox {
        try await repository.fetchInbox()
    }
}

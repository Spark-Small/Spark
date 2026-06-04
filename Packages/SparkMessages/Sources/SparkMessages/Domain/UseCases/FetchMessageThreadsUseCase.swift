// Module: SparkMessages — Loads inbox threads.

import Foundation

struct FetchMessageThreadsUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [MessageThread] {
        try await repository.fetchThreads()
    }
}

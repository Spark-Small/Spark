// Module: SparkMessages — Hide conversation from inbox.

import Foundation

struct HideThreadUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(threadID: MessageThreadID) async throws {
        try await repository.hideThread(threadID: threadID)
    }
}

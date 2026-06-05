// Module: SparkMessages — Persist inbox action card dismissal.

import Foundation

struct DismissActionItemUseCase: Sendable {
    private let repository: any MessagesRepository

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func callAsFunction(actionItemID: String) async throws {
        try await repository.dismissInboxActionItem(id: actionItemID)
    }
}

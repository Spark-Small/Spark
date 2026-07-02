// Module: SparkBuddy — Creates escrow-held companion order.

import Foundation

public struct CreateBuddyOrderUseCase: CreateBuddyOrderUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository

    public init(repository: any BuddyRepository) {
        self.repository = repository
    }

    public func callAsFunction(draft: BuddyOrderDraft) async throws -> BuddyOrderConfirmation {
        try await repository.createOrder(draft: draft)
    }
}

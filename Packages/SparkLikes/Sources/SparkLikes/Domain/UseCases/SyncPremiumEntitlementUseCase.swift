// Module: SparkLikes — Sync StoreKit premium state to backend.

import Foundation

struct SyncPremiumEntitlementUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(isActive: Bool) async throws {
        try await repository.syncPremiumEntitlement(isActive: isActive)
    }
}

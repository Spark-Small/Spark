// Module: SparkBuddy — Data boundary for companion listings and orders.

import Foundation

public struct BuddyListQuery: Sendable, Equatable {
    public let serviceFilter: BuddyServiceFilter
    public let billingFilter: BuddyBillingFilter
    public let cursor: String?

    public init(
        serviceFilter: BuddyServiceFilter = .all,
        billingFilter: BuddyBillingFilter,
        cursor: String?
    ) {
        self.serviceFilter = serviceFilter
        self.billingFilter = billingFilter
        self.cursor = cursor
    }
}

public struct BuddyListPage: Sendable, Equatable {
    public let items: [BuddyListing]
    public let nextCursor: String?

    public init(items: [BuddyListing], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public protocol BuddyRepository: Sendable {
    func fetchListings(query: BuddyListQuery) async throws -> BuddyListPage
    func fetchListing(id: String) async throws -> BuddyListing
    func createOrder(draft: BuddyOrderDraft) async throws -> BuddyOrderConfirmation

    func fetchProviderStatus() async throws -> BuddyProviderStatus
    func submitProviderApplication(_ draft: BuddyProviderApplicationDraft) async throws -> BuddyProviderStatus
    func fetchProviderEarnings() async throws -> BuddyProviderEarnings
    func fetchProviderOrders() async throws -> [BuddyProviderOrder]
}

// Module: SparkBuddy — Mock listings for previews and mock API host.

import Foundation

public struct MockBuddyRepository: BuddyRepository, Sendable {
    public init() {}

    public func resetProviderStateForTesting() async {
        await MockBuddyProviderStore.shared.reset()
    }

    public func fetchListings(query: BuddyListQuery) async throws -> BuddyListPage {
        var filtered = MockBuddyCatalog.listings
        if let category = query.serviceFilter.apiCategoryValue,
           let kind = BuddyServiceCategory(apiValue: category) {
            filtered = filtered.filter { $0.serviceCategory == kind }
        }
        if let billing = query.billingFilter.apiBillingValue,
           let kind = BuddyBillingKind(apiValue: billing) {
            filtered = filtered.filter { $0.billingKind == kind }
        }
        return BuddyListPage(items: filtered, nextCursor: nil)
    }

    public func fetchListing(id: String) async throws -> BuddyListing {
        guard let listing = MockBuddyCatalog.listings.first(where: { $0.id == id }) else {
            throw BuddyError.invalidListingID
        }
        return listing
    }

    public func fetchReviews(query: BuddyReviewQuery) async throws -> BuddyReviewPage {
        guard let listing = MockBuddyCatalog.listings.first(where: { $0.id == query.listingID }) else {
            throw BuddyError.invalidListingID
        }
        return MockBuddyReviewPagination.page(for: listing, query: query)
    }

    public func createOrder(draft: BuddyOrderDraft) async throws -> BuddyOrderConfirmation {
        guard let listing = MockBuddyCatalog.listings.first(where: { $0.id == draft.listingID }) else {
            throw BuddyError.invalidListingID
        }
        guard listing.packages.contains(where: { $0.id == draft.packageID }) else {
            throw BuddyError.invalidPackageID
        }
        return BuddyOrderConfirmation(
            id: "order_mock_\(draft.listingID)",
            listingID: draft.listingID,
            packageID: draft.packageID,
            escrowHeld: true
        )
    }

    public func fetchProviderStatus() async throws -> BuddyProviderStatus {
        await MockBuddyProviderStore.shared.currentStatus()
    }

    public func submitProviderApplication(_ draft: BuddyProviderApplicationDraft) async throws -> BuddyProviderStatus {
        guard draft.isValid else { throw BuddyError.invalidApplication }
        BuddyTelemetry.providerApplicationSubmitted(category: draft.serviceCategory.rawValue)
        return await MockBuddyProviderStore.shared.submit(draft)
    }

    public func fetchProviderEarnings() async throws -> BuddyProviderEarnings {
        let status = await MockBuddyProviderStore.shared.currentStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        return BuddyProviderEarnings(
            availableBalance: 1280,
            pendingEscrow: 599,
            currencyCode: "CNY",
            completedOrderCount: 42,
            monthEarnings: 3860
        )
    }

    public func fetchProviderOrders() async throws -> [BuddyProviderOrder] {
        let status = await MockBuddyProviderStore.shared.currentStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        return [
            BuddyProviderOrder(
                id: "provider_order_1",
                guestDisplayName: "游客 A",
                packageTitle: "城市漫游",
                scheduledAt: Date().addingTimeInterval(86_400),
                amount: 299,
                currencyCode: "CNY",
                state: .upcoming
            ),
            BuddyProviderOrder(
                id: "provider_order_2",
                guestDisplayName: "游客 B",
                packageTitle: "美食陪玩",
                scheduledAt: Date().addingTimeInterval(-86_400),
                amount: 399,
                currencyCode: "CNY",
                state: .completed
            )
        ]
    }
}

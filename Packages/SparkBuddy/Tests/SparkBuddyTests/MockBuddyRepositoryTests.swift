// Module: SparkBuddyTests — Mock repository integration.

import SparkBuddy
import Testing

struct MockBuddyRepositoryTests {
    @Test func fetchListingByID() async throws {
        let repository = MockBuddyRepository()
        let listing = try await repository.fetchListing(id: "buddy_city_1")
        #expect(listing.billingKind == .daily)
        #expect(listing.serviceCategory == .cityWalk)
        #expect(listing.supportsOfflineMeetup)
    }

    @Test func createOrderReturnsEscrowConfirmation() async throws {
        let repository = MockBuddyRepository()
        let draft = BuddyOrderDraft(
            listingID: "buddy_city_1",
            packageID: "pkg_city_half_day",
            scheduledAt: .now
        )
        let confirmation = try await repository.createOrder(draft: draft)
        #expect(confirmation.escrowHeld)
        #expect(confirmation.listingID == "buddy_city_1")
    }

    @Test func createOrderInvalidPackageThrows() async {
        let repository = MockBuddyRepository()
        let draft = BuddyOrderDraft(
            listingID: "buddy_city_1",
            packageID: "missing_package",
            scheduledAt: .now
        )
        await #expect(throws: BuddyError.self) {
            _ = try await repository.createOrder(draft: draft)
        }
    }

    @Test func invalidListingThrows() async {
        let repository = MockBuddyRepository()
        await #expect(throws: BuddyError.self) {
            _ = try await repository.fetchListing(id: "missing")
        }
    }
}

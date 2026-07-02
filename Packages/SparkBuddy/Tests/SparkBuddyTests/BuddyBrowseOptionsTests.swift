// Module: SparkBuddyTests — Browse options client filtering.

@testable import SparkBuddy
import Testing

struct BuddyBrowseOptionsTests {
    @Test func verifiedOnlyFiltersListings() {
        let listings = [
            verifiedListing(id: "a"),
            unverifiedListing(id: "b")
        ]
        let filtered = BuddyViewModel.filterAndSort(
            listings,
            options: BuddyBrowseOptions(verifiedOnly: true)
        )
        #expect(filtered.count == 1)
        #expect(filtered.first?.id == "a")
    }

    @Test func sortByMatchDescending() {
        let listings = [
            listing(id: "low", match: 70),
            listing(id: "high", match: 95)
        ]
        let sorted = BuddyViewModel.filterAndSort(
            listings,
            options: BuddyBrowseOptions(sortOrder: .match)
        )
        #expect(sorted.first?.id == "high")
    }

    private func verifiedListing(id: String) -> BuddyListing {
        listing(id: id, match: 80, isVerified: true)
    }

    private func unverifiedListing(id: String) -> BuddyListing {
        listing(id: id, match: 80, isVerified: false)
    }

    private func listing(id: String, match: Int, isVerified: Bool = true) -> BuddyListing {
        BuddyListing(
            id: id,
            ownerUserID: "user_\(id)",
            displayName: "Test",
            avatarURL: nil,
            coverURL: nil,
            headline: "Headline",
            city: "成都",
            serviceCategory: .cityWalk,
            billingKind: .hourly,
            priceAmount: 100,
            priceCurrencyCode: "CNY",
            tags: ["tag"],
            rating: 4.5,
            reviewCount: 10,
            isVerified: isVerified,
            supportsOfflineMeetup: true,
            supportsPaidCompanion: true,
            matchInsight: BuddyMatchInsight(matchPercent: match, reason: "test")
        )
    }
}

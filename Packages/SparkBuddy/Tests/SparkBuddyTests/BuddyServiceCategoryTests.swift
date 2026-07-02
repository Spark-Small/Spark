// Module: SparkBuddyTests — Service category mapping.

import SparkBuddy
import Testing

struct BuddyServiceCategoryTests {
    @Test func apiValueRoundTrip() {
        for category in BuddyServiceCategory.allCases {
            #expect(BuddyServiceCategory(apiValue: category.apiValue) == category)
        }
    }

    @Test func serviceFilterMapsToCategory() {
        #expect(BuddyServiceFilter.cityWalk.category == .cityWalk)
        #expect(BuddyServiceFilter.all.category == nil)
        #expect(BuddyServiceFilter.food.apiCategoryValue == "food")
    }
}

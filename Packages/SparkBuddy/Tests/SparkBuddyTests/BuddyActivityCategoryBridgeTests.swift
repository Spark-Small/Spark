// Module: SparkBuddyTests — Activity category → buddy filter bridge.

import SparkBuddy
import Testing

struct BuddyActivityCategoryBridgeTests {
    @Test func mapsOutdoorToSports() {
        #expect(BuddyActivityCategoryBridge.serviceFilter(forActivityCategory: "户外") == .sports)
    }

    @Test func mapsFoodSynonyms() {
        #expect(BuddyActivityCategoryBridge.serviceFilter(forActivityCategory: "饭搭子") == .food)
    }

    @Test func unknownCategoryReturnsNil() {
        #expect(BuddyActivityCategoryBridge.serviceFilter(forActivityCategory: "随机") == nil)
    }
}

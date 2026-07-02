// Module: SparkBuddyTests — Billing kind display.

import SparkBuddy
import Testing

struct BuddyBillingKindTests {
    @Test func hourlyTitle() {
        #expect(BuddyBillingKind.hourly.localizedTitle == "按小时")
    }

    @Test func dailyUnitSuffix() {
        #expect(BuddyBillingKind.daily.localizedUnitSuffix == "/天")
    }

    @Test func perProjectFilterMapsAPIValue() {
        #expect(BuddyBillingFilter.perProject.apiBillingValue == "per_project")
    }
}

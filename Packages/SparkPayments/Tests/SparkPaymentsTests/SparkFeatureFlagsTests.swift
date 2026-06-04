// Module: SparkPaymentsTests

import SparkPayments
import Testing

struct SparkFeatureFlagsTests {
    @Test func premiumPaywallEnabledByDefault() {
        #expect(SparkFeatureFlags.isPremiumPaywallEnabled == true)
    }
}

// Module: SparkPaymentsTests

import SparkPayments
import Testing

struct SparkFeatureFlagsTests {
    @Test func premiumPaywallEnabledByDefault() {
        #expect(SparkFeatureFlags.isPremiumPaywallEnabled == true)
    }

    @Test func buddyVoicePreChatDisabledByDefault() {
        #expect(SparkFeatureFlags.isBuddyVoicePreChatEnabled == false)
    }

    @Test func buddyEscrowPaymentDisabledByDefault() {
        #expect(SparkFeatureFlags.isBuddyEscrowPaymentEnabled == false)
    }
}

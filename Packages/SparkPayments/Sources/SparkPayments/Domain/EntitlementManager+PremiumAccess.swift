// Module: SparkPayments — Premium gating helpers.

import Foundation

public extension EntitlementManager {
    /// Premium status used for gating; respects `SparkFeatureFlags.isPremiumPaywallEnabled`.
    var effectiveHasPremium: Bool {
        guard SparkFeatureFlags.isPremiumPaywallEnabled else { return true }
        return hasPremium
    }

    /// Whether the user may use a premium capability without seeing the paywall.
    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .fullActivityFeed:
            effectiveHasPremium
        }
    }
}

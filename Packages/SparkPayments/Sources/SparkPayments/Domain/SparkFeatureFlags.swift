// Module: SparkPayments — Remote-configurable kill switches (Info.plist defaults).

import Foundation

public enum SparkFeatureFlags: Sendable {
    private static let premiumPaywallEnabledKey = "SPARKPremiumPaywallEnabled"
    private static let premiumInboundBlurEnabledKey = "SPARKPremiumInboundBlurEnabled"

    /// When `false`, paywall UI is hidden and `EntitlementManager.canAccess` treats everyone as premium.
    public static var isPremiumPaywallEnabled: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: premiumPaywallEnabledKey) else {
            return true
        }
        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            return (string as NSString).boolValue
        }
        return true
    }

    /// When `false`, inbound likes are never blurred regardless of subscription.
    public static var isPremiumInboundBlurEnabled: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: premiumInboundBlurEnabledKey) else {
            return true
        }
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String { return (string as NSString).boolValue }
        return true
    }
}

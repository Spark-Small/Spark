// Module: SparkPayments — Remote-configurable kill switches (Info.plist defaults).

import Foundation

public enum SparkFeatureFlags: Sendable {
    private static let premiumPaywallEnabledKey = "SPARKPremiumPaywallEnabled"

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

    /// When `false`, community post composer FAB is hidden (MODULE-E compliance).
    public static var isCommunityPostingEnabled: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SPARKCommunityPostingEnabled") else {
            return true
        }
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String { return (string as NSString).boolValue }
        return true
    }
}

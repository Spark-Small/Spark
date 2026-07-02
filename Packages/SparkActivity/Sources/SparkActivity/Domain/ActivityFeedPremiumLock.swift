// Module: SparkActivity — Premium row gating for discover/inbox feeds.

/// Premium lock rule for activity list feeds (discover + inbox).
///
/// REASONING: First row stays readable for conversion; index > 0 requires full feed access
/// when the paywall flag is enabled (`docs/TAB_SCREENS.md`).
public enum ActivityFeedPremiumLock {
    public static func isRowLocked(
        at index: Int,
        isPaywallEnabled: Bool,
        hasFullFeedAccess: Bool
    ) -> Bool {
        isPaywallEnabled && !hasFullFeedAccess && index > 0
    }
}

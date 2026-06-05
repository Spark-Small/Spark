// Module: SparkPayments — Premium-gated product capabilities.

import Foundation

public enum PremiumFeature: Sendable {
    /// Browse and open all activity rows (non-subscribers see only the first row).
    case fullActivityFeed
    /// See inbound like identities without blur (ADR-0004).
    case inboundLikes
}

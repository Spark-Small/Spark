// Module: SparkPayments — Subscription entitlement identifiers.

import Foundation

public enum SubscriptionEntitlement: String, Sendable, CaseIterable {
    case premium
}

public enum SubscriptionProductID: String, Sendable, CaseIterable {
    case premiumMonthly = "com.sparksmall.spark.premium.monthly"
    case premiumYearly = "com.sparksmall.spark.premium.yearly"

    public static var allIDs: [String] {
        allCases.map(\.rawValue)
    }
}

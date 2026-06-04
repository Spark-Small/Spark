// Module: SparkPayments — Deterministic StoreKit double for previews and tests.

import Foundation

public actor MockStoreKitService: StoreKitServing {
    public var purchasedProductIDs: Set<String>
    public var availableProducts: [StoreProduct]
    public var shouldFailPurchase: Bool

    public init(
        purchasedProductIDs: Set<String> = [],
        shouldFailPurchase: Bool = false
    ) {
        self.purchasedProductIDs = purchasedProductIDs
        self.shouldFailPurchase = shouldFailPurchase
        self.availableProducts = [
            StoreProduct(
                id: SubscriptionProductID.premiumMonthly.rawValue,
                displayName: "Spark Premium",
                displayPrice: "¥18.00/月"
            ),
            StoreProduct(
                id: SubscriptionProductID.premiumYearly.rawValue,
                displayName: "Spark Premium Annual",
                displayPrice: "¥128.00/年"
            ),
        ]
    }

    public func loadProducts(ids: [String]) async throws -> [StoreProduct] {
        availableProducts.filter { ids.contains($0.id) }
    }

    public func purchase(productID: String) async throws {
        if shouldFailPurchase {
            throw PaymentsError.userCancelled
        }
        purchasedProductIDs.insert(productID)
    }

    public func restorePurchases() async throws {}

    public func currentEntitlementProductIDs() async -> Set<String> {
        purchasedProductIDs
    }
}

// Module: SparkPaymentsTests

import SparkPayments
import Testing

@MainActor
struct EntitlementManagerTests {
    @Test func purchaseGrantsPremium() async {
        let store = MockStoreKitService()
        let manager = EntitlementManager(storeKit: store)
        await manager.refresh()
        guard let product = manager.products.first else {
            Issue.record("Expected mock products")
            return
        }
        await manager.purchase(product)
        #expect(manager.hasPremium)
        #expect(manager.canAccess(.hostTools))
    }

    @Test func restoreSyncsEntitlements() async {
        let store = MockStoreKitService(
            purchasedProductIDs: [SubscriptionProductID.premiumMonthly.rawValue]
        )
        let manager = EntitlementManager(storeKit: store)
        await manager.restorePurchases()
        #expect(manager.hasPremium)
    }

    @Test func canAccessFullFeedWhenNotPremium() async {
        let manager = EntitlementManager(storeKit: MockStoreKitService())
        await manager.refresh()
        #expect(!manager.canAccess(.hostTools))
    }
}

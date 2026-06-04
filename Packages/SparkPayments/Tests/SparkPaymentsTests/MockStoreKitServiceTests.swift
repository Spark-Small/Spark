// Module: SparkPaymentsTests

import SparkPayments
import Testing

struct MockStoreKitServiceTests {
    @Test func purchaseUpdatesEntitlements() async throws {
        let service = MockStoreKitService()
        try await service.purchase(productID: SubscriptionProductID.premiumMonthly.rawValue)
        let ids = await service.currentEntitlementProductIDs()
        #expect(ids.contains(SubscriptionProductID.premiumMonthly.rawValue))
    }
}

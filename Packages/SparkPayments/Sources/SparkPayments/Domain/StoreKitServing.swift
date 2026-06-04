// Module: SparkPayments — StoreKit abstraction for Live and Mock implementations.

import Foundation

public protocol StoreKitServing: Sendable {
    func loadProducts(ids: [String]) async throws -> [StoreProduct]
    func purchase(productID: String) async throws
    func restorePurchases() async throws
    func currentEntitlementProductIDs() async -> Set<String>
}

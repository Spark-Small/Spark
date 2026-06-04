// Module: SparkPayments — Tracks active subscription entitlements.

import Foundation
import Observation

@MainActor
@Observable
public final class EntitlementManager {
    public private(set) var activeEntitlements: Set<SubscriptionEntitlement> = []
    public private(set) var products: [StoreProduct] = []
    public private(set) var isLoading = false
    public private(set) var lastErrorMessage: String?

    private let storeKit: any StoreKitServing

    public init(storeKit: any StoreKitServing) {
        self.storeKit = storeKit
    }

    public var hasPremium: Bool {
        activeEntitlements.contains(.premium)
    }

    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await storeKit.loadProducts(ids: SubscriptionProductID.allIDs)
            try await syncEntitlements()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func purchase(_ product: StoreProduct) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await storeKit.purchase(productID: product.id)
            try await syncEntitlements()
            lastErrorMessage = nil
        } catch PaymentsError.userCancelled {
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await storeKit.restorePurchases()
            try await syncEntitlements()
            products = try await storeKit.loadProducts(ids: SubscriptionProductID.allIDs)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func syncEntitlements() async throws {
        let productIDs = await storeKit.currentEntitlementProductIDs()
        var entitlements = Set<SubscriptionEntitlement>()
        if productIDs.contains(where: { id in
            SubscriptionProductID.allIDs.contains(id)
        }) {
            entitlements.insert(.premium)
        }
        activeEntitlements = entitlements
    }
}

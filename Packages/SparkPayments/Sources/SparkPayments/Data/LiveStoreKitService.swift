// Module: SparkPayments — StoreKit 2 implementation.

import Foundation
import StoreKit

public actor LiveStoreKitService: StoreKitServing {
    public init() {}

    public func loadProducts(ids: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: Set(ids))
        return products.map {
            StoreProduct(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice)
        }
    }

    public func purchase(productID: String) async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw PaymentsError.productNotFound
        }
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            let transaction = try Self.verify(verification)
            await transaction.finish()
        case .userCancelled:
            throw PaymentsError.userCancelled
        case .pending:
            throw PaymentsError.pending
        @unknown default:
            throw PaymentsError.underlying(.unknown(message: "Unknown purchase result"))
        }
    }

    public func restorePurchases() async throws {
        try await AppStore.sync()
    }

    public func currentEntitlementProductIDs() async -> Set<String> {
        var ids = Set<String>()
        for await verification in Transaction.currentEntitlements {
            // REASONING: Skip unverified StoreKit payloads when building the entitlement set.
            if let transaction = try? Self.verify(verification) {
                ids.insert(transaction.productID)
            }
        }
        return ids
    }

    private static func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(safe):
            return safe
        case .unverified:
            throw PaymentsError.verificationFailed
        }
    }
}

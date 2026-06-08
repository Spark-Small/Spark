// Module: SparkPayments — Tracks active subscription entitlements.

import Foundation
import Observation

@MainActor
@Observable
public final class EntitlementManager {
    private static let cnPremiumDefaultsKey = "spark.cnPremiumActive"

    public private(set) var activeEntitlements: Set<SubscriptionEntitlement> = []
    public private(set) var products: [StoreProduct] = []
    public private(set) var isLoading = false
    public private(set) var lastErrorMessage: String?

    private let storeKit: any StoreKitServing
    private let paymentRepository: (any PaymentRepository)?
    private let cnPaymentCoordinators: CNPaymentCoordinators?

    public init(
        storeKit: any StoreKitServing,
        paymentRepository: (any PaymentRepository)? = nil,
        cnPaymentCoordinators: CNPaymentCoordinators? = nil
    ) {
        self.storeKit = storeKit
        self.paymentRepository = paymentRepository
        self.cnPaymentCoordinators = cnPaymentCoordinators
    }

    public var hasPremium: Bool {
        activeEntitlements.contains(.premium)
    }

    public var supportsCNPayments: Bool {
        SparkFeatureFlags.isCNPaymentsEnabled
            && paymentRepository != nil
            && cnPaymentCoordinators != nil
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

    public func purchaseWithCN(provider: CNPaymentProvider, productID: String) async {
        guard supportsCNPayments,
              let paymentRepository,
              let cnPaymentCoordinators else {
            lastErrorMessage = PaymentsError.cnPaymentUnavailable.errorDescription
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let order = try await paymentRepository.createOrder(productID: productID, provider: provider)
            let receipt: CNPaymentReceipt
            switch provider {
            case .wechat:
                receipt = try await cnPaymentCoordinators.weChat.pay(order: order)
            case .alipay:
                receipt = try await cnPaymentCoordinators.alipay.pay(order: order)
            }
            let confirmation = try await paymentRepository.confirmPayment(receipt)
            if confirmation.isPremiumActive {
                setCNPremiumGranted(true)
            }
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

    public func handleOpenURL(_ url: URL) -> Bool {
        guard let cnPaymentCoordinators else { return false }
        return cnPaymentCoordinators.weChat.handleOpenURL(url)
            || cnPaymentCoordinators.alipay.handleOpenURL(url)
    }

    private func syncEntitlements() async throws {
        let productIDs = await storeKit.currentEntitlementProductIDs()
        var entitlements = Set<SubscriptionEntitlement>()
        if productIDs.contains(where: { id in
            SubscriptionProductID.allIDs.contains(id)
        }) {
            entitlements.insert(.premium)
        }
        if cnPremiumGranted {
            entitlements.insert(.premium)
        }
        activeEntitlements = entitlements
    }

    private var cnPremiumGranted: Bool {
        UserDefaults.standard.bool(forKey: Self.cnPremiumDefaultsKey)
    }

    private func setCNPremiumGranted(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: Self.cnPremiumDefaultsKey)
    }
}

// Module: SparkPayments — Deterministic payment double for previews and tests.

import Foundation

public struct MockPaymentRepository: PaymentRepository {
    public init() {}

    public func createOrder(productID: String, provider: CNPaymentProvider) async throws -> CNPaymentOrder {
        CNPaymentOrder(
            orderID: "staging-order-\(provider.rawValue)",
            provider: provider,
            productID: productID,
            payload: CNPaymentOrderPayload(
                partnerID: provider == .wechat ? "staging-partner" : nil,
                prepayID: provider == .wechat ? "staging-prepay" : nil,
                orderString: provider == .alipay ? "staging-alipay-order" : nil
            )
        )
    }

    public func confirmPayment(_ receipt: CNPaymentReceipt) async throws -> CNPaymentConfirmation {
        CNPaymentConfirmation(orderID: receipt.orderID, isPremiumActive: true)
    }
}

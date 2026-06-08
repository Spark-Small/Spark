// Module: SparkPayments — Server-side CN payment order API.

import Foundation

public protocol PaymentRepository: Sendable {
    func createOrder(productID: String, provider: CNPaymentProvider) async throws -> CNPaymentOrder
    func confirmPayment(_ receipt: CNPaymentReceipt) async throws -> CNPaymentConfirmation
}

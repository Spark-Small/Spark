// Module: SparkPayments — Live payment order API.

import Foundation
import SparkNetworking

public struct LivePaymentRepository: PaymentRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func createOrder(productID: String, provider: CNPaymentProvider) async throws -> CNPaymentOrder {
        let body = try JSONEncoder().encode(
            CreatePaymentOrderRequestDTO(productID: productID, provider: provider)
        )
        let response: CreatePaymentOrderResponseDTO = try await apiClient.post(
            PaymentAPIPath.orders,
            body: body
        )
        return CNPaymentOrder(
            orderID: response.orderID,
            provider: response.provider,
            productID: response.productID,
            payload: response.payload
        )
    }

    public func confirmPayment(_ receipt: CNPaymentReceipt) async throws -> CNPaymentConfirmation {
        let body = try JSONEncoder().encode(
            ConfirmPaymentRequestDTO(
                orderID: receipt.orderID,
                provider: receipt.provider,
                receipt: receipt.receipt
            )
        )
        let response: ConfirmPaymentResponseDTO = try await apiClient.post(
            PaymentAPIPath.confirm,
            body: body
        )
        return CNPaymentConfirmation(
            orderID: response.orderID,
            isPremiumActive: response.isPremium
        )
    }
}

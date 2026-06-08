// Module: SparkPayments — Payment HTTP DTOs.

import Foundation

struct CreatePaymentOrderRequestDTO: Encodable {
    let productID: String
    let provider: CNPaymentProvider

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case provider
    }
}

struct CreatePaymentOrderResponseDTO: Decodable {
    let orderID: String
    let provider: CNPaymentProvider
    let productID: String
    let payload: CNPaymentOrderPayload

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case provider
        case productID = "product_id"
        case payload
    }
}

struct ConfirmPaymentRequestDTO: Encodable {
    let orderID: String
    let provider: CNPaymentProvider
    let receipt: String

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case provider
        case receipt
    }
}

struct ConfirmPaymentResponseDTO: Decodable {
    let orderID: String
    let status: String
    let isPremium: Bool

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case status
        case isPremium = "is_premium"
    }
}

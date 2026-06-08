// Module: SparkPayments — CN payment order and receipt models.

import Foundation

public struct CNPaymentOrderPayload: Sendable, Equatable, Codable {
    public let partnerID: String?
    public let prepayID: String?
    public let packageValue: String?
    public let nonceStr: String?
    public let timestamp: String?
    public let sign: String?
    /// Alipay order string passed to the SDK.
    public let orderString: String?

    public init(
        partnerID: String? = nil,
        prepayID: String? = nil,
        packageValue: String? = nil,
        nonceStr: String? = nil,
        timestamp: String? = nil,
        sign: String? = nil,
        orderString: String? = nil
    ) {
        self.partnerID = partnerID
        self.prepayID = prepayID
        self.packageValue = packageValue
        self.nonceStr = nonceStr
        self.timestamp = timestamp
        self.sign = sign
        self.orderString = orderString
    }

    enum CodingKeys: String, CodingKey {
        case partnerID = "partner_id"
        case prepayID = "prepay_id"
        case packageValue = "package"
        case nonceStr = "nonce_str"
        case timestamp
        case sign
        case orderString = "order_string"
    }
}

public struct CNPaymentOrder: Sendable, Equatable {
    public let orderID: String
    public let provider: CNPaymentProvider
    public let productID: String
    public let payload: CNPaymentOrderPayload

    public init(
        orderID: String,
        provider: CNPaymentProvider,
        productID: String,
        payload: CNPaymentOrderPayload
    ) {
        self.orderID = orderID
        self.provider = provider
        self.productID = productID
        self.payload = payload
    }
}

public struct CNPaymentReceipt: Sendable, Equatable {
    public let orderID: String
    public let provider: CNPaymentProvider
    public let receipt: String

    public init(orderID: String, provider: CNPaymentProvider, receipt: String) {
        self.orderID = orderID
        self.provider = provider
        self.receipt = receipt
    }
}

public struct CNPaymentConfirmation: Sendable, Equatable {
    public let orderID: String
    public let isPremiumActive: Bool

    public init(orderID: String, isPremiumActive: Bool) {
        self.orderID = orderID
        self.isPremiumActive = isPremiumActive
    }
}

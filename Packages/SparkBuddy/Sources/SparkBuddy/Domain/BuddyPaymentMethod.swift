// Module: SparkBuddy — Escrow payment channel selection.

import Foundation

public enum BuddyPaymentMethod: String, CaseIterable, Sendable, Equatable, Identifiable {
    case wechatPay
    case alipay

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .wechatPay:
            String(localized: "buddy.payment.wechat", defaultValue: "微信支付", comment: "WeChat Pay")
        case .alipay:
            String(localized: "buddy.payment.alipay", defaultValue: "支付宝", comment: "Alipay")
        }
    }

    public var systemImage: String {
        switch self {
        case .wechatPay: "message.fill"
        case .alipay: "wallet.pass.fill"
        }
    }

    public var apiValue: String {
        switch self {
        case .wechatPay: "wechat_pay"
        case .alipay: "alipay"
        }
    }
}

public struct BuddyPaymentResult: Equatable, Sendable {
    public let transactionID: String
    public let method: BuddyPaymentMethod
    public let succeeded: Bool

    public init(transactionID: String, method: BuddyPaymentMethod, succeeded: Bool) {
        self.transactionID = transactionID
        self.method = method
        self.succeeded = succeeded
    }
}

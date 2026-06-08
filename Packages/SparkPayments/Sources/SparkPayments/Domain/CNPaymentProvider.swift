// Module: SparkPayments — CN payment provider identifiers.

import Foundation

public enum CNPaymentProvider: String, Sendable, Codable, CaseIterable, Equatable {
    case wechat
    case alipay
}

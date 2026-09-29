//
//  BookingPaymentPolicy.swift
//  CoordinateDomain
//

import Foundation

public enum BookingPaymentPolicy: Sendable {
    /// 接单后须在此时间内完成支付，否则订单自动释放（对齐 B-31「请在 X 前支付」）。
    public static let paymentWindow: TimeInterval = 24 * 60 * 60

    public static func paymentDueDate(from acceptedAt: Date) -> Date {
        acceptedAt.addingTimeInterval(paymentWindow)
    }
}

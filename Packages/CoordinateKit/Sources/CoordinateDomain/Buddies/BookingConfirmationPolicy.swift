//
//  BookingConfirmationPolicy.swift
//  CoordinateDomain
//

import Foundation

public enum BookingConfirmationPolicy: Sendable {
    /// 提交后陪玩须在此时间内确认接单（对齐 B-30 SLA 预期）。
    public static let confirmationWindow: TimeInterval = 30 * 60

    public static func confirmDueDate(from bookedAt: Date) -> Date {
        bookedAt.addingTimeInterval(confirmationWindow)
    }
}

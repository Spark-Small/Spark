//
//  ProfileMyCompanionsStatus.swift
//  坐标系
//
//  「我的陪玩」角标与分类：角标直接用 `BookingOrderStatus` 产品词；
//  「已结束」含终态与档期已过。
//

import Foundation
import CoordinateModels

@MainActor
enum ProfileMyCompanionsStatusPresentation {
    /// 场次卡左上角标：与订单状态词一致（待确认 / 待支付 / 进行中…）。
    static func badge(for record: BuddyBookingRecord) -> String {
        record.statusLabel
    }

    static func isPast(_ record: BuddyBookingRecord, now: Date = .now) -> Bool {
        switch record.status {
        case .completed, .refunded, .cancelled:
            return true
        case .pendingConfirm, .awaitingPayment, .paid, .inProgress, .refunding:
            return record.endAt <= now
        }
    }

    static func matches(_ record: BuddyBookingRecord, category: ProfileMyCompanionsCopy.Category, now: Date = .now) -> Bool {
        switch category {
        case .upcoming:
            return !isPast(record, now: now)
        case .pending:
            return record.status == .pendingConfirm || record.status == .awaitingPayment
        case .active:
            return record.status == .paid
                || record.status == .inProgress
                || record.status == .refunding
        case .past:
            return isPast(record, now: now)
        }
    }
}

//
//  BuddiesModel+CompanionReviews.swift
//  坐标系
//
//  陪玩口碑门控：已完成预约 → 订单凭证写评价；一单一评。
//

import Foundation
import CoordinateModels

extension BuddiesModel {
    func companionReviewTarget(for record: BuddyBookingRecord) -> PlatformReviewTarget? {
        guard case .paid(let companion) = item(
            for: record.companionNickname,
            userID: record.companionUserID
        ) else { return nil }
        return .companion(companion.id)
    }

    func canWriteCompanionReview(for record: BuddyBookingRecord) -> Bool {
        guard record.status == .completed else { return false }
        guard let target = companionReviewTarget(for: record) else { return false }
        return !PlatformReviewsStore.hasReview(forBookingID: record.id, target: target)
    }

    func companionReviewServiceTitle(for record: BuddyBookingRecord) -> String {
        if let slot = record.selectedSlotLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !slot.isEmpty {
            return slot
        }
        return "陪玩预约 · \(record.hours) 小时"
    }
}

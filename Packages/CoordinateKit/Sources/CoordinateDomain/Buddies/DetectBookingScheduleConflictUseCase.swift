//
//  DetectBookingScheduleConflictUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct DetectBookingScheduleConflictUseCase: Sendable {
    public init() {}

    public func hasConflict(
        candidate: BuddyBookingRecord,
        existing: [BuddyBookingRecord],
        excluding: UUID? = nil
    ) -> Bool {
        let range = candidate.scheduledAt..<candidate.endAt
        return existing.contains { other in
            guard other.id != excluding,
                  other.companionNickname == candidate.companionNickname,
                  ![BookingOrderStatus.cancelled, .refunded, .refunding].contains(other.status)
            else { return false }
            let otherRange = other.scheduledAt..<other.endAt
            return range.overlaps(otherRange)
        }
    }
}

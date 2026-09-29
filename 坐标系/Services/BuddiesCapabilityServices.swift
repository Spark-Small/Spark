//
//  BuddiesCapabilityServices.swift
//  坐标系
//

import Foundation
import CoordinateDomain
import CoordinateModels

protocol BuddyInviteService {
    func createInvite(nickname: String, activity: Activity) -> BuddyInviteRecord
    func advanceInvite(_ record: BuddyInviteRecord, to status: BuddyInviteStatus) -> BuddyInviteRecord
}

protocol BuddyBookingService {
    func createBooking(
        companion: PaidCompanion,
        scheduledAt: Date,
        hours: Int,
        slotLabel: String?
    ) -> BuddyBookingRecord

    func rescheduleBooking(
        _ record: BuddyBookingRecord,
        scheduledAt: Date,
        hours: Int,
        hourlyPrice: Int?
    ) -> BuddyBookingRecord
}

struct LocalBuddyInviteService: BuddyInviteService {
    func createInvite(nickname: String, activity: Activity) -> BuddyInviteRecord {
        BuddyInviteRecord(
            id: UUID(),
            nickname: nickname,
            activityTitle: activity.title,
            sentAt: .now,
            status: .pending,
            relatedActivityID: activity.id
        )
    }

    func advanceInvite(_ record: BuddyInviteRecord, to status: BuddyInviteStatus) -> BuddyInviteRecord {
        var next = record
        next.status = status
        return next
    }
}

struct LocalBuddyBookingService: BuddyBookingService {
    func createBooking(
        companion: PaidCompanion,
        scheduledAt: Date,
        hours: Int,
        slotLabel: String?
    ) -> BuddyBookingRecord {
        let bookedAt = Date.now
        return BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion.profile.nickname,
            hours: hours,
            scheduledAt: scheduledAt,
            bookedAt: bookedAt,
            priceText: "¥\(companion.hourlyPrice * hours)",
            status: .pendingConfirm,
            confirmDueAt: BookingConfirmationPolicy.confirmDueDate(from: bookedAt),
            selectedSlotLabel: slotLabel
        )
    }

    func rescheduleBooking(
        _ record: BuddyBookingRecord,
        scheduledAt: Date,
        hours: Int,
        hourlyPrice: Int?
    ) -> BuddyBookingRecord {
        var next = record
        next.scheduledAt = scheduledAt
        next.hours = hours
        if let hourlyPrice {
            next.priceText = "¥\(hourlyPrice * hours)"
        }
        return next
    }
}

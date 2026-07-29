//
//  BuddiesCapabilityServices.swift
//  坐标系
//

import Foundation

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

    func advanceBooking(
        _ record: BuddyBookingRecord,
        to status: BookingOrderStatus
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
        BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion.profile.nickname,
            hours: hours,
            scheduledAt: scheduledAt,
            bookedAt: .now,
            priceText: "¥\(companion.hourlyPrice * hours)",
            status: .pendingConfirm,
            selectedSlotLabel: slotLabel
        )
    }

    func advanceBooking(
        _ record: BuddyBookingRecord,
        to status: BookingOrderStatus
    ) -> BuddyBookingRecord {
        var next = record
        next.status = status
        switch status {
        case .paid:
            next.paidAt = next.paidAt ?? .now
            next.paymentMethod = "simulated"
        case .completed:
            next.completedAt = .now
        default:
            break
        }
        return next
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

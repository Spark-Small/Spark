//
//  BuddiesModel+Bookings.swift
//  坐标系
//
//  预约入口与待确认编排：下单、接单/拒单、进入支付。
//  支付确认 / 履约 / 退款 / 改期见 `BuddiesModel+BookingFulfillment`。
//

import CoordinateDomain
import CoordinateFeatureFlags
import Foundation
import CoordinateModels

extension BuddiesModel {
    func book(
        _ companion: PaidCompanion,
        initialDay: Date? = nil,
        serviceSKU: BuddyCompanionServiceSKU? = nil
    ) {
        if YouthModePreference.isEnabled {
            flash(CommerceAccessCopy.youthCommerceReason)
            return
        }
        presentation.bookingPresentation = BuddyBookingPresentation(
            companion: companion,
            initialDay: initialDay,
            serviceSKU: serviceSKU,
            token: UUID()
        )
    }

    func dismissBookingPresentation() {
        presentation.bookingPresentation = nil
    }

    @discardableResult
    func recordBooking(
        companion: PaidCompanion,
        scheduledAt: Date,
        hours: Int,
        slotLabel: String? = nil
    ) -> BuddyBookingRecord? {
        let candidate = bookingService.createBooking(
            companion: companion,
            scheduledAt: scheduledAt,
            hours: hours,
            slotLabel: slotLabel
        )
        if booking.scheduleConflict.hasConflict(candidate: candidate, existing: bookingRecords) {
            flash(BuddyBookingFlowCopy.conflictHint)
            return nil
        }
        bookingRecords.insert(candidate, at: 0)
        presentation.bookingPresentation = nil
        presentation.pendingBookingAcknowledgementID = candidate.id
        trustService.record(
            .bookingCreated,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: candidate.companionNickname
        )
        persist()
        onRecordsChanged?()
        scheduleBookingConfirmationLifecycle(for: candidate.id)
        if remoteBookingSync.isEnabled {
            startRemoteBookingPolling(for: candidate.id)
            Task { await submitBookingToRemote(candidate.id) }
        } else {
            scheduleCompanionAcceptSimulation(for: candidate.id)
        }
        return candidate
    }

    var pendingBookingAcknowledgement: BuddyBookingRecord? {
        guard let id = presentation.pendingBookingAcknowledgementID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    func dismissBookingAcknowledgement() {
        presentation.pendingBookingAcknowledgementID = nil
    }

    func dismissBookingSuccess() {
        presentation.pendingBookingSuccessID = nil
    }

    func simulateCompanionAcceptsIfNeeded() {
        guard FeatureFlags.simulateBookingCompanionAcceptance else { return }
        for record in bookingRecords where record.status == .pendingConfirm {
            let age = Date.now.timeIntervalSince(record.bookedAt)
            if age > 4, age < 180 {
                acceptBooking(record.id)
            }
        }
    }

    func acceptBooking(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .accept) != nil else { return }
        completeCompanionAcceptance(for: id)
    }

    func declineBooking(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .decline) != nil else { return }
        completeCompanionDecline(for: id)
    }

    func beginPayment(_ id: BuddyBookingRecord.ID) {
        guard case .success = booking.applyTransition.apply(
            bookingRecords.first(where: { $0.id == id }),
            transition: .beginPayment
        ) else {
            flash(BuddyBookingFlowCopy.orderNotPayableYet)
            return
        }
        presentation.pendingAwaitingPaymentReviewID = nil
        presentation.pendingPaymentBookingID = id
    }

    func scheduleCompanionAcceptSimulation(for id: BuddyBookingRecord.ID) {
        #if DEBUG
        guard FeatureFlags.simulateBookingCompanionAcceptance,
              !FeatureFlags.useRemoteBuddies else { return }
        cancelBookingSimulation(for: id)
        bookingSimulationTasks[id] = Task { @MainActor in
            defer { bookingSimulationTasks[id] = nil }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            if bookingRecords.contains(where: { $0.id == id && $0.status == .pendingConfirm }) {
                if abs(id.uuidString.hashValue) % 7 == 0 {
                    declineBooking(id)
                } else {
                    acceptBooking(id)
                }
            }
        }
        #endif
    }
}

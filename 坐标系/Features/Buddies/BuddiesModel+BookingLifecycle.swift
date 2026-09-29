//
//  BuddiesModel+BookingLifecycle.swift
//  坐标系
//
//  预约状态转移、SLA 定时与通知的共享编排（供 +Bookings / +RemoteBookings 调用）。
//

import CoordinateDomain
import Foundation
import CoordinateModels

extension BuddiesModel {
    // MARK: - Rehydration

    func rehydrateBookingLifecycleIfNeeded() {
        for record in bookingRecords {
            switch record.status {
            case .pendingConfirm:
                scheduleBookingConfirmationLifecycle(for: record.id)
            case .awaitingPayment:
                schedulePaymentExpiry(for: record.id)
            default:
                break
            }
        }
        rehydrateRemoteBookingPollingIfNeeded()
    }

    func rehydrateRemoteBookingPollingIfNeeded() {
        guard remoteBookingSync.isEnabled else { return }
        for record in bookingRecords where record.status == .pendingConfirm {
            startRemoteBookingPolling(for: record.id)
        }
    }

    // MARK: - Confirmation SLA (B-30)

    func scheduleBookingConfirmationLifecycle(for id: BuddyBookingRecord.ID) {
        guard let record = bookingRecords.first(where: { $0.id == id }),
              record.status == .pendingConfirm,
              let confirmDueAt = record.confirmDueAt else { return }

        NotificationService.scheduleBookingConfirmationSLA(
            bookingID: id,
            companion: record.companionNickname,
            confirmDueAt: confirmDueAt
        )
        scheduleConfirmationExpiry(for: id)
    }

    func scheduleConfirmationExpiry(for id: BuddyBookingRecord.ID) {
        bookingConfirmationExpiryTasks[id]?.cancel()
        guard let record = bookingRecords.first(where: { $0.id == id }),
              record.status == .pendingConfirm,
              let due = record.confirmDueAt else { return }
        let delay = due.timeIntervalSinceNow
        if delay <= 0 {
            expireOverdueConfirmation(id)
            return
        }
        bookingConfirmationExpiryTasks[id] = Task { @MainActor in
            defer { bookingConfirmationExpiryTasks[id] = nil }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            expireOverdueConfirmation(id)
        }
    }

    func expireOverdueConfirmationsIfNeeded(now: Date = .now) {
        let overdueIDs = booking.expireOverdueConfirmations.overdueIDs(
            in: bookingRecords,
            now: now
        )
        for id in overdueIDs {
            expireOverdueConfirmation(id, now: now)
        }
    }

    func expireOverdueConfirmation(_ id: BuddyBookingRecord.ID, now: Date = .now) {
        guard let record = bookingRecords.first(where: { $0.id == id }),
              record.isConfirmationOverdue(at: now) else { return }
        guard commitBookingTransition(id, transition: .expireConfirmation, now: now) != nil else {
            return
        }
        clearPendingConfirmLifecycle(for: id)
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        recordBookingTrustEvent(.expireConfirmation, bookingID: id, note: "确认超时")
        NotificationService.scheduleBookingConfirmationExpiredNotification(
            bookingID: id,
            companion: record.companionNickname
        )
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.confirmationExpiredHint)
    }

    // MARK: - Payment SLA (B-31)

    func expireOverduePaymentsIfNeeded(now: Date = .now) {
        let overdueIDs = booking.expireOverduePayments.overdueIDs(in: bookingRecords, now: now)
        for id in overdueIDs {
            expireOverduePayment(id, now: now)
        }
    }

    func expireOverduePayment(_ id: BuddyBookingRecord.ID, now: Date = .now) {
        guard let record = bookingRecords.first(where: { $0.id == id }),
              record.isPaymentOverdue(at: now) else { return }
        guard commitBookingTransition(id, transition: .expirePayment, now: now) != nil else { return }
        completePaymentRelease(for: id, trustNote: "支付超时", flashMessage: BuddyBookingFlowCopy.paymentExpiredHint)
    }

    func schedulePaymentExpiry(for id: BuddyBookingRecord.ID) {
        bookingPaymentExpiryTasks[id]?.cancel()
        guard let record = bookingRecords.first(where: { $0.id == id }),
              record.status == .awaitingPayment,
              let due = record.paymentDueAt else { return }
        let delay = due.timeIntervalSinceNow
        if delay <= 0 {
            expireOverduePayment(id)
            return
        }
        bookingPaymentExpiryTasks[id] = Task { @MainActor in
            defer { bookingPaymentExpiryTasks[id] = nil }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            expireOverduePayment(id)
        }
    }

    // MARK: - Acceptance notifications (B-31)

    func notifyBookingAcceptedIfNeeded(_ record: BuddyBookingRecord) {
        guard record.status == .awaitingPayment else { return }
        if pendingAwaitingPaymentReviewID == record.id { return }
        NotificationService.scheduleBookingAcceptedNotification(
            bookingID: record.id,
            companion: record.companionNickname
        )
    }

    func cancelBookingLifecycleNotifications(bookingID: UUID) {
        NotificationService.cancelBookingConfirmationNotifications(bookingID: bookingID)
    }

    // MARK: - Status completion side effects

    func completeCompanionAcceptance(for id: BuddyBookingRecord.ID) {
        clearPendingConfirmLifecycle(for: id)
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        pendingAwaitingPaymentReviewID = id
        schedulePaymentExpiry(for: id)
        recordBookingTrustEvent(.accept, bookingID: id)
        if let record = bookingRecords.first(where: { $0.id == id }) {
            notifyBookingAcceptedIfNeeded(record)
        }
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.companionAcceptedPayHint)
    }

    func completeCompanionDecline(for id: BuddyBookingRecord.ID) {
        clearPendingConfirmLifecycle(for: id)
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        recordBookingTrustEvent(.decline, bookingID: id)
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.companionDeclinedHint)
    }

    func completePaymentRelease(for id: BuddyBookingRecord.ID, trustNote: String, flashMessage: String) {
        cancelPaymentExpiry(for: id)
        clearBookingPresentationState(for: id)
        recordBookingTrustEvent(.expirePayment, bookingID: id, note: trustNote)
        persist()
        onRecordsChanged?()
        flash(flashMessage)
    }

    func clearPendingConfirmLifecycle(for id: BuddyBookingRecord.ID) {
        cancelBookingSimulation(for: id)
        cancelConfirmationExpiry(for: id)
        cancelRemoteBookingPoll(for: id)
        cancelBookingLifecycleNotifications(bookingID: id)
    }

    func clearAllBookingTasks(for id: BuddyBookingRecord.ID) {
        clearPendingConfirmLifecycle(for: id)
        cancelPaymentExpiry(for: id)
    }

    // MARK: - Transition primitives

    @discardableResult
    func commitBookingTransition(
        _ id: BuddyBookingRecord.ID,
        transition: BookingStatusTransition,
        paymentMethod: String? = nil,
        now: Date = .now
    ) -> BuddyBookingRecord? {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return nil }
        switch booking.applyTransition.apply(
            bookingRecords[index],
            transition: transition,
            paymentMethod: paymentMethod,
            now: now
        ) {
        case .failure:
            return nil
        case .success(let outcome):
            if !outcome.presentationOnly {
                bookingRecords[index] = outcome.record
            }
            return outcome.record
        }
    }

    func clearBookingPresentationState(for id: BuddyBookingRecord.ID) {
        if pendingPaymentBookingID == id {
            pendingPaymentBookingID = nil
        }
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        if pendingAwaitingPaymentReviewID == id {
            pendingAwaitingPaymentReviewID = nil
        }
    }

    func recordBookingTrustEvent(
        _ transition: BookingStatusTransition,
        bookingID: BuddyBookingRecord.ID,
        note: String? = nil
    ) {
        guard let record = bookingRecords.first(where: { $0.id == bookingID }) else { return }
        let actor = trustActorKey()
        let subject = record.companionNickname
        switch transition {
        case .accept:
            trustService.record(.bookingAccepted, domain: .booking, actorKey: actor, subjectKey: subject)
        case .decline:
            trustService.record(.bookingDeclined, domain: .booking, actorKey: actor, subjectKey: subject)
        case .withdraw, .expirePayment, .expireConfirmation:
            trustService.record(
                .bookingCancelled,
                domain: .booking,
                actorKey: actor,
                subjectKey: subject,
                note: note ?? cancellationNote(for: transition)
            )
        default:
            break
        }
    }

    // MARK: - Task cancellation

    func cancelBookingSimulation(for id: BuddyBookingRecord.ID) {
        bookingSimulationTasks[id]?.cancel()
        bookingSimulationTasks[id] = nil
    }

    func cancelConfirmationExpiry(for id: BuddyBookingRecord.ID) {
        bookingConfirmationExpiryTasks[id]?.cancel()
        bookingConfirmationExpiryTasks[id] = nil
    }

    func cancelPaymentExpiry(for id: BuddyBookingRecord.ID) {
        bookingPaymentExpiryTasks[id]?.cancel()
        bookingPaymentExpiryTasks[id] = nil
    }

    func cancelRemoteBookingPoll(for id: BuddyBookingRecord.ID) {
        bookingRemotePollTasks[id]?.cancel()
        bookingRemotePollTasks[id] = nil
    }

    private func cancellationNote(for transition: BookingStatusTransition) -> String {
        switch transition {
        case .expirePayment:
            "支付超时"
        case .expireConfirmation:
            "确认超时"
        case .withdraw:
            "用户撤回"
        default:
            "已取消"
        }
    }
}

//
//  BuddiesModel+Bookings.swift
//  坐标系
//
//  预约记录编排：下单、支付、履约、退款与演示接单模拟。
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
            flash(GuestAccessGate.youthCommerceReason)
            return
        }
        bookingPresentation = BuddyBookingPresentation(
            companion: companion,
            initialDay: initialDay,
            serviceSKU: serviceSKU,
            token: UUID()
        )
    }

    func dismissBookingPresentation() {
        bookingPresentation = nil
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
        bookingPresentation = nil
        pendingBookingAcknowledgementID = candidate.id
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
        guard let id = pendingBookingAcknowledgementID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    func dismissBookingAcknowledgement() {
        pendingBookingAcknowledgementID = nil
    }

    func dismissBookingSuccess() {
        pendingBookingSuccessID = nil
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
            flash("订单尚未可支付")
            return
        }
        pendingAwaitingPaymentReviewID = nil
        pendingPaymentBookingID = id
    }

    @discardableResult
    func confirmPayment(
        _ id: BuddyBookingRecord.ID,
        method: PaymentMethod = .wallet
    ) -> PaymentOutcome {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else {
            return .failed("订单不存在")
        }
        guard case .success(let record) = booking.statusTransition.validate(
            bookingRecords[index],
            transition: .confirmPayment
        ) else {
            return .failed("订单尚未可支付")
        }
        if method != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        }
        let amountCents = WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800
        let outcome = walletStore.charge(
            amountCents: amountCents,
            method: method,
            kind: .bookingPayment,
            title: "陪玩 · \(record.companionNickname)",
            subtitle: record.priceText,
            relatedID: record.id
        )
        guard outcome == .success else { return outcome }

        guard let paid = commitBookingTransition(
            id,
            transition: .confirmPayment,
            paymentMethod: method.displayName
        ) else {
            return .failed("订单尚未可支付")
        }
        cancelPaymentExpiry(for: id)
        pendingPaymentBookingID = nil
        pendingBookingSuccessID = id
        trustService.record(
            .bookingPaid,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: paid.companionNickname
        )
        NotificationService.scheduleBookingReminder(
            bookingID: id,
            companion: paid.companionNickname,
            at: paid.scheduledAt
        )
        persist()
        onRecordsChanged?()
        walletPassStore.issueBookingTicket(for: paid)
        return .success
    }

    func cancelPendingPayment() {
        pendingPaymentBookingID = nil
    }

    func withdrawPendingBooking(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .withdraw) != nil else { return }
        clearBookingPresentationState(for: id)
        clearAllBookingTasks(for: id)
        recordBookingTrustEvent(.withdraw, bookingID: id)
        persist()
        onRecordsChanged?()
        flash("已取消预约")
    }

    func markInProgress(_ id: BuddyBookingRecord.ID) {
        guard let record = commitBookingTransition(id, transition: .markInProgress) else { return }
        _ = walletPassStore.issueBookingTicket(for: record)
        persist()
        onRecordsChanged?()
        flash("预约已开始")
    }

    func completeBooking(_ id: BuddyBookingRecord.ID) {
        guard let record = commitBookingTransition(id, transition: .complete) else { return }
        _ = walletPassStore.issueBookingTicket(for: record)
        NotificationService.cancelBookingReminder(bookingID: id)
        trustService.record(
            .bookingCompleted,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: record.companionNickname
        )
        persist()
        onRecordsChanged?()
        if !trustService.hasCheckedIn(bookingID: id) {
            pendingSafetyCheckInBookingID = id
            flash("订单已完成，可确认履约情况")
        } else {
            flash("订单已完成")
        }
    }

    func cancelPendingSafetyCheckIn() {
        pendingSafetyCheckInBookingID = nil
    }

    var pendingSafetyCheckInBooking: BuddyBookingRecord? {
        guard let id = pendingSafetyCheckInBookingID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    @discardableResult
    func refundBooking(
        _ id: BuddyBookingRecord.ID,
        reason: String,
        detail: String
    ) -> Result<UUID, RefundSubmitError> {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else {
            return .failure(.bookingNotFound)
        }
        guard case .success(let record) = booking.statusTransition.validate(
            bookingRecords[index],
            transition: .refund
        ) else {
            return .failure(.orderNotRefundable)
        }

        let result = refundFlowService.submitBookingRefund(
            record: record,
            reason: reason,
            detail: detail,
            onFinalize: { [weak self] bookingID in
                self?.completeBookingRefund(bookingID)
            },
            onReject: { [weak self] bookingID in
                self?.rejectBookingRefund(bookingID)
            }
        )
        switch result {
        case .success(let refundRecord):
            guard let updated = commitBookingTransition(id, transition: .refund) else {
                return .failure(.orderNotRefundable)
            }
            _ = walletPassStore.issueBookingTicket(for: updated)
            NotificationService.cancelBookingReminder(bookingID: id)
            cancelBookingLifecycleNotifications(bookingID: id)
            persist()
            onRecordsChanged?()
            flash("退款申请已提交")
            return .success(refundRecord.id)
        case .failure(let error):
            return .failure(error)
        }
    }

    func completeBookingRefund(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .completeRefund) != nil else { return }
        persist()
        onRecordsChanged?()
        flash("退款已完成")
    }

    func rejectBookingRefund(_ id: BuddyBookingRecord.ID) {
        guard let record = commitBookingTransition(id, transition: .rejectRefund) else { return }
        _ = walletPassStore.issueBookingTicket(for: record)
        persist()
        onRecordsChanged?()
        flash("退款未通过，预约已恢复")
    }

    func cancelBooking(_ id: BuddyBookingRecord.ID) {
        guard let record = bookingRecords.first(where: { $0.id == id }) else { return }
        let companion = record.companionNickname
        guard commitBookingTransition(id, transition: .cancel) != nil else { return }
        clearBookingPresentationState(for: id)
        clearAllBookingTasks(for: id)
        NotificationService.cancelBookingReminder(bookingID: id)
        walletPassStore.void(relatedID: id)
        trustService.record(
            .bookingCancelled,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: companion
        )
        persist()
        onRecordsChanged?()
        flash("已取消预约")
    }

    func deleteBooking(_ id: BuddyBookingRecord.ID) {
        NotificationService.cancelBookingReminder(bookingID: id)
        walletPassStore.revoke(relatedID: id)
        clearAllBookingTasks(for: id)
        bookingRecords.removeAll { $0.id == id }
        persist()
        onRecordsChanged?()
    }

    func rescheduleBooking(_ id: BuddyBookingRecord.ID, scheduledAt: Date, hours: Int) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].canReschedule else {
            if bookingRecords[index].status == .refunding {
                flash("退款处理中，暂不可改期")
            }
            return
        }
        let hourlyPrice = SampleData.paidCompanions.first(where: {
            $0.profile.nickname == bookingRecords[index].companionNickname
        })?.hourlyPrice
        let draft = bookingService.rescheduleBooking(
            bookingRecords[index],
            scheduledAt: scheduledAt,
            hours: hours,
            hourlyPrice: hourlyPrice
        )
        if booking.scheduleConflict.hasConflict(
            candidate: draft,
            existing: bookingRecords,
            excluding: id
        ) {
            flash("改期时间与其他预约冲突")
            return
        }
        bookingRecords[index] = draft
        trustService.record(
            .bookingRescheduled,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: draft.companionNickname
        )
        if bookingRecords[index].status == .paid
            || bookingRecords[index].status == .inProgress
            || bookingRecords[index].status == .completed {
            NotificationService.scheduleBookingReminder(
                bookingID: id,
                companion: bookingRecords[index].companionNickname,
                at: scheduledAt
            )
            _ = walletPassStore.issueBookingTicket(for: bookingRecords[index])
        }
        persist()
        onRecordsChanged?()
    }

    func hasScheduleConflict(_ candidate: BuddyBookingRecord, excluding: UUID? = nil) -> Bool {
        booking.scheduleConflict.hasConflict(
            candidate: candidate,
            existing: bookingRecords,
            excluding: excluding
        )
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

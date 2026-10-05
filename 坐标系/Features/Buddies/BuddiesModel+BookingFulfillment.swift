//
//  BuddiesModel+BookingFulfillment.swift
//  坐标系
//
//  预约履约：支付确认、撤回、进行中/完成、退款、取消、改期。
//

import CoordinateDomain
import Foundation
import CoordinateModels

extension BuddiesModel {
    @discardableResult
    func confirmPayment(
        _ id: BuddyBookingRecord.ID,
        method: PaymentMethod = .wallet
    ) async -> PaymentOutcome {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else {
            return .failed(BuddyBookingFlowCopy.orderNotFound)
        }
        guard case .success(let record) = booking.statusTransition.validate(
            bookingRecords[index],
            transition: .confirmPayment
        ) else {
            return .failed(BuddyBookingFlowCopy.orderNotPayableYet)
        }
        if method != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            CommerceAnalytics.checkoutBlocked(method: method.rawValue)
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        }
        let amountCents = WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800
        let outcome = await walletStore.chargeAsync(
            amountCents: amountCents,
            method: method,
            kind: .bookingPayment,
            title: "\(BuddyBrowseCopy.ModelCopy.bookingThreadTitlePrefix) · \(record.companionNickname)",
            subtitle: record.priceText,
            relatedID: record.id,
            orderType: "booking"
        )
        guard outcome == .success else { return outcome }

        guard let paid = commitBookingTransition(
            id,
            transition: .confirmPayment,
            paymentMethod: method.displayName
        ) else {
            return .failed(BuddyBookingFlowCopy.orderNotPayableYet)
        }
        cancelPaymentExpiry(for: id)
        presentation.pendingPaymentBookingID = nil
        presentation.pendingBookingSuccessID = id
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
        presentation.pendingPaymentBookingID = nil
    }

    func withdrawPendingBooking(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .withdraw) != nil else { return }
        clearBookingPresentationState(for: id)
        clearAllBookingTasks(for: id)
        recordBookingTrustEvent(.withdraw, bookingID: id)
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.bookingCancelled)
    }

    func markInProgress(_ id: BuddyBookingRecord.ID) {
        guard let record = commitBookingTransition(id, transition: .markInProgress) else { return }
        _ = walletPassStore.issueBookingTicket(for: record)
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.bookingStarted)
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
            presentation.pendingSafetyCheckInBookingID = id
            flash(BuddyBookingFlowCopy.bookingCompletedWithCheckIn)
        } else {
            flash(BuddyBookingFlowCopy.bookingCompleted)
        }
    }

    func cancelPendingSafetyCheckIn() {
        presentation.pendingSafetyCheckInBookingID = nil
    }

    var pendingSafetyCheckInBooking: BuddyBookingRecord? {
        guard let id = presentation.pendingSafetyCheckInBookingID else { return nil }
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
            flash(BuddyBookingFlowCopy.refundSubmitted)
            return .success(refundRecord.id)
        case .failure(let error):
            return .failure(error)
        }
    }

    func completeBookingRefund(_ id: BuddyBookingRecord.ID) {
        guard commitBookingTransition(id, transition: .completeRefund) != nil else { return }
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.refundCompleted)
    }

    func rejectBookingRefund(_ id: BuddyBookingRecord.ID) {
        guard let record = commitBookingTransition(id, transition: .rejectRefund) else { return }
        _ = walletPassStore.issueBookingTicket(for: record)
        persist()
        onRecordsChanged?()
        flash(BuddyBookingFlowCopy.refundRejectedRestored)
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
        flash(BuddyBookingFlowCopy.bookingCancelled)
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
                flash(BuddyBookingFlowCopy.refundInProgressCannotReschedule)
            }
            return
        }
        let hourlyPrice: Int?
        let record = bookingRecords[index]
        if let companion = item(for: record.companionNickname, userID: record.companionUserID),
           case .paid(let paid) = companion {
            hourlyPrice = paid.hourlyPrice
        } else if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog {
            hourlyPrice = SampleData.paidCompanions.first(where: {
                ParticipantIdentity.matches(
                    nickname: $0.profile.nickname,
                    userID: $0.profile.userID,
                    otherNickname: record.companionNickname,
                    otherUserID: record.companionUserID
                )
            })?.hourlyPrice
        } else {
            hourlyPrice = nil
        }
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
            flash(BuddyBookingFlowCopy.rescheduleConflict)
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
}

import CoordinateDomain
import CoordinateModels
import XCTest

final class BuddiesBookingUseCaseTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let validator = ValidateBookingStatusTransitionUseCase()

    // MARK: - Schedule conflict

    func testDetectScheduleConflictForSameCompanion() {
        let companion = "阿川"
        let base = now.addingTimeInterval(7200)
        let existing = BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion,
            hours: 2,
            scheduledAt: base,
            bookedAt: now,
            priceText: "¥100",
            status: .paid
        )
        let overlapping = BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion,
            hours: 2,
            scheduledAt: base.addingTimeInterval(3600),
            bookedAt: now,
            priceText: "¥100",
            status: .pendingConfirm
        )

        XCTAssertTrue(
            DetectBookingScheduleConflictUseCase().hasConflict(
                candidate: overlapping,
                existing: [existing]
            )
        )
    }

    func testCancelledBookingDoesNotBlockSchedule() {
        let companion = "阿川"
        let base = now.addingTimeInterval(7200)
        let cancelled = BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion,
            hours: 2,
            scheduledAt: base,
            bookedAt: now,
            priceText: "¥100",
            status: .cancelled
        )
        let candidate = BuddyBookingRecord(
            id: UUID(),
            companionNickname: companion,
            hours: 2,
            scheduledAt: base,
            bookedAt: now,
            priceText: "¥100",
            status: .pendingConfirm
        )

        XCTAssertFalse(
            DetectBookingScheduleConflictUseCase().hasConflict(
                candidate: candidate,
                existing: [cancelled]
            )
        )
    }

    // MARK: - Decoder

    func testDecoderDefaultsMissingStatusToPendingConfirm() throws {
        let original = makeRecord(status: .paid)
        var object = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(original)
        ) as! [String: Any]
        object.removeValue(forKey: "status")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(BuddyBookingRecord.self, from: data)
        XCTAssertEqual(decoded.status, .pendingConfirm)
    }

    // MARK: - Accept / decline

    func testValidateAcceptRequiresPendingConfirm() {
        let record = makeRecord(status: .paid)
        XCTAssertFalse(validator.canTransition(record, transition: .accept))
        assertInvalidTransition(validator.validate(record, transition: .accept))
    }

    func testValidateAcceptFromPendingConfirmSucceeds() {
        let record = makeRecord(status: .pendingConfirm)
        XCTAssertTrue(validator.canTransition(record, transition: .accept))
        assertSuccess(validator.validate(record, transition: .accept))
    }

    func testValidateDeclineFromPendingConfirmSucceeds() {
        let record = makeRecord(status: .pendingConfirm)
        XCTAssertTrue(validator.canTransition(record, transition: .decline))
    }

    func testValidateDeclineFromPaidFails() {
        let record = makeRecord(status: .paid)
        XCTAssertFalse(validator.canTransition(record, transition: .decline))
    }

    // MARK: - Withdraw

    func testValidateWithdrawFromPendingConfirmSucceeds() {
        let record = makeRecord(status: .pendingConfirm)
        XCTAssertTrue(validator.canTransition(record, transition: .withdraw))
    }

    func testValidateWithdrawFromAwaitingPaymentSucceeds() {
        let record = makeRecord(status: .awaitingPayment)
        XCTAssertTrue(validator.canTransition(record, transition: .withdraw))
    }

    func testValidateWithdrawFromPaidFails() {
        let record = makeRecord(status: .paid)
        XCTAssertFalse(validator.canTransition(record, transition: .withdraw))
    }

    // MARK: - Payment

    func testValidateBeginPaymentRequiresAwaitingPayment() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .beginPayment))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .pendingConfirm), transition: .beginPayment))
        assertNotPayable(validator.validate(makeRecord(status: .pendingConfirm), transition: .beginPayment))
    }

    func testValidateConfirmPaymentRequiresAwaitingPayment() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .confirmPayment))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .pendingConfirm), transition: .confirmPayment))
        assertNotPayable(validator.validate(makeRecord(status: .pendingConfirm), transition: .confirmPayment))
    }

    func testValidateConfirmPaymentFromPaidFails() {
        let record = makeRecord(status: .paid)
        XCTAssertFalse(validator.canTransition(record, transition: .confirmPayment))
        assertNotPayable(validator.validate(record, transition: .confirmPayment))
    }

    // MARK: - Fulfillment

    func testValidateMarkInProgressFromPaidSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .paid), transition: .markInProgress))
    }

    func testValidateMarkInProgressFromAwaitingPaymentFails() {
        XCTAssertFalse(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .markInProgress))
    }

    func testValidateCompleteFromPaidWithoutInProgressSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .paid), transition: .complete))
        assertSuccess(validator.validate(makeRecord(status: .paid), transition: .complete))
    }

    func testValidateCompleteFromInProgressSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .inProgress), transition: .complete))
    }

    func testValidateCompleteFromAwaitingPaymentFails() {
        XCTAssertFalse(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .complete))
    }

    // MARK: - Cancel / refund

    func testValidateCancelFromPaidSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .paid), transition: .cancel))
    }

    func testValidateCancelFromInProgressSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .inProgress), transition: .cancel))
    }

    func testValidateCancelFromCompletedFails() {
        XCTAssertFalse(validator.canTransition(makeRecord(status: .completed), transition: .cancel))
    }

    func testValidateRefundFromPaidSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .paid), transition: .refund))
    }

    func testValidateRefundFromInProgressSucceeds() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .inProgress), transition: .refund))
    }

    func testValidateRefundFromPendingConfirmFails() {
        XCTAssertFalse(validator.canTransition(makeRecord(status: .pendingConfirm), transition: .refund))
    }

    func testValidateCompleteRefundRequiresRefunding() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .refunding), transition: .completeRefund))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .paid), transition: .completeRefund))
    }

    func testValidateRejectRefundRequiresRefunding() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .refunding), transition: .rejectRefund))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .inProgress), transition: .rejectRefund))
    }

    func testValidateRefundFromRefundingFails() {
        XCTAssertFalse(validator.canTransition(makeRecord(status: .refunding), transition: .refund))
    }

    // MARK: - Apply transition

    func testApplyAcceptSetsAwaitingPaymentAndPaymentDue() {
        let apply = ApplyBookingStatusTransitionUseCase()
        let record = makeRecord(status: .pendingConfirm)
        guard case .success(let outcome) = apply.apply(record, transition: .accept, now: now) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(outcome.record.status, .awaitingPayment)
        XCTAssertEqual(outcome.record.acceptedAt, now)
        XCTAssertEqual(
            outcome.record.paymentDueAt,
            BookingPaymentPolicy.paymentDueDate(from: now)
        )
        XCTAssertFalse(outcome.presentationOnly)
    }

    func testApplyBeginPaymentIsPresentationOnly() {
        let apply = ApplyBookingStatusTransitionUseCase()
        let record = makeRecord(status: .awaitingPayment)
        guard case .success(let outcome) = apply.apply(record, transition: .beginPayment) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(outcome.record.status, .awaitingPayment)
        XCTAssertTrue(outcome.presentationOnly)
    }

    func testApplyRefundPreservesRestoreStatus() {
        let apply = ApplyBookingStatusTransitionUseCase()
        let record = makeRecord(status: .paid)
        guard case .success(let outcome) = apply.apply(record, transition: .refund) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(outcome.record.status, .refunding)
        XCTAssertEqual(outcome.record.refundRestoreStatus, .paid)
    }

    func testApplyExpirePaymentCancelsAwaitingPayment() {
        let apply = ApplyBookingStatusTransitionUseCase()
        var record = makeRecord(status: .awaitingPayment)
        record.acceptedAt = now.addingTimeInterval(-86_400)
        record.paymentDueAt = now.addingTimeInterval(-60)
        guard case .success(let outcome) = apply.apply(record, transition: .expirePayment, now: now) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(outcome.record.status, .cancelled)
    }

    func testExpireOverduePaymentsFindsStaleAwaitingPayment() {
        var record = makeRecord(status: .awaitingPayment)
        record.paymentDueAt = now.addingTimeInterval(-120)
        let ids = ExpireOverdueBookingPaymentsUseCase().overdueIDs(in: [record], now: now)
        XCTAssertEqual(ids, [record.id])
    }

    func testExpireOverduePaymentsIgnoresFutureDueDate() {
        var record = makeRecord(status: .awaitingPayment)
        record.paymentDueAt = now.addingTimeInterval(3600)
        let ids = ExpireOverdueBookingPaymentsUseCase().overdueIDs(in: [record], now: now)
        XCTAssertTrue(ids.isEmpty)
    }

    func testValidateExpirePaymentRequiresAwaitingPayment() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .expirePayment))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .paid), transition: .expirePayment))
    }

    func testValidateExpireConfirmationRequiresPendingConfirm() {
        XCTAssertTrue(validator.canTransition(makeRecord(status: .pendingConfirm), transition: .expireConfirmation))
        XCTAssertFalse(validator.canTransition(makeRecord(status: .awaitingPayment), transition: .expireConfirmation))
    }

    func testApplyExpireConfirmationCancelsPendingConfirm() {
        let apply = ApplyBookingStatusTransitionUseCase()
        var record = makeRecord(status: .pendingConfirm)
        record.confirmDueAt = now.addingTimeInterval(-60)
        guard case .success(let outcome) = apply.apply(record, transition: .expireConfirmation, now: now) else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(outcome.record.status, .cancelled)
    }

    func testExpireOverdueConfirmationsFindsStalePendingConfirm() {
        var record = makeRecord(status: .pendingConfirm)
        record.confirmDueAt = now.addingTimeInterval(-120)
        let ids = ExpireOverdueBookingConfirmationsUseCase().overdueIDs(in: [record], now: now)
        XCTAssertEqual(ids, [record.id])
    }

    func testConfirmationPolicyDueDate() {
        let due = BookingConfirmationPolicy.confirmDueDate(from: now)
        XCTAssertEqual(due.timeIntervalSince(now), BookingConfirmationPolicy.confirmationWindow, accuracy: 0.5)
    }

    func testReconcileRemoteAcceptFromPendingConfirm() {
        let reconcile = ReconcileRemoteBookingRecordUseCase()
        let local = makeRecord(status: .pendingConfirm)
        var remote = makeRecord(status: .awaitingPayment)
        remote.acceptedAt = now
        remote.paymentDueAt = now.addingTimeInterval(3600)
        let merged = reconcile.reconcile(local: local, remote: remote)
        XCTAssertEqual(merged?.status, .awaitingPayment)
        XCTAssertEqual(merged?.acceptedAt, now)
    }

    func testReconcileRemoteDeclineFromPendingConfirm() {
        let reconcile = ReconcileRemoteBookingRecordUseCase()
        let local = makeRecord(status: .pendingConfirm)
        let remote = makeRecord(status: .cancelled)
        XCTAssertEqual(reconcile.reconcile(local: local, remote: remote)?.status, .cancelled)
    }

    func testReconcileIgnoresLocalPaidRegression() {
        let reconcile = ReconcileRemoteBookingRecordUseCase()
        let local = makeRecord(status: .paid)
        let remote = makeRecord(status: .awaitingPayment)
        XCTAssertNil(reconcile.reconcile(local: local, remote: remote))
    }

    func testReconcileEnrichesAwaitingPaymentTimestamps() {
        let reconcile = ReconcileRemoteBookingRecordUseCase()
        var local = makeRecord(status: .awaitingPayment)
        var remote = makeRecord(status: .awaitingPayment)
        remote.acceptedAt = now
        remote.paymentDueAt = now.addingTimeInterval(3600)
        let merged = reconcile.reconcile(local: local, remote: remote)
        XCTAssertEqual(merged?.paymentDueAt, remote.paymentDueAt)
    }

    // MARK: - Helpers

    private func makeRecord(status: BookingOrderStatus) -> BuddyBookingRecord {
        BuddyBookingRecord(
            id: UUID(),
            companionNickname: "阿川",
            hours: 2,
            scheduledAt: now.addingTimeInterval(7200),
            bookedAt: now,
            priceText: "¥100",
            status: status
        )
    }

    private func assertSuccess(
        _ result: Result<BuddyBookingRecord, BookingStatusTransitionFailure>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .success = result else {
            XCTFail("expected success", file: file, line: line)
            return
        }
    }

    private func assertInvalidTransition(
        _ result: Result<BuddyBookingRecord, BookingStatusTransitionFailure>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failure(.invalidTransition) = result else {
            XCTFail("expected invalidTransition", file: file, line: line)
            return
        }
    }

    private func assertNotPayable(
        _ result: Result<BuddyBookingRecord, BookingStatusTransitionFailure>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failure(.notPayable) = result else {
            XCTFail("expected notPayable", file: file, line: line)
            return
        }
    }
}

//
//  ApplyBookingStatusTransitionUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct BookingStatusTransitionOutcome: Sendable, Equatable {
    public let record: BuddyBookingRecord
    /// 仅影响呈现（如打开支付 Sheet），不写入订单状态。
    public let presentationOnly: Bool

    public init(record: BuddyBookingRecord, presentationOnly: Bool = false) {
        self.record = record
        self.presentationOnly = presentationOnly
    }
}

public struct ApplyBookingStatusTransitionUseCase: Sendable {
    private let validator: ValidateBookingStatusTransitionUseCase

    public init(
        validator: ValidateBookingStatusTransitionUseCase = ValidateBookingStatusTransitionUseCase()
    ) {
        self.validator = validator
    }

    public func apply(
        _ record: BuddyBookingRecord?,
        transition: BookingStatusTransition,
        paymentMethod: String? = nil,
        now: Date = .now
    ) -> Result<BookingStatusTransitionOutcome, BookingStatusTransitionFailure> {
        switch validator.validate(record, transition: transition) {
        case .failure(let failure):
            return .failure(failure)
        case .success(let record):
            if transition == .beginPayment {
                return .success(BookingStatusTransitionOutcome(record: record, presentationOnly: true))
            }
            return .success(
                BookingStatusTransitionOutcome(
                    record: advance(record, transition: transition, paymentMethod: paymentMethod, now: now)
                )
            )
        }
    }

    private func advance(
        _ record: BuddyBookingRecord,
        transition: BookingStatusTransition,
        paymentMethod: String?,
        now: Date
    ) -> BuddyBookingRecord {
        var next = record
        switch transition {
        case .accept:
            next.status = .awaitingPayment
            next.acceptedAt = now
            next.paymentDueAt = BookingPaymentPolicy.paymentDueDate(from: now)
        case .decline, .withdraw, .cancel, .expirePayment, .expireConfirmation:
            next.status = .cancelled
        case .confirmPayment:
            next.status = .paid
            next.paidAt = next.paidAt ?? now
            if let paymentMethod {
                next.paymentMethod = paymentMethod
            }
        case .markInProgress:
            next.status = .inProgress
        case .complete:
            next.status = .completed
            next.completedAt = now
        case .refund:
            next.refundRestoreStatus = record.status
            next.status = .refunding
        case .completeRefund:
            next.refundRestoreStatus = nil
            next.status = .refunded
        case .rejectRefund:
            let restore = record.refundRestoreStatus ?? .paid
            next.refundRestoreStatus = nil
            next.status = restore
        case .beginPayment:
            break
        }
        return next
    }
}

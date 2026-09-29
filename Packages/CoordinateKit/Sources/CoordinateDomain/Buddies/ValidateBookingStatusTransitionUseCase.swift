//
//  ValidateBookingStatusTransitionUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct ValidateBookingStatusTransitionUseCase: Sendable {
    public init() {}

    public func canTransition(
        _ record: BuddyBookingRecord,
        transition: BookingStatusTransition
    ) -> Bool {
        switch transition {
        case .accept, .decline:
            return record.status == .pendingConfirm
        case .withdraw:
            return record.canWithdraw
        case .beginPayment:
            return record.canPay
        case .confirmPayment:
            return record.status == .awaitingPayment
        case .markInProgress:
            return record.canMarkInProgress
        case .complete:
            return record.canComplete
        case .cancel:
            return record.canWithdraw
                || record.status == .paid
                || record.status == .inProgress
        case .refund:
            return record.canRefund
        case .completeRefund, .rejectRefund:
            return record.status == .refunding
        case .expirePayment:
            return record.status == .awaitingPayment
        case .expireConfirmation:
            return record.status == .pendingConfirm
        }
    }

    public func validate(
        _ record: BuddyBookingRecord?,
        transition: BookingStatusTransition
    ) -> Result<BuddyBookingRecord, BookingStatusTransitionFailure> {
        guard let record else { return .failure(.recordNotFound) }
        guard canTransition(record, transition: transition) else {
            if transition == .beginPayment || transition == .confirmPayment, !record.canPay {
                return .failure(.notPayable)
            }
            return .failure(.invalidTransition)
        }
        return .success(record)
    }
}

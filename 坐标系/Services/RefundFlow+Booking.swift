//
//  RefundFlow+Booking.swift
//  坐标系
//
//  陪玩预约退款提交。
//

import CoordinateModels
import Foundation

extension RefundFlowService {
    func submitBookingRefund(
        record: BuddyBookingRecord,
        reason: String,
        detail: String,
        initiator: RefundInitiator = .user,
        expedited: Bool = false,
        onFinalize: @escaping (BuddyBookingRecord.ID) -> Void = { _ in },
        onReject: @escaping (BuddyBookingRecord.ID) -> Void = { _ in }
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        if isRefunding(orderID: record.id) {
            return .failure(.duplicateInFlight)
        }

        if initiator == .user {
            let policy = RefundPolicy.evaluateBooking(record: record)
            guard policy.allowed else {
                return .failure(.policyDenied(policy.detail))
            }
            guard record.canRefund else {
                return .failure(.orderNotRefundable)
            }
        } else if record.status != .refunding {
            guard record.canRefund else {
                return .failure(.orderNotRefundable)
            }
        }

        let amountCents = WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800

        let refundRecord = RefundRequestRecord(
            id: UUID(),
            kind: .booking,
            orderID: record.id,
            subjectTitle: record.companionNickname,
            amountCents: amountCents,
            amountDisplay: record.priceText,
            paymentMethod: record.paymentMethod,
            reason: reason,
            detail: detail,
            status: .submitted,
            initiator: initiator,
            createdAt: .now,
            processingStartedAt: nil,
            completedAt: nil,
            cancelsRegistration: false,
            activityID: nil,
            rejectionMessage: nil
        )
        insert(refundRecord)
        bookingFinalizeHandlers[refundRecord.id] = onFinalize
        bookingRejectHandlers[refundRecord.id] = onReject
        enqueueProcessing(recordID: refundRecord.id, expedited: expedited) {}
        return .success(refundRecord)
    }
}

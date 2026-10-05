//
//  RefundFlow+Activity.swift
//  坐标系
//
//  活动退款提交。
//

import CoordinateModels
import Foundation

extension RefundFlowService {
    func submitActivityRefund(
        order: ActivityOrder,
        activity: Activity?,
        refundNotes: [String] = [],
        reason: String,
        detail: String,
        cancelRegistration: Bool,
        initiator: RefundInitiator = .user,
        expedited: Bool = false,
        onCancelRegistration: ((Activity.ID) -> Void)? = nil
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        if isRefunding(orderID: order.id) {
            return .failure(.duplicateInFlight)
        }

        if initiator == .user {
            if order.status != .paid {
                return .failure(.orderNotRefundable)
            }
            if let activity {
                let policy = RefundPolicy.evaluateActivity(activity: activity, refundNotes: refundNotes)
                guard policy.allowed else {
                    return .failure(.policyDenied(policy.detail))
                }
            }
        } else if order.status != .paid && order.status != .refunding {
            return .failure(.orderNotRefundable)
        }

        if order.status == .paid {
            if let error = ActivityPaymentStore.requestRefund(orderID: order.id) {
                return .failure(.policyDenied(error))
            }
        }

        let record = RefundRequestRecord(
            id: UUID(),
            kind: .activity,
            orderID: order.id,
            subjectTitle: order.activityTitle,
            amountCents: order.amountCents,
            amountDisplay: ActivityFeeParser.formattedPrice(cents: order.amountCents),
            paymentMethod: order.paymentMethod,
            reason: reason,
            detail: detail,
            status: .submitted,
            initiator: initiator,
            createdAt: .now,
            processingStartedAt: nil,
            completedAt: nil,
            cancelsRegistration: cancelRegistration,
            activityID: order.activityID,
            rejectionMessage: nil
        )
        insert(record)
        enqueueProcessing(recordID: record.id, expedited: expedited) {
            if cancelRegistration {
                onCancelRegistration?(order.activityID)
            }
        }
        return .success(record)
    }

    /// 主办取消活动：为所有已支付订单创建系统退款
    func submitSystemActivityRefunds(
        for activityID: Activity.ID,
        activityTitle: String,
        refundNotes: [String] = [],
        onCancelRegistration: ((Activity.ID) -> Void)? = nil
    ) {
        for order in ActivityPaymentStore.orders(for: activityID) where order.status == .paid {
            _ = submitActivityRefund(
                order: order,
                activity: nil,
                refundNotes: refundNotes,
                reason: "主办取消活动",
                detail: "活动「\(activityTitle)」已被发起人取消，系统自动退款。",
                cancelRegistration: false,
                initiator: .system,
                expedited: true,
                onCancelRegistration: onCancelRegistration
            )
        }
    }

    /// 支付成功但报名失败等场景：系统即时退款，不取消参加（尚未加入）
    func submitExpeditedActivityRefund(
        order: ActivityOrder,
        reason: String,
        detail: String
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        submitActivityRefund(
            order: order,
            activity: nil,
            reason: reason,
            detail: detail,
            cancelRegistration: false,
            initiator: .system,
            expedited: true
        )
    }
}

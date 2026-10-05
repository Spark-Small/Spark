//
//  ActivityJourneyCommerceModels.swift
//  坐标系
//
//  活动行程商务条：动作枚举、订单投影、可点行动列表（与 Section View 分离）。
//

import Foundation
import CoordinateModels

enum ActivityJourneyCommerceAction: Equatable {
    case resumePayment
    case openOrders
    case openRefund(UUID)
}

@MainActor
struct ActivityJourneyCommerceModel: Equatable {
    let order: ActivityOrder
    var refundRequestID: UUID?

    static func resolve(
        activityID: Activity.ID,
        refunds: RefundFlowService
    ) -> ActivityJourneyCommerceModel? {
        guard let order = ActivityPaymentStore.displayOrder(for: activityID) else { return nil }
        let refundID = refunds.latestRequest(forOrderID: order.id)?.id
        return ActivityJourneyCommerceModel(order: order, refundRequestID: refundID)
    }

    var statusLine: String {
        ActivityPaymentStore.statusLabel(for: order.status)
    }

    var amountLine: String {
        ActivityFeeParser.formattedPrice(cents: order.amountCents)
    }

    /// 按订单态给出可点行动（续付 / 退款 / 订单列表）；取消态无行动。
    var actions: [(title: String, systemImage: String, action: ActivityJourneyCommerceAction)] {
        switch order.status {
        case .pending:
            return [(
                ActivityDetailCopy.resumePaymentAction,
                "yensign.circle",
                .resumePayment
            )]
        case .refunding:
            if let id = refundRequestID {
                return [(
                    ActivityJourneyCopy.commerceViewRefund,
                    "arrow.uturn.backward.circle",
                    .openRefund(id)
                )]
            }
            return [(
                ActivityJourneyCopy.commerceViewOrders,
                "doc.text",
                .openOrders
            )]
        case .refunded:
            if let id = refundRequestID {
                return [(
                    ActivityJourneyCopy.commerceViewRefundRecord,
                    "checkmark.circle",
                    .openRefund(id)
                )]
            }
            return [(
                ActivityJourneyCopy.commerceViewOrders,
                "doc.text",
                .openOrders
            )]
        case .paid:
            return [(
                ActivityJourneyCopy.commerceViewOrders,
                "doc.text",
                .openOrders
            )]
        case .cancelled:
            return []
        }
    }
}

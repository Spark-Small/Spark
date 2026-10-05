//
//  RefundPolicy.swift
//  坐标系
//
//  活动 / 陪玩退款是否可申请的策略评估。
//

import Foundation
import CoordinateModels

enum RefundPolicy {
    struct Evaluation: Hashable {
        let allowed: Bool
        let headline: String
        let detail: String
    }

    static func evaluateActivity(activity: Activity, refundNotes: [String]) -> Evaluation {
        let now = Date.now
        if activity.date <= now {
            return Evaluation(
                allowed: false,
                headline: "活动已开始",
                detail: "活动已开始或已结束，无法在线申请退款。如有争议请联系客服。"
            )
        }

        let hoursUntil = activity.date.timeIntervalSince(now) / 3600
        if hoursUntil < 6 {
            return Evaluation(
                allowed: false,
                headline: "临近开始不可退",
                detail: "活动开始前 6 小时内不支持在线退款。如有特殊情况请联系发起人协商。"
            )
        }

        let noteText = refundNotes.isEmpty
            ? "活动开始前 6 小时可全额退款；提交后需再次确认。"
            : refundNotes.joined(separator: "；")
        return Evaluation(
            allowed: true,
            headline: "可全额退款",
            detail: noteText
        )
    }

    static func evaluateBooking(record: BuddyBookingRecord) -> Evaluation {
        guard record.canRefund else {
            return Evaluation(
                allowed: false,
                headline: "当前不可退",
                detail: "仅已支付或进行中的预约可申请退款。"
            )
        }
        let now = Date.now
        if record.endAt <= now {
            return Evaluation(
                allowed: false,
                headline: "履约已结束",
                detail: "预约时段已结束，请通过「完成订单」或联系客服处理。"
            )
        }
        let hoursUntil = record.scheduledAt.timeIntervalSince(now) / 3600
        if hoursUntil < 2 {
            return Evaluation(
                allowed: true,
                headline: "临近开始仍可退",
                detail: "距开始不足 2 小时，提交后将尽快处理，并按原支付方式退回。"
            )
        }
        return Evaluation(
            allowed: true,
            headline: "可全额退款",
            detail: "开始前 2 小时外可全额退款；提交后需再次确认。"
        )
    }

    /// 系统发起（主办取消、库存失败等）始终允许
    static let systemAllowed = Evaluation(
        allowed: true,
        headline: "系统自动退款",
        detail: "因活动变更或报名失败，系统将按原支付方式退回。"
    )
}


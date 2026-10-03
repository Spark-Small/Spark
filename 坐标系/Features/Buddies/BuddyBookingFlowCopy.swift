//
//  BuddyBookingFlowCopy.swift
//  坐标系
//
//  预约 / 邀约流程文案。
//

import CoordinateFeatureFlags
import Foundation
import CoordinateModels

nonisolated enum BuddyBookingFlowCopy {
    static let selectStepTitle = "选择档期"
    static let confirmStepTitle = "确认预约"
    static let nextStep = "下一步"
    static let submitBooking = "提交预约"
    static let unavailableTitle = BuddyDetailCopy.bookUnavailable
    static let unavailableBody = "对方档期已满或暂停接单，可先打招呼沟通时间。"
    static let unavailableDismiss = "知道了"
    static let submitBookingAccessibilityHint = "提交后等待陪玩确认；接单后需完成支付"
    static let confirmFooter = "提交后等待陪玩确认；接单后完成支付即可锁定档期。"
    static let selectedServiceSection = "已选服务"
    static let customTimeToggle = "自定义时间"
    static let startTime = "开始时间"
    static let duration = "时长"
    static func durationHours(_ hours: Int) -> String { "\(hours) 小时" }
    static let bookingTimeSection = "预约时间"
    static let scheduleEmptyHint = "对方暂未公开档期，可自选开始时间提交，等待确认。"
    static let companionLabel = "陪玩"
    static let serviceItemLabel = "服务项目"
    static let pricingLabel = "计价"
    static let totalFeeLabel = "费用合计"
    static let slotLabel = "档期"
    static let timeSlotLabel = "时段"
    static let bookingInfoSection = "预约信息"
    static let verifiedShort = "认证"
    static func priceReplyCaption(priceText: String, responseTime: String) -> String {
        "\(priceText) · \(responseTime) 回复"
    }
    static let bookingDate = "预约日期"
    static let availableSlotsHeader = "可选档期"
    static let availableSlotsFooter = "先选日期，再选当日可约时段。"
    static let emptyDayFull = "当天档期已满，请换一天。"
    static let emptyDayPending = "当天档期待开放，请稍后再约或换一天。"
    static let emptyDayDefault = "当天暂无可约时段。"
    static let inviteNoteSection = "留言"
    static let inviteSelectPromptPrefix = "邀请"
    static let inviteSelectPromptSuffix = "一起参加"
    static let invitePickActivity = "选择活动"
    static func inviteSelectPrompt(nickname: String) -> String {
        "\(inviteSelectPromptPrefix) \(nickname) \(inviteSelectPromptSuffix)"
    }
    static let conflictHint = "该时间与已有预约冲突，请改选其他时段。"
    static let waitStepSubmitted = "已提交预约"
    static let waitStepAwaitingCompanion = "等待陪玩确认"
    static let waitStepPayment = "完成支付"
    static func waitStepDoneA11y(_ title: String) -> String { "\(title)，已完成" }
    static func waitStepActiveA11y(_ title: String) -> String { "\(title)，进行中" }
    static func waitStepPendingA11y(_ title: String) -> String { "\(title)，待进行" }
    static let timeLabel = "时间"
    static var submittedHint: String {
        if FeatureFlags.useRemoteBuddies {
            return "接单后可在「我的 → 我的订单」核对并完成支付；陪玩确认后会在 App 内通知你。"
        }
        return "接单后可在「我的 → 我的订单」查看进度；陪玩通常在 30 分钟内确认，超时将自动取消。"
    }
    static let companionAcceptedPayHint = "对方已接单，请核对订单后完成支付"
    static let companionDeclinedHint = "对方已拒单"
    static let awaitingPaymentTitle = "待支付预约"
    static let orderDetailTitle = "预约订单"
    static let awaitingPaymentReviewFooter = "请核对陪玩、时间与费用后再支付。支付成功后生成预约凭证。"
    static let paymentExpiredHint = "支付超时，预约已自动取消"
    static let confirmationExpiredHint = "陪玩未在时限内确认，预约已自动取消"
    static func confirmationDeadlineFooter(for record: BuddyBookingRecord, now: Date = .now) -> String {
        guard record.status == .pendingConfirm, let due = record.confirmDueAt else {
            return "提交后请耐心等待陪玩确认；确认结果将通过通知告知你。"
        }
        if now >= due {
            return "确认时限已过，订单将自动取消。"
        }
        return "陪玩通常在 \(Formatters.activityEventTime(from: due, relativeTo: now)) 前确认；超时订单将自动取消。"
    }
    static func paymentDeadlineFooter(for record: BuddyBookingRecord, now: Date = .now) -> String {
        guard record.status == .awaitingPayment, let due = record.paymentDueAt else {
            return awaitingPaymentReviewFooter
        }
        if now >= due {
            return "支付时限已过，订单将自动释放。"
        }
        return "请在 \(Formatters.activityEventTime(from: due, relativeTo: now)) 前完成支付，超时订单将自动取消。"
    }
    static let goToPay = "去支付"
    static let payLater = "稍后支付"
    static let viewCancellationPolicy = "查看取消规则"
    static let cancellationPolicyBody = "待支付订单可随时撤回；支付后取消与退款按预约详情中的规则处理。"
    static let successTitle = "支付成功"
    static let successSubtitle = "预约凭证已生成，开场前会提醒你。"
    static let inviteConfirmTitle = "确认邀约"
    static let inviteConfirmHint = "邀约会保存在本机；接通消息与推送后，对方才能实时收到。"
    static let inviteNotePlaceholder = "补充说明（可选）"
    static let inviteSend = "发送邀约"
    static let inviteEmptyTitle = "暂无可邀约的活动"
    static let inviteEmptyBody = "先报名或发布一场活动，再邀请搭子一起参加。"
    static let inviteEmptyBrowseActivities = "去活动看看"
    static let inviteEmptyDismiss = "稍后再说"
    static let inviteSuccessTitle = "邀约已发送"
    static func inviteSuccessSubtitle(_ nickname: String) -> String {
        "已记录对 \(nickname) 的邀约；接通消息后对方才能实时收到"
    }
    static let inviteDetailTitle = "邀约详情"
    static let inviteTarget = "邀请对象"
    static let inviteActivity = "活动"
    static let inviteTime = "时间"
    static let invitePlace = "地点"
    static let inviteFee = "费用"
    static let inviteRecordTarget = "对象"
    static let inviteRecordStatus = "状态"
    static let inviteRecordSentAt = "发出"
    static let inviteMissingTitle = "邀约不存在"
    static let inviteMissingDismiss = "关闭"
    static let inviteDelete = "删除记录"
    static let viewActivity = "查看活动"
    static let buddyProfileLink = "搭子资料"
    #if DEBUG
    static let debugAdvanceAccept = "标记为已接受"
    static let debugAdvanceDecline = "标记为已婉拒"
    static let debugAdvanceHeader = "调试"
    static let debugAdvanceFooter = "仅调试构建可见；正式环境由对方回执推进。"
    #endif
    static let rescheduleSection = "改期"
    static let save = "保存"
    static let freeScheduleHint = "点选有空档的日期，可邀约 TA 一起参加活动。"

    static let submittedTitle = "预约已提交"
    static let done = "完成"
    static let cancel = "取消"
    static let back = "返回"
    static let loadingOrder = "加载订单…"
    static let orderProcessing = "订单处理中"
    static let withdrawBooking = "撤销预约"
    static let waitInBackground = "在后台等待"
    static let gotIt = "知道了"
    static let contactCompanion = "联系陪玩"
    static let openMyBookings = "查看陪玩预约"
    static let feeLabel = "费用"
    static let hoursUnit = "小时"
    static let confirmServiceCompleted = "确认服务已完成"
    static let markServiceStarted = "标记服务已开始"
    static let fulfillmentSectionFooter = "多数履约一步确认即可；如需留痕，可先标记服务已开始。"
    static let refundingFooter = "退款处理中，请耐心等待。完成前不可改期或再次申请退款。"
    static let refundedFooter = "退款已完成，金额将按原支付方式退回。"
    static let refundCTA = "申请退款"
    static let bookingRefundPolicyNote = "待支付订单可随时撤回；支付后如需取消须申请退款，审核通过后按原支付方式退回。"

    static let orderNotPayableYet = "订单尚未可支付"
    static let orderNotFound = "订单不存在"
    static let bookingCancelled = "已取消预约"
    static let bookingStarted = "预约已开始"
    static let bookingCompletedWithCheckIn = "订单已完成，可确认履约情况"
    static let bookingCompleted = "订单已完成"
    static let refundSubmitted = "退款申请已提交"
    static let refundCompleted = "退款已完成"
    static let refundRejectedRestored = "退款未通过，预约已恢复"
    static let refundInProgressCannotReschedule = "退款处理中，暂不可改期"
    static let rescheduleConflict = "改期时间与其他预约冲突"

    static func submittedStatus(for record: BuddyBookingRecord) -> String {
        switch record.status {
        case .pendingConfirm:
            return "已提交，等待 \(record.companionNickname) 确认"
        case .awaitingPayment:
            return "\(record.companionNickname) 已接单，请完成支付"
        case .cancelled:
            return "订单已取消"
        default:
            return record.status.rawValue
        }
    }
}

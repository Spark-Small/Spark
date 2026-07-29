//
//  ActivityDetailCopy.swift
//  坐标系
//
//  活动详情 / 行程 / 支付文案。动作词与 ActivityCardStatus 对齐。
//

import Foundation

enum ActivityDetailCopy {
    // MARK: - 决策卡

    static let hostMessageAccessibility = "私信发起人"
    static let calendarAction = "添加日历提醒"
    static let navigationAction = "导航前往"
    static let mapPreviewAccessibility = "查看集合地点并导航"
    static let peopleRowAccessibility = "查看已参加成员"

    static func spotsLabel(full: Bool, almostFull: Bool, remaining: Int) -> String {
        ActivityCardStatus.spotsLabel(full: full, almostFull: almostFull, remaining: remaining)
    }

    static func socialProof(joined: Int, capacity: Int, viewerWaitlisted: Bool) -> String {
        var parts = ["\(joined)/\(capacity) 人已参加"]
        if viewerWaitlisted {
            parts.append("你已候补")
        }
        return parts.joined(separator: " · ")
    }

    static let joinConfirmTitle = ActivityCardStatus.joinConfirm
    static let joinConfirmMessage = "参加后将自动加入活动群，可在开始前取消。"
    static let joinConfirmPaidHint = "确认后将进入模拟支付；支付成功自动完成参加并加入活动群。"
    static let joinConfirmNotePlaceholder = "给发起人留言（可选）"
    static let joinConfirmPayCTA = "下一步 · 支付"
    static let reportAction = "举报活动"
    static let peopleMemberRole = "已参加成员"
    static let peopleHostRole = "发起人"
    static let peopleOrganizerBadge = "组织者"
    static let peopleSheetFooter = "点头像查看资料，点消息可私信对方。其余名额以参加人数为准。"
    static let notesEditorSection = "参加须知（每行一条）"
    static let joinNotePrefix = "【参加留言】"
    static let reportReceivedTitle = ActivityCardStatus.reportReceived

    // MARK: - 支付（本地模拟）

    static let paymentTitle = "确认支付"
    static let paymentProcessing = "支付处理中…"
    static let paymentMockHint = "当前为演示支付流程，不会发起真实扣款。支付成功后将自动完成参加。"
    static let joinFailedFullAfterPayTitle = ActivityCardStatus.fullVerbose
    static let joinFailedFullAfterPayMessage = "支付完成时名额刚满，演示流程已自动退款。你可以加入候补，有空位时再参加。"

    // MARK: - 评论 / 推荐

    static let commentsTitle = "活动讨论"
    static let commentsEmpty = "还没有讨论"
    static let commentsPlaceholder = "提问或留言…"
    static let relatedTitle = "相关活动"
    static let relatedCircleTitle = "相关组织"
    static let relatedCircleFooter = "长期同好群，不只这一场；加入后进入组织群聊。"
    static let relatedCircleJoined = "进入群聊"
    static let relatedCircleJoin = "查看并加入"
    static let timelineEditorTitle = "行程安排"
    static let timelineEditorHint = "每行一条，格式：时间｜环节｜说明"
    static let gearEditorTitle = "装备清单"
    static let gearEditorHint = "按实际活动填写，留空则使用类别默认"
    static let galleryEditorTitle = "活动相册"
    static let galleryEditorHint = "除封面外最多再添加 5 张配图"

    // MARK: - 发起人管理

    static let hostManageTitle = "管理活动"
    static let hostManageCapacityTitle = "名额设置"
    static let hostManageCapacityHint = "不能低于当前已参加人数"
    static let hostManageRescheduleTitle = "改期"
    static let hostManageRescheduleHint = "改期后已参加成员会收到日历提醒更新；说明会展示在发起人补充"
    static let hostManageRescheduleNotePlaceholder = "改期说明（可选，如：因天气顺延 1 小时）"
    static let hostManageEditBasics = "编辑标题、地点与简介"
    static let hostManageCancelActivity = "取消活动"
    static let hostManageCancelHint = "取消后活动将从发现列表移除；已支付订单将演示退款，群聊会收到通知。"
    static let hostManageCancelAlertTitle = "确认取消活动？"
    static func hostManageCancelAlertMessage(title: String) -> String {
        "「\(title)」将被取消；已支付成员将收到演示退款，活动群会收到取消通知。"
    }

    static let hostManageActionsTitle = "快捷操作"
    static let hostManageViewDetail = "查看活动详情"
    static let hostManageHostedHeader = "我发起的活动"
    static let hostManageHostedSubtitle = "调整名额、改期或完善说明"

    // MARK: - 订单 / 退款

    static let ordersTitle = "活动订单"
    static let ordersEmptyTitle = "暂无订单"
    static let ordersEmptySubtitle = "付费参加后会在这里显示"
    static let orderBannerTitle = "查看支付订单"
    static let refundCTA = "申请退款"
    static let refundProcessing = "退款处理中…"
    static let refundedHint = "演示退款已完成，实际产品将原路退回"
    static let cancelWithRefundTitle = "取消参加并退款？"
    static let cancelWithRefundMessage = "你已支付本次活动费用，取消参加后可申请演示退款。"
    static let cancelWithRefundConfirm = "取消并退款"
    static let cancelOnly = "仅取消参加"

    /// 底栏参加按钮：主标题 + 可选名额副标题
    static func joinButtonLabels(
        free: Bool,
        almostFull: Bool,
        remaining: Int,
        full: Bool,
        waitlisted: Bool,
        hasOpenSpotFromWaitlist: Bool
    ) -> (primary: String, subtitle: String?) {
        if full {
            let primary = waitlisted ? ActivityCardStatus.leaveWaitlist : ActivityCardStatus.joinWaitlist
            return (primary, nil)
        }
        if hasOpenSpotFromWaitlist {
            return (ActivityCardStatus.joinPrimaryLabel(free: free), "候补名额已开放")
        }

        let primary = ActivityCardStatus.joinPrimaryLabel(free: free)
        let subtitle = almostFull
            ? spotsLabel(full: false, almostFull: true, remaining: remaining)
            : nil
        return (primary, subtitle)
    }

    // MARK: - 底栏

    static var cancelRegistration: String { ActivityCardStatus.cancelJoin }
    static var openGroupChat: String { ActivityCardStatus.openGroupChat }

    // MARK: - 分区

    static let navigationSheetTitle = "选择地图应用"
    static let recapCTA = "活动已结束 · 分享你的体验"
    static let activityEnded = "活动已结束"
    static let activityOngoing = "活动进行中"
    static let hostCancelledNotice = "发起人已取消本次活动"
    static let missingActivity = "活动不存在"

    static func askHostGreeting(title: String) -> String {
        "你好，我对「\(title)」感兴趣，想确认一下名额和集合地点，方便介绍一下吗？"
    }
}

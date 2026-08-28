//
//  ActivityDetailCopy.swift
//  坐标系
//
//  活动详情 / 行程 / 支付文案。动作词与 ActivityCardStatus 对齐。
//

import Foundation

enum ActivityDetailCopy {
    // MARK: - 决策卡

    static let askHostAction = "私信发起人"
    static let calendarAction = "添加日历提醒"
    static let calendarRemoveAction = "移除日历提醒"
    static let calendarAccessDeniedTitle = "无法访问日历"
    static let calendarAccessDeniedMessage = "请在系统设置中允许「坐标系」访问日历，以便添加活动提醒。"
    static let calendarOpenSettings = "去设置"
    static let calendarFailedMessage = "暂时无法写入日历，请稍后重试"
    static let calendarRemoveFailedMessage = "暂时无法从日历移除，请稍后重试"
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
    static let joinConfirmPaidHint = "确认后将一次性完成支付与参加，并自动加入活动群。当前为演示支付，不会发起真实扣款。"
    static let joinConfirmNotePlaceholder = "给发起人留言（可选）"
    static let joinConfirmPayCTA = "支付并参加"
    static let joinConflictHeader = "时间冲突"
    static let joinConflictFooter = "你已有行程与本场时间重叠，确认后仍可参加，请自行协调安排。"
    static func joinConflictTitle(_ count: Int) -> String {
        count == 1 ? "与 1 场已有行程冲突" : "与 \(count) 场已有行程冲突"
    }
    static let reportAction = "举报活动"
    static let reportTargetLabel = "举报对象"
    static let reportReasonLabel = "举报原因"
    static let reportDetailLabel = "情况说明"
    static let reportDetailPlaceholder = "请描述问题，便于核查"
    static let reportDetailFooter = "请尽量写清时间、地点与具体行为，避免仅写笼统评价。"
    static let reportEvidenceLabel = "证明材料"
    static let reportEvidenceAdd = "添加截图或照片"
    static func reportEvidenceSelected(_ count: Int) -> String { "已选 \(count) 张，点击更换" }
    static let reportEvidenceFooter = "可选；建议上传聊天记录、活动页截图等证明材料，最多 4 张。"
    static let reportSubmit = "提交举报"
    static let reportSubmitFooter = "恶意举报可能影响账号权限。提交前请确认材料与说明属实。"
    static let reportReasons = ["虚假信息", "欺诈或收费异常", "安全隐患", "不当内容", "其他"]
    static let reportReceivedMessage = "我们已收到对该活动的反馈，将尽快核查。"
    static let peopleMemberRole = "已参加成员"
    static let peopleHostRole = "发起人"
    static let peopleSheetBack = "返回"
    static let peopleSheetDone = "完成"
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

    static let commentsTitle = "活动评论"
    static let commentsEmpty = "还没有评论"
    static let commentsEmptyHint = "来抢沙发，问问集合地点或装备准备"
    static let commentsPlaceholder = "友善评论，分享你的问题或期待…"
    static func commentsCountTitle(_ count: Int) -> String {
        count == 0 ? commentsTitle : "\(commentsTitle) · \(count)"
    }
    static let commentsViewAll = "查看全部评论"
    static let commentsWriteFirst = "写评论…"
    static let relatedTitle = "相关活动"
    static let relatedCircleTitle = "相关圈子"
    static let credentialSectionTitle = "活动凭证"
    static let credentialReissueAction = "补发活动凭证"
    static let credentialVoidedAction = "凭证已作废"
    static let credentialViewAction = "查看活动凭证"
    static let timelineEditorTitle = "行程安排"
    static let timelineEditorHint = "每行一条，格式：时间｜环节｜说明"
    static let gearEditorTitle = "装备清单"
    static let gearEditorHint = "按实际活动填写，留空则使用类别默认"
    static let galleryEditorTitle = "活动相册"
    static let galleryEditorHint = "除封面外最多再添加 5 张照片或视频"

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

    // MARK: - 订单 / 退款

    static let ordersTitle = "活动订单"
    static let ordersEmptyTitle = "暂无订单"
    static let ordersEmptySubtitle = "付费参加后会在这里显示"
    static let orderBannerTitle = "查看支付订单"
    static let refundCTA = "申请退款"
    static let refundProcessing = "退款处理中"
    static let refundedHint = "退款已完成，可在「我的订单」查看进度"
    static let cancelWithRefundTitle = "取消参加并退款？"
    static let cancelWithRefundMessage = "你已支付本次活动费用。选择「取消并退款」后需填写退款申请，再确认才会退款。"
    static let cancelWithRefundConfirm = "取消并退款"
    static let cancelOnly = "仅取消参加"
    static let cancelUnpaidTitle = "确定取消参加？"
    static let cancelUnpaidMessage = "这场活动的名额已经为你预留，也已进入活动群。取消后名额会立刻放出，热门场次不一定还能报上，群里的集合与变动你也会错过。"
    static let cancelUnpaidKeep = "继续参加"
    static let cancelUnpaidConfirm = "确认取消"

    /// 底栏参加按钮：单行主标题（名额紧迫信息并入文案，与陪玩详情底栏对齐）
    static func joinButtonTitle(
        free: Bool,
        almostFull: Bool,
        remaining: Int,
        full: Bool,
        waitlisted: Bool,
        hasOpenSpotFromWaitlist: Bool
    ) -> String {
        if full {
            return waitlisted ? ActivityCardStatus.leaveWaitlist : ActivityCardStatus.joinWaitlist
        }
        if hasOpenSpotFromWaitlist {
            return "\(ActivityCardStatus.joinPrimaryLabel(free: free)) · \(ActivityCardStatus.waitlistSpotOpen)"
        }

        let primary = ActivityCardStatus.joinPrimaryLabel(free: free)
        if almostFull {
            return "\(primary) · \(spotsLabel(full: false, almostFull: true, remaining: remaining))"
        }
        return primary
    }

    // MARK: - 底栏

    static var cancelRegistration: String { ActivityCardStatus.cancelJoin }
    static var openGroupChat: String { ActivityCardStatus.openGroupChat }

    // MARK: - 分区

    static let navigationSheetTitle = "选择地图应用"
    static let navigationAddressField = "活动地址"
    static let recapCTA = "活动已结束 · 分享你的体验"
    static let activityEnded = "活动已结束"
    static let hostCancelledNotice = "发起人已取消本次活动"
    static let missingActivity = "活动不存在"

    static func askHostGreeting(title: String) -> String {
        "你好，我对「\(title)」感兴趣，想确认一下名额和集合地点，方便介绍一下吗？"
    }

    static let askHostQuickRepliesTitle = "快捷咨询"

    /// 向活动发起人咨询时的快捷发送模版（短标签 + 完整文案）。
    static func askHostQuickReplies(for activity: Activity) -> [(label: String, text: String)] {
        [
            ("确认名额与地点", askHostGreeting(title: activity.title)),
            ("集合时间", "请问活动大概几点集合？需要提前多久到？"),
            ("费用说明", "想了解一下费用都包含哪些内容？"),
            ("新手须知", "我是第一次参加这类活动，有什么需要特别注意的吗？"),
        ]
    }

    static let askMemberQuickRepliesTitle = "快捷打招呼"

    /// 向活动参加者打招呼时的快捷发送模版。
    static func askMemberQuickReplies(for activity: Activity) -> [(label: String, text: String)] {
        [
            ("打个招呼", "你好，我在「\(activity.title)」活动里看到你，想认识一下。"),
            ("同行安排", "请问你打算怎么过去？可以一起拼车或集合吗？"),
            ("经验交流", "你之前参加过类似活动吗？有什么建议吗？"),
            ("装备请教", "这次活动的装备/准备有什么需要注意的吗？"),
        ]
    }
}

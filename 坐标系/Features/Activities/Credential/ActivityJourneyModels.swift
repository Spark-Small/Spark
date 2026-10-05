//
//  ActivityJourneyModels.swift
//  坐标系
//
//  行程文案 / 步骤 / 下一步内容模型。
//

import Foundation
import CoordinateDomain
import CoordinateModels

enum ActivityJourneyCopy {
    static let pageTitle = "活动行程"
    static let brandName = "坐标系"
    static let departureVoided = "凭证已作废"
    static let participantFallback = "参与者"
    static let onSiteCheckIn = "到场签到"
    static let alarmReminder = "闹钟提醒"
    static let checkInPrompt = "到场后点击签到"
    static let checkInEarly = "活动当日开放签到"
    static let checkInSuccess = "签到成功，已向发起人同步到场"
    static let checkInNotYet = "活动开始前 24 小时开放签到"
    static let checkedInTitle = "已签到"
    static let checkedInAtPrefix = "签到于"
    static let voided = "已作废"
    static let nextStepTitle = "下一步"
    static let commerceSectionTitle = "支付与退款"
    static let commerceViewOrders = "查看本场支付"
    static let commerceViewRefund = "查看退款进度"
    static let commerceViewRefundRecord = "查看退款记录"

    /// 赴约四件套（约陪玩可选，由用户决定是否点）
    static let bookCompanionTitle = "约陪玩"
    static let bookCompanionSubtitle = "可选 · 需要时再约"
    static let bookCompanionAccessibilityHint = "可选，打开搭子约陪玩"
    static let openGroupChat = "进入群聊"
    static let groupChatSubtitle = "集合通知与临时变动会发在群里"
    static let navigate = "导航前往"
    static let navigateUnavailable = "暂无集合地点"
    static let gearPrepTitle = "装备要求"
    static let gearPrepSubtitle = "出发前核对随身装备"
    static let noticesTitle = "注意事项"
    static let noticesSubtitle = "安全与集合须知"

    static func progressAccessibility(rows: [ActivityJourneyTimelineRow]) -> String {
        let completed = rows.filter(\.isComplete).count
        let total = rows.count
        let current = rows.first(where: \.isCurrent)?.step.title ?? ""
        return "旅程进度，当前\(current)，已完成 \(completed) 项，共 \(total) 项"
    }
    static let detailBannerTitle = "活动详情"
    static let group = "活动群"
    static let detail = "查看活动详情"
    static let recapBannerSubtitle = "把体验分享给更多同好"
    static let shareFeedback = "分享感受"
    static let writeRecap = "写活动复盘"
    static let feedbackPrompt = "这场活动体验如何？你的反馈会帮助其他人做决定。"
    static let shareMementoTicket = "分享纪念票"
    static let mementoShareFooter = "坐标系 · 我已参加"

    static let coParticipantsTitle = "一起去的伙伴"
    static let coParticipantsSubtitle = "活动已结束，和同行的人打个招呼吧"
    static func greetParticipant(_ name: String) -> String { "打招呼 · \(name)" }
}

enum ActivityJourneyStep: String, CaseIterable, Identifiable {
    case registered
    case joinedGroup
    case dayOfReady
    case arrived
    case feedback
    case recap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .registered: "已报名"
        case .joinedGroup: "打开活动群"
        case .dayOfReady: "活动当日 · 准备出发"
        case .arrived: "到场签到"
        case .feedback: "活动反馈"
        case .recap: "发布复盘（可选）"
        }
    }
}

enum ActivityJourneyPrimaryAction: Equatable {
    case openDetail
    case openGroup
    case navigate
    case shareFeedback
    case writeRecap
    case toggleAlarmReminder
}

/// 赴约四件套 + 类目扩展格（约陪玩可选给用户点）。
enum ActivityJourneyKitAction: String, Equatable, Hashable, Identifiable {
    case bookCompanion
    case openGroup
    case navigate
    case checkIn
    /// 运动户外等：装备要求 → 打开活动详情
    case openGearPrep
    /// 有须知内容的类目：注意事项 → 打开活动详情
    case openNotices

    var id: String { rawValue }
}

struct ActivityJourneyKitItem: Equatable, Identifiable {
    let action: ActivityJourneyKitAction
    let face: ActivityJourneyGlassCardFace
    var isEnabled: Bool = true
    var isComplete: Bool = false

    var id: ActivityJourneyKitAction { action }
}

struct ActivityJourneyNextStepContent: Equatable {
    let focusStep: ActivityJourneyStep
    /// 赴约四件套；反馈 / 复盘 / 作废时为空。
    let kitItems: [ActivityJourneyKitItem]
    /// 结束后主操作（反馈 / 复盘）或作废看详情。
    let postBanner: ActivityJourneyBannerContent?
}

enum ActivityJourneyUtilityAction: Equatable {
    case checkIn
}

struct ActivityJourneyGlassCardFace: Equatable {
    let title: String
    let subtitle: String
    let systemImage: String
    var isCheckedIn: Bool = false
}

struct ActivityJourneyBannerContent: Equatable {
    let face: ActivityJourneyGlassCardFace
    let primary: ActivityJourneyPrimaryAction
}

struct ActivityJourneyTimelineRow: Identifiable {
    let step: ActivityJourneyStep
    let isComplete: Bool
    let isCurrent: Bool

    var id: String { step.id }
}

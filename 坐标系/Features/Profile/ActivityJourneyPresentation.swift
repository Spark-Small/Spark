//
//  ActivityJourneyPresentation.swift
//  坐标系
//
//  活动旅程：阶段文案、时间线节点、glass 卡面数据（Activity + ParticipationLifecycle）。
//

import Foundation
import CoordinateDomain
import CoordinateModels

enum ActivityJourneyCopy {
    static let pageTitle = "我的行程"
    static let openAction = "打开我的行程"
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
    static let alarmEnabled = "已开启 T-24h / T-1h"
    static let alarmDisabled = "点击开启 T-24h / T-1h"
    static let alarmUnavailable = "凭证已作废"
    static let voided = "已作废"
    static let nextStepTitle = "下一步"

    static func progressAccessibility(rows: [ActivityJourneyTimelineRow]) -> String {
        let completed = rows.filter(\.isComplete).count
        let total = rows.count
        let current = rows.first(where: \.isCurrent)?.step.title ?? ""
        return "旅程进度，当前\(current)，已完成 \(completed) 项，共 \(total) 项"
    }
    static let detailBannerTitle = "活动详情"
    static let navigate = "导航前往"
    static let group = "活动群"
    static let detail = "查看活动详情"
    static let groupChatSubtitle = "集合通知与临时变动会发在群里"
    static let inProgressTitle = "活动进行中"
    static let inProgressBannerSubtitle = "查看现场信息与讨论"
    static let preparingBannerSubtitle = "查看集合点、费用与参加须知"
    static let recapBannerSubtitle = "把体验分享给更多同好"
    static let voidedPlaceholder = "—"
    static let shareFeedback = "分享感受"
    static let writeRecap = "写活动复盘"
    static let feedbackThanks = "感谢参与"
    static let feedbackPrompt = "这场活动体验如何？你的反馈会帮助其他人做决定。"
    static let shareMementoTicket = "分享纪念票"
    static let mementoShareFooter = "坐标系 · 我已参加"
    static let addToWallet = "加入 Apple Wallet"

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

struct ActivityJourneyUtilityStatusRow: Equatable, Identifiable {
    let action: ActivityJourneyUtilityAction
    let title: String
    let subtitle: String
    let systemImage: String
    var isComplete: Bool = false

    var id: ActivityJourneyUtilityAction { action }
}

struct ActivityJourneyNextStepContent: Equatable {
    let focusStep: ActivityJourneyStep
    let banner: ActivityJourneyBannerContent
    let interactiveUtilities: [ActivityJourneyUtilityCard]
    let statusRows: [ActivityJourneyUtilityStatusRow]
}

enum ActivityJourneyUtilityAction: Equatable {
    case checkIn
    case toggleAlarmReminder
}

struct ActivityJourneyGlassCardFace: Equatable {
    let title: String
    let subtitle: String
    let systemImage: String
    var isCheckedIn: Bool = false
}

struct ActivityJourneyUtilityCard: Equatable {
    let face: ActivityJourneyGlassCardFace
    let action: ActivityJourneyUtilityAction
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

enum ActivityJourneyPresentation {
    static func phase(
        for activity: Activity,
        progress: ActivityParticipationProgress?,
        participatesInJourney: Bool,
        now: Date = .now
    ) -> ActivityParticipationPhase? {
        ActivityParticipationLifecycle.phase(
            for: activity,
            progress: progress,
            isJoined: participatesInJourney,
            now: now
        )
    }

    static func passStatus(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        voided: Bool,
        now: Date = .now
    ) -> (title: String, subtitle: String) {
        if voided {
            return ("凭证已作废", "如需帮助可在菜单中联系平台")
        }
        guard let phase else {
            return ("行程确认", "请查看下方集合信息")
        }
        switch phase {
        case .registered:
            return ("座位已确认", countdown(to: activity.date, now: now))
        case .preparing:
            return ("准备出发", countdown(to: activity.date, now: now))
        case .dayOf:
            return ("今日出发", "请按集合时间前往目的地")
        case .inProgress:
            return ("活动进行中", "祝你玩得开心")
        case .awaitingFeedback:
            return ("感谢参与", "欢迎分享你的体验")
        case .recapEligible:
            return ("旅程已完成", "可以写复盘或看看下一场")
        case .closed:
            return ("纪念行程", "感谢一起完成这趟旅程")
        }
    }

    /// 参与者在本次活动中的稳定座位号（活动 + 用户 seed，不含随机假字段）。
    static func seatNumber(activityID: UUID, userID: UUID) -> String {
        let seat = (abs(activityID.stableSeed) ^ abs(userID.stableSeed)) % 999 + 1
        return String(format: "%03d", seat)
    }

    /// 标题下方单行：「今日出发：8月30日 14:00·星期六」；前缀随阶段变化。
    static func departureScheduleLine(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        voided: Bool,
        now: Date = .now
    ) -> String {
        if voided {
            return ActivityJourneyCopy.departureVoided
        }
        let headline = passStatus(for: activity, phase: phase, voided: false, now: now).title
        let detail = scheduleDetail(from: activity.date)
        return "\(headline)：\(detail)"
    }

    private static func scheduleDetail(from date: Date) -> String {
        let monthDay = Formatters.monthDay.string(from: date)
        let time = Formatters.shortTime.string(from: date)
        let weekday = Formatters.weekday.string(from: date)
        return "\(monthDay) \(time)·\(weekday)"
    }

    /// 票面参与者昵称（不含 UID）。
    static func participantNickname(name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? ActivityJourneyCopy.participantFallback : trimmedName
    }

    /// 票面参与者：`昵称 · UID`（与资料页 UID 展示一致）。
    static func participantLine(name: String, uidDisplay: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameLine = trimmedName.isEmpty ? ActivityJourneyCopy.participantFallback : trimmedName
        let trimmedUID = uidDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUID.isEmpty else { return nameLine }
        return "\(nameLine) · \(trimmedUID)"
    }

    /// 集合时间已在票面标题区展示；此处仅保留座位与费用。
    static func passMetricsLine(
        activity: Activity,
        activityID: UUID,
        userID: UUID
    ) -> (seat: String, fee: String) {
        (
            seat: seatNumber(activityID: activityID, userID: userID),
            fee: activity.isFree ? "免费" : activity.fee
        )
    }

    /// 下一步区：主 banner + 次级工具 + 只读状态行（与 `focusStep` / 时间线对齐）。
    static func nextStepContent(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress?,
        voided: Bool,
        isOnCalendar: Bool,
        showsNavigate: Bool
    ) -> ActivityJourneyNextStepContent {
        if voided {
            return ActivityJourneyNextStepContent(
                focusStep: .registered,
                banner: ActivityJourneyBannerContent(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.detailBannerTitle,
                        subtitle: ActivityJourneyCopy.detail,
                        systemImage: "calendar"
                    ),
                    primary: .openDetail
                ),
                interactiveUtilities: [],
                statusRows: []
            )
        }

        let progress = progress ?? ActivityParticipationProgress(activityID: activity.id)
        let focusStep = focusTimelineStep(
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar
        )
        let banner = banner(
            for: focusStep,
            activity: activity,
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar,
            showsNavigate: showsNavigate
        )
        let utilities = secondaryUtilities(
            focusStep: focusStep,
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar
        )
        return ActivityJourneyNextStepContent(
            focusStep: focusStep,
            banner: banner,
            interactiveUtilities: utilities.interactive,
            statusRows: utilities.status
        )
    }

    static func canCheckIn(
        phase: ActivityParticipationPhase?,
        markedArrived: Bool,
        voided: Bool
    ) -> Bool {
        guard !voided, !markedArrived else { return false }
        switch phase {
        case .dayOf, .inProgress:
            return true
        default:
            return false
        }
    }

    private static func checkedInSubtitle(arrivedAt: Date?) -> String {
        guard let arrivedAt else { return ActivityJourneyCopy.checkedInTitle }
        return "\(ActivityJourneyCopy.checkedInAtPrefix) \(Formatters.shortTime.string(from: arrivedAt))"
    }

    private static func alarmUtilityFace(
        isOnCalendar: Bool,
        voided: Bool
    ) -> ActivityJourneyGlassCardFace {
        ActivityJourneyGlassCardFace(
            title: ActivityJourneyCopy.alarmReminder,
            subtitle: alarmReminderSubtitle(isOnCalendar: isOnCalendar, voided: voided),
            systemImage: alarmSymbol(isScheduled: isOnCalendar && !voided)
        )
    }

    private static func alarmSymbol(isScheduled: Bool) -> String {
        isScheduled ? "alarm.waves.left.and.right.fill" : "alarm.fill"
    }

    private static func alarmReminderSubtitle(isOnCalendar: Bool, voided: Bool) -> String {
        if voided { return ActivityJourneyCopy.alarmUnavailable }
        return isOnCalendar
            ? ActivityJourneyCopy.alarmEnabled
            : ActivityJourneyCopy.alarmDisabled
    }

    static func timeline(
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress?,
        isOnCalendar: Bool,
        activityID: Activity.ID,
        focusStep: ActivityJourneyStep? = nil
    ) -> [ActivityJourneyTimelineRow] {
        let progress = progress ?? ActivityParticipationProgress(activityID: activityID)
        let resolvedFocus = focusStep ?? focusTimelineStep(
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar
        )

        let completed: [ActivityJourneyStep: Bool] = [
            .registered: true,
            .joinedGroup: progress.openedActivityGroup,
            .dayOfReady: isDayOfReadyComplete(phase: phase, isOnCalendar: isOnCalendar),
            .arrived: progress.markedArrived,
            .feedback: progress.feedbackSubmitted || progress.feedbackSkipped,
            .recap: progress.recapPublished || progress.recapSkipped
        ]

        return ActivityJourneyStep.allCases.map { step in
            ActivityJourneyTimelineRow(
                step: step,
                isComplete: completed[step] ?? false,
                isCurrent: step == resolvedFocus
            )
        }
    }

    static func focusTimelineStep(
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress,
        isOnCalendar: Bool
    ) -> ActivityJourneyStep {
        if !progress.openedActivityGroup { return .joinedGroup }
        if (phase == .registered || phase == .preparing) && !isOnCalendar { return .dayOfReady }

        switch phase {
        case .registered, .preparing:
            return .dayOfReady
        case .dayOf:
            return progress.markedArrived ? .arrived : .dayOfReady
        case .inProgress:
            return .arrived
        case .awaitingFeedback:
            return .feedback
        case .recapEligible, .closed, nil:
            return .recap
        }
    }

    private static func banner(
        for focusStep: ActivityJourneyStep,
        activity: Activity,
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress,
        isOnCalendar: Bool,
        showsNavigate: Bool
    ) -> ActivityJourneyBannerContent {
        switch focusStep {
        case .registered, .joinedGroup:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.group,
                    subtitle: ActivityJourneyCopy.groupChatSubtitle,
                    systemImage: "bubble.left.and.bubble.right.fill"
                ),
                primary: .openGroup
            )
        case .dayOfReady:
            if phase == .dayOf && showsNavigate {
                return ActivityJourneyBannerContent(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.navigate,
                        subtitle: activity.location,
                        systemImage: "map.fill"
                    ),
                    primary: .navigate
                )
            }
            if phase == .dayOf {
                return ActivityJourneyBannerContent(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.group,
                        subtitle: ActivityJourneyCopy.groupChatSubtitle,
                        systemImage: "bubble.left.and.bubble.right.fill"
                    ),
                    primary: .openGroup
                )
            }
            if !isOnCalendar {
                return ActivityJourneyBannerContent(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.alarmReminder,
                        subtitle: ActivityJourneyCopy.alarmDisabled,
                        systemImage: "alarm.fill"
                    ),
                    primary: .toggleAlarmReminder
                )
            }
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.detailBannerTitle,
                    subtitle: ActivityJourneyCopy.preparingBannerSubtitle,
                    systemImage: "calendar"
                ),
                primary: .openDetail
            )
        case .arrived:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.inProgressTitle,
                    subtitle: ActivityJourneyCopy.inProgressBannerSubtitle,
                    systemImage: "sparkles"
                ),
                primary: .openDetail
            )
        case .feedback:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.shareFeedback,
                    subtitle: ActivityJourneyCopy.feedbackPrompt,
                    systemImage: "hand.thumbsup"
                ),
                primary: .shareFeedback
            )
        case .recap:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.writeRecap,
                    subtitle: ActivityJourneyCopy.recapBannerSubtitle,
                    systemImage: "square.and.pencil"
                ),
                primary: .writeRecap
            )
        }
    }

    private static func secondaryUtilities(
        focusStep: ActivityJourneyStep,
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress,
        isOnCalendar: Bool
    ) -> (interactive: [ActivityJourneyUtilityCard], status: [ActivityJourneyUtilityStatusRow]) {
        var interactive: [ActivityJourneyUtilityCard] = []
        var status: [ActivityJourneyUtilityStatusRow] = []

        if isOnCalendar {
            status.append(
                ActivityJourneyUtilityStatusRow(
                    action: .toggleAlarmReminder,
                    title: ActivityJourneyCopy.alarmReminder,
                    subtitle: ActivityJourneyCopy.alarmEnabled,
                    systemImage: "alarm.waves.left.and.right.fill",
                    isComplete: true
                )
            )
        } else if focusStep != .dayOfReady {
            interactive.append(
                ActivityJourneyUtilityCard(
                    face: alarmUtilityFace(isOnCalendar: false, voided: false),
                    action: .toggleAlarmReminder
                )
            )
        }

        if progress.markedArrived {
            status.append(
                ActivityJourneyUtilityStatusRow(
                    action: .checkIn,
                    title: ActivityJourneyCopy.checkedInTitle,
                    subtitle: checkedInSubtitle(arrivedAt: progress.arrivedAt),
                    systemImage: "checkmark.circle.fill",
                    isComplete: true
                )
            )
        } else if canCheckIn(phase: phase, markedArrived: false, voided: false) {
            interactive.append(
                ActivityJourneyUtilityCard(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.onSiteCheckIn,
                        subtitle: ActivityJourneyCopy.checkInPrompt,
                        systemImage: "figure.wave"
                    ),
                    action: .checkIn
                )
            )
        } else {
            status.append(
                ActivityJourneyUtilityStatusRow(
                    action: .checkIn,
                    title: ActivityJourneyCopy.onSiteCheckIn,
                    subtitle: ActivityJourneyCopy.checkInEarly,
                    systemImage: "figure.wave"
                )
            )
        }

        return (interactive, status)
    }

    private static func isDayOfReadyComplete(
        phase: ActivityParticipationPhase?,
        isOnCalendar: Bool
    ) -> Bool {
        guard let phase else { return false }
        switch phase {
        case .dayOf, .inProgress, .awaitingFeedback, .recapEligible, .closed:
            return true
        case .preparing:
            return isOnCalendar
        case .registered:
            return false
        }
    }

    private static func countdown(to date: Date, now: Date) -> String {
        countdownDescription(to: date, now: now)
    }

    static func countdownDescription(to date: Date, now: Date = .now) -> String {
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return "活动已开始" }
        let totalHours = Int(interval / 3600)
        let days = totalHours / 24
        let hours = totalHours % 24
        if days > 0 {
            return "还有 \(days) 天 \(hours) 小时"
        }
        if hours > 0 {
            return "还有 \(hours) 小时"
        }
        let minutes = max(1, Int(interval / 60))
        return "还有 \(minutes) 分钟"
    }
}

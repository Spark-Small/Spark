//
//  ActivityJourneyPresentation.swift
//  坐标系
//
//  活动旅程：阶段、时间线、票面状态（下一步见 ActivityJourneyNextStepPresentation）。
//

import Foundation
import CoordinateDomain
import CoordinateModels

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

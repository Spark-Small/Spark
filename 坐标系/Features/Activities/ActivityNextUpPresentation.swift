//
//  ActivityNextUpPresentation.swift
//  坐标系
//
//  活动下一场 Continue / 发现引导共用摘要。
//

import Foundation
import CoordinateDomain
import CoordinateModels

@MainActor
enum ActivityNextUpPresentation {
    enum Copy {
        static let sectionTitle = "下一场"
        static let pendingPrepHint = "还有 %d 项准备没完成"
    }

    enum DiscoverPromo {
        static let title = "找一场一起玩"
        static let subtitle = "挑一场参加，或自己发起"
        static let accessibilityHint = "滚动到可参加的活动"
    }

    enum Phase: Equatable {
        case preparing
        case today
        case inProgress
        case ended

        var identityKey: String {
            switch self {
            case .preparing: "preparing"
            case .today: "today"
            case .inProgress: "inProgress"
            case .ended: "ended"
            }
        }
    }

    enum NextUpAction: Equatable {
        case openJourney
        case navigate
    }

    struct Summary: Identifiable, Equatable {
        let activity: Activity
        let phase: Phase
        let headline: String
        let pendingHint: String?
        let primaryAction: NextUpAction

        var id: UUID { activity.id }

        var promoTitle: String { activity.title }

        var promoSubtitle: String {
            let actionHint = trailingActionTitle
            if let pendingHint {
                return "\(Copy.sectionTitle) · \(pendingHint) · \(actionHint)"
            }
            return "\(Copy.sectionTitle) · \(headline) · \(actionHint)"
        }

        var promoContent: (title: String, subtitle: String) {
            (promoTitle, promoSubtitle)
        }

        var promoAccessibilitySummary: String {
            "\(Copy.sectionTitle)，\(activity.title)，\(promoSubtitle)"
        }

        var trailingActionTitle: String {
            switch primaryAction {
            case .openJourney: ActivityDetailCopy.credentialViewAction
            case .navigate: ActivityDetailCopy.navigationAction
            }
        }

        func promoIdentity(calendarSyncRevision: Int) -> String {
            [
                activity.id.uuidString,
                String(calendarSyncRevision),
                phase.identityKey,
                pendingHint ?? "complete",
                headline
            ].joined(separator: "|")
        }
    }

    private static let bannerWindow: TimeInterval = 7 * 24 * 3600

    /// 非主理人、已报名场次队列（已结束且复盘完成的场次不占位）。
    static func journeyQueue(from activities: ActivitiesModel) -> [Activity] {
        activities.joinedActivities.filter { activity in
            guard !activities.isHost(activity) else { return false }
            if !activity.isLifecycleEnded { return true }
            let progress = activities.participationRecord(for: activity.id)
            let recapDone = progress?.recapPublished == true || progress?.recapSkipped == true
            return !recapDone
        }
    }

    static func summary(
        for activities: ActivitiesModel,
        hasSeenWelcomeGuide: Bool,
        now: Date = .now
    ) -> Summary? {
        guard hasSeenWelcomeGuide else { return nil }
        guard let activity = nextJoinedActivity(from: activities, now: now) else { return nil }
        guard isWithinBannerWindow(activity: activity, now: now) else { return nil }

        let progress = activities.participationRecord(for: activity.id)
            ?? ActivityParticipationProgress(activityID: activity.id)
        let phase = resolvePhase(for: activity, now: now)
        let pendingCount = pendingPrepCount(
            phase: phase,
            progress: progress,
            activityID: activity.id
        )

        let headline: String
        switch phase {
        case .preparing:
            headline = "\(Formatters.activityEventTime(from: activity.date)) 出发 · \(ActivityJourneyPresentation.countdownDescription(to: activity.date, now: now))"
        case .today:
            headline = "今天 \(Formatters.shortTime.string(from: activity.date)) 出发"
        case .inProgress:
            headline = "活动进行中"
        case .ended:
            headline = "玩得怎么样？"
        }

        let pendingHint = pendingCount > 0
            ? String(format: Copy.pendingPrepHint, pendingCount)
            : nil
        let primaryAction: NextUpAction = (phase == .today || phase == .inProgress) ? .navigate : .openJourney

        return Summary(
            activity: activity,
            phase: phase,
            headline: headline,
            pendingHint: pendingHint,
            primaryAction: primaryAction
        )
    }

    private static func pendingPrepCount(
        phase: Phase,
        progress: ActivityParticipationProgress,
        activityID: Activity.ID
    ) -> Int {
        var count = 0

        if phase != .ended {
            if !progress.openedActivityGroup { count += 1 }
            if !ActivityCalendar.isScheduled(activityID: activityID) { count += 1 }
        }

        if phase == .today || phase == .inProgress, !progress.markedArrived {
            count += 1
        }

        if phase == .ended || phase == .inProgress {
            let feedbackDone = progress.feedbackSubmitted || progress.feedbackSkipped
            if !feedbackDone { count += 1 }
            let recapDone = progress.recapPublished || progress.recapSkipped
            if feedbackDone, !recapDone { count += 1 }
        }

        return count
    }

    private static func isWithinBannerWindow(activity: Activity, now: Date) -> Bool {
        if activity.isLifecycleEnded {
            return now.timeIntervalSince(activity.date) <= bannerWindow
        }
        return activity.date.timeIntervalSince(now) <= bannerWindow
    }

    private static func nextJoinedActivity(
        from activities: ActivitiesModel,
        now: Date
    ) -> Activity? {
        _ = now
        return journeyQueue(from: activities).first
    }

    static func resolvePhase(for activity: Activity, now: Date = .now) -> Phase {
        if activity.isLifecycleEnded { return .ended }
        let calendar = Calendar.current
        if activity.date <= now, !activity.isLifecycleEnded { return .inProgress }
        if calendar.isDateInToday(activity.date) { return .today }
        return .preparing
    }
}

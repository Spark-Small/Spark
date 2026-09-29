//
//  ActivityParticipationLifecycle.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public enum ActivityParticipationLifecycle {
    /// 已参加用户当前所处旅程阶段；未参加返回 `nil`。
    public static func phase(
        for activity: Activity,
        progress: ActivityParticipationProgress?,
        isJoined: Bool,
        now: Date = .now
    ) -> ActivityParticipationPhase? {
        guard isJoined else { return nil }

        let progress = progress ?? ActivityParticipationProgress(activityID: activity.id)

        if progress.recapPublished || progress.recapSkipped {
            return .closed
        }
        if progress.feedbackSubmitted || progress.feedbackSkipped {
            return .recapEligible
        }

        let lifecycle = ActivityLifecycle.phase(for: activity, now: now)
        switch lifecycle {
        case .ended:
            return .awaitingFeedback
        case .ongoing:
            return .inProgress
        case .upcoming:
            break
        }

        let hoursUntil = activity.date.timeIntervalSince(now) / 3600
        if hoursUntil <= 24 || progress.markedArrived {
            return .dayOf
        }
        if hoursUntil <= 72 {
            return .preparing
        }
        return .registered
    }

    public static func canPublishRecap(
        for activity: Activity,
        progress: ActivityParticipationProgress?,
        isJoined: Bool,
        now: Date = .now
    ) -> Bool {
        phase(for: activity, progress: progress, isJoined: isJoined, now: now) == .recapEligible
    }
}

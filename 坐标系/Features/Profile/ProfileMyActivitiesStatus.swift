//
//  ProfileMyActivitiesStatus.swift
//  坐标系
//
//  「我的活动」角标：与发现 `ActivityCardStatus` 词表看齐（已参加 / 已候补 / 已结束 / 我发起的）。
//  阶段仍用 `resolvePhase` 区分「已结束」；不做待出发/已报名第二套词。
//

import Foundation
import CoordinateModels

@MainActor
enum ProfileMyActivitiesStatusPresentation {
    /// 场次卡左上角标：对齐活动卡状态词。
    static func badge(
        for activity: Activity,
        isHost: Bool,
        isWaitlisted: Bool = false,
        now: Date = .now
    ) -> String {
        let phase = ActivityNextUpPresentation.resolvePhase(for: activity, now: now)
        if phase == .ended {
            return ActivityCardStatus.ended
        }
        if isHost {
            return ActivityCardStatus.hosting
        }
        if isWaitlisted {
            return ActivityCardStatus.waitlisted
        }
        return ActivityCardStatus.joined
    }
}

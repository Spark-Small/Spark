//
//  ActivityLifecycle.swift
//  坐标系
//
//  本地推导的活动生命周期（无服务端场次时，用开始时间 + 宽限窗口）。
//

import Foundation

enum ActivityLifecyclePhase: Equatable, Sendable {
    case upcoming
    case ongoing
    case ended

    var allowsJoining: Bool {
        switch self {
        case .upcoming, .ongoing: true
        case .ended: false
        }
    }

    var statusLabel: String? {
        switch self {
        case .upcoming: nil
        case .ongoing: "进行中"
        case .ended: "已结束"
        }
    }
}

enum ActivityLifecycle {
    /// 开始后视作「进行中」的默认时长；超过则本地视为已结束。
    static let ongoingGrace: TimeInterval = 3 * 3600

    static func phase(for activity: Activity, now: Date = .now) -> ActivityLifecyclePhase {
        if activity.date > now { return .upcoming }
        if now.timeIntervalSince(activity.date) < ongoingGrace { return .ongoing }
        return .ended
    }
}

extension Activity {
    var lifecyclePhase: ActivityLifecyclePhase {
        ActivityLifecycle.phase(for: self)
    }

    var isLifecycleEnded: Bool {
        lifecyclePhase == .ended
    }

    /// 是否仍可报名（生命周期未结束且未满员）
    var isJoinable: Bool {
        lifecyclePhase.allowsJoining && !isFull
    }

    /// 本地推算的结束时间（与生命周期宽限一致，用于行程冲突检测）
    var estimatedEndDate: Date {
        date.addingTimeInterval(ActivityLifecycle.ongoingGrace)
    }

    var estimatedTimeRange: Range<Date> {
        date..<estimatedEndDate
    }

    func scheduleOverlaps(_ other: Activity) -> Bool {
        id != other.id && estimatedTimeRange.overlaps(other.estimatedTimeRange)
    }
}

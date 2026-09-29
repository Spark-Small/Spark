//
//  ActivityLifecycle.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public enum ActivityLifecyclePhase: Equatable, Sendable {
    case upcoming
    case ongoing
    case ended

    public var allowsJoining: Bool {
        switch self {
        case .upcoming, .ongoing: true
        case .ended: false
        }
    }
}

public enum ActivityLifecycle {
    /// 开始后视作「进行中」的默认时长；超过则本地视为已结束。
    public static let ongoingGrace: TimeInterval = 3 * 3600

    public static func phase(for activity: Activity, now: Date = .now) -> ActivityLifecyclePhase {
        if activity.date > now { return .upcoming }
        if now.timeIntervalSince(activity.date) < ongoingGrace { return .ongoing }
        return .ended
    }
}

public extension Activity {
    func lifecyclePhase(now: Date = .now) -> ActivityLifecyclePhase {
        ActivityLifecycle.phase(for: self, now: now)
    }

    var isLifecycleEnded: Bool {
        lifecyclePhase() == .ended
    }

    func isLifecycleEnded(at now: Date) -> Bool {
        lifecyclePhase(now: now) == .ended
    }

    /// 是否仍可报名（生命周期未结束且未满员）
    func isJoinable(now: Date = .now) -> Bool {
        lifecyclePhase(now: now).allowsJoining && !isFull
    }
}

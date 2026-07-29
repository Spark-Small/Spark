//
//  ActivityEngagementStore.swift
//  坐标系
//
//  隐式反馈引擎：把「浏览详情 / 收藏 / 报名」这些真实转化行为，
//  按标签与品类累积成动态兴趣权重，喂给 ActivityRecommender 做二次排序。
//  比只认引导页勾选的静态兴趣更贴近「这个人真正会点开、会报名」，
//  是提升推荐流转化率与复访率（DAU）最直接的杠杆。
//

import Foundation
import Observation

/// 一次行为对应的隐式信号强度：报名 > 收藏 > 仅查看。
enum ActivityEngagementEvent {
    case viewed
    case favorited
    case joined

    var weight: Double {
        switch self {
        case .viewed: 1
        case .favorited: 3
        case .joined: 7
        }
    }
}

@MainActor
@Observable
final class ActivityEngagementStore {
    static let shared = ActivityEngagementStore()

    /// 权重每天衰减一次，让近期行为主导排序，旧信号慢慢退场（保持推荐「新鲜」）
    private static let dailyDecay = 0.9
    private static let maxWeight = 60.0
    private static let dropBelow = 0.4

    private var snapshot: ActivityEngagementSnapshot

    private init() {
        snapshot = AppPersistence.loadEngagement()
        applyDecayIfNeeded()
    }

    func record(_ event: ActivityEngagementEvent, for activity: Activity) {
        applyDecayIfNeeded()
        for tag in activity.tags {
            snapshot.tagWeights[tag] = min(Self.maxWeight, (snapshot.tagWeights[tag] ?? 0) + event.weight)
        }
        let categoryKey = activity.category.rawValue
        snapshot.categoryWeights[categoryKey] = min(
            Self.maxWeight,
            (snapshot.categoryWeights[categoryKey] ?? 0) + event.weight
        )
        persist()
    }

    /// 活动命中的隐式兴趣分，压缩进 0...cap 供推荐打分叠加
    func implicitScore(for activity: Activity, cap: Int) -> Int {
        guard !snapshot.tagWeights.isEmpty || !snapshot.categoryWeights.isEmpty else { return 0 }
        var raw = 0.0
        for tag in activity.tags {
            raw += snapshot.tagWeights[tag] ?? 0
        }
        raw += (snapshot.categoryWeights[activity.category.rawValue] ?? 0) * 0.5
        guard raw > 0 else { return 0 }
        return min(cap, Int(raw))
    }

    /// 品类整体热度：用于给「因为你喜欢 / 品类」货架排序，让真正被点/被约的品类靠前
    func categoryAffinity(_ category: ActivityCategory) -> Double {
        snapshot.categoryWeights[category.rawValue] ?? 0
    }

    /// 标签整体热度：用于给「因为你喜欢 X」货架排序
    func tagAffinity(_ tag: String) -> Double {
        snapshot.tagWeights[tag] ?? 0
    }

    private func applyDecayIfNeeded() {
        let calendar = Calendar.current
        guard let days = calendar.dateComponents([.day], from: snapshot.lastDecayAt, to: .now).day,
              days > 0
        else { return }
        let factor = pow(Self.dailyDecay, Double(days))
        for key in snapshot.tagWeights.keys {
            snapshot.tagWeights[key, default: 0] *= factor
        }
        for key in snapshot.categoryWeights.keys {
            snapshot.categoryWeights[key, default: 0] *= factor
        }
        snapshot.tagWeights = snapshot.tagWeights.filter { $0.value > Self.dropBelow }
        snapshot.categoryWeights = snapshot.categoryWeights.filter { $0.value > Self.dropBelow }
        snapshot.lastDecayAt = .now
        persist()
    }

    private func persist() {
        AppPersistence.saveEngagement(snapshot)
    }

    func reloadFromDisk() {
        snapshot = AppPersistence.loadEngagement()
        applyDecayIfNeeded()
    }
}

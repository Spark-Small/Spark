//
//  MembershipAdImpressionStore.swift
//  坐标系
//
//  会员广告位本地曝光账本（view-through / click-through）。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class MembershipAdImpressionStore {
    static var shared: MembershipAdImpressionStore { AppComposition.membershipAdImpressionStore }
    /// 最短停留后再记一次 view-through（秒），避免闪现误计。
    static let minimumViewDuration: TimeInterval = 1

    private static let viewCountKey = "profile.membership.ad.viewCount"
    private static let tapCountKey = "profile.membership.ad.tapCount"
    private static let lastViewAtKey = "profile.membership.ad.lastViewAt"
    private static let lastTapAtKey = "profile.membership.ad.lastTapAt"
    private static let lastViewWasMemberKey = "profile.membership.ad.lastViewWasMember"
    private static let lastTapWasMemberKey = "profile.membership.ad.lastTapWasMember"

    private(set) var viewCount: Int
    private(set) var tapCount: Int

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        viewCount = defaults.integer(forKey: Self.viewCountKey)
        tapCount = defaults.integer(forKey: Self.tapCountKey)
    }

    /// 对应 `AppImpression.handleView()`：结束展示时记录 view-through。
    func handleView(isActive: Bool) async throws {
        viewCount += 1
        defaults.set(viewCount, forKey: Self.viewCountKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.lastViewAtKey)
        defaults.set(isActive, forKey: Self.lastViewWasMemberKey)
    }

    /// 对应 `AppImpression.handleTap()`：有效点击后记录 click-through。
    func handleTap(isActive: Bool) async throws {
        tapCount += 1
        defaults.set(tapCount, forKey: Self.tapCountKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.lastTapAtKey)
        defaults.set(isActive, forKey: Self.lastTapWasMemberKey)
    }

    /// 是否应记曝光：需满足最短可见时长，且本轮会话尚未记过。
    func shouldRecordView(appearedAt: Date?, alreadyRecorded: Bool) -> Bool {
        guard !alreadyRecorded, let appearedAt else { return false }
        return Date().timeIntervalSince(appearedAt) >= Self.minimumViewDuration
    }

    func reset() {
        viewCount = 0
        tapCount = 0
        [
            Self.viewCountKey, Self.tapCountKey, Self.lastViewAtKey, Self.lastTapAtKey,
            Self.lastViewWasMemberKey, Self.lastTapWasMemberKey
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    #if DEBUG
    func resetForDebug() { reset() }
    #endif
}

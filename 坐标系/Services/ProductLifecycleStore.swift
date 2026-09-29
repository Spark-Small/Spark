//
//  ProductLifecycleStore.swift
//  坐标系
//
//  产品生命周期：安装 / 打开次数 / 回流提示（本地演示）。
//

import Foundation
import Observation
import CoordinateModels

enum ProductLifecyclePhase: String, Codable {
    case new
    case active
    case returning
}

struct ProductLifecycleTip: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

@MainActor
@Observable
final class ProductLifecycleStore {
    static var shared: ProductLifecycleStore { AppComposition.productLifecycleStore }

    private enum Key {
        static let installAt = "lifecycle.installAt"
        static let lastOpenedAt = "lifecycle.lastOpenedAt"
        static let openCount = "lifecycle.openCount"
        static let dismissedTips = "lifecycle.dismissedTips"
        static let lastVersionSeen = "lifecycle.lastVersionSeen"
        static let tabVisits = "lifecycle.tabVisits"
    }

    private struct TabVisitRecord: Codable {
        let tab: String
        let date: Date
    }

    private(set) var installAt: Date
    private(set) var lastOpenedAt: Date?
    private(set) var openCount: Int
    private(set) var dismissedTipIDs: Set<String>
    private(set) var phase: ProductLifecyclePhase = .new

    init() {
        let defaults = UserDefaults.standard
        let resolvedInstall: Date
        if let stamp = defaults.object(forKey: Key.installAt) as? Date {
            resolvedInstall = stamp
        } else {
            resolvedInstall = .now
            defaults.set(resolvedInstall, forKey: Key.installAt)
        }
        let resolvedLastOpen = defaults.object(forKey: Key.lastOpenedAt) as? Date
        let resolvedOpenCount = defaults.integer(forKey: Key.openCount)
        let dismissed = defaults.stringArray(forKey: Key.dismissedTips) ?? []
        let resolvedPhase: ProductLifecyclePhase
        if resolvedOpenCount <= 1 {
            resolvedPhase = .new
        } else if let resolvedLastOpen,
                  let gap = Calendar.current.dateComponents([.day], from: resolvedLastOpen, to: .now).day,
                  gap >= 7 {
            resolvedPhase = .returning
        } else {
            resolvedPhase = .active
        }
        installAt = resolvedInstall
        lastOpenedAt = resolvedLastOpen
        openCount = resolvedOpenCount
        dismissedTipIDs = Set(dismissed)
        phase = resolvedPhase
    }

    var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installAt, to: .now).day ?? 0
    }

    var daysSinceLastOpen: Int? {
        guard let lastOpenedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: lastOpenedAt, to: .now).day
    }

    var versionLabel: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// 进入主 Tab 时记一次打开；用于回流与运营触达。
    func recordOpen() {
        let defaults = UserDefaults.standard
        let previousOpen = lastOpenedAt
        if let previousOpen {
            let gap = Calendar.current.dateComponents([.day], from: previousOpen, to: .now).day ?? 0
            phase = gap >= 7 ? .returning : .active
        } else if openCount == 0 {
            phase = .new
        } else {
            phase = .active
        }
        lastOpenedAt = .now
        openCount += 1
        defaults.set(lastOpenedAt, forKey: Key.lastOpenedAt)
        defaults.set(openCount, forKey: Key.openCount)
        defaults.set(versionLabel, forKey: Key.lastVersionSeen)
        if openCount <= 1 {
            phase = .new
        }
    }

    /// 切换 Tab 时记一次访问，用于 7 日打开率观察（如广场是否应并入活动）。
    func recordTabVisit(_ tab: AppTab) {
        var records = loadTabVisits()
        records.append(TabVisitRecord(tab: tab.analyticsKey, date: .now))
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        records = records.filter { $0.date >= cutoff }
        saveTabVisits(records)
    }

    func tabVisitCount(_ tab: AppTab, withinDays days: Int = 7) -> Int {
        guard days > 0 else { return 0 }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return loadTabVisits().filter { $0.tab == tab.analyticsKey && $0.date >= cutoff }.count
    }

    /// 安装满 7 天且广场 Tab 零打开时，可在设置或运营侧参考。
    var shouldReviewCommunityTabPlacement: Bool {
        daysSinceInstall >= 7 && tabVisitCount(.community, withinDays: 7) == 0
    }

    /// 满足观察条件时，将广场并入活动 Tab（独立 Tab 隐藏）。
    var shouldMergeCommunityIntoActivitiesTab: Bool {
        shouldReviewCommunityTabPlacement
    }

    private func loadTabVisits() -> [TabVisitRecord] {
        guard let data = UserDefaults.standard.data(forKey: Key.tabVisits),
              let records = try? JSONDecoder().decode([TabVisitRecord].self, from: data)
        else { return [] }
        return records
    }

    private func saveTabVisits(_ records: [TabVisitRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: Key.tabVisits)
    }

    func dismissTip(_ id: String) {
        dismissedTipIDs.insert(id)
        UserDefaults.standard.set(Array(dismissedTipIDs), forKey: Key.dismissedTips)
    }

    func eligibleTips(
        isGuest: Bool,
        profileComplete: Bool,
        hasOrders: Bool
    ) -> [ProductLifecycleTip] {
        var tips: [ProductLifecycleTip] = []

        if phase == .returning, !dismissedTipIDs.contains("returning") {
            tips.append(
                ProductLifecycleTip(
                    id: "returning",
                    title: "欢迎回来",
                    detail: "附近有新活动和搭子在线，先从「活动」逛起。",
                    systemImage: "arrow.uturn.backward"
                )
            )
        }

        if isGuest, !dismissedTipIDs.contains("guest") {
            tips.append(
                ProductLifecycleTip(
                    id: "guest",
                    title: "创建账号解锁交易",
                    detail: "游客可浏览；支付、会员与完整资料需创建账号。",
                    systemImage: "person.crop.circle.badge.plus"
                )
            )
        }

        if !profileComplete, !dismissedTipIDs.contains("profile") {
            tips.append(
                ProductLifecycleTip(
                    id: "profile",
                    title: "完善资料提高匹配",
                    detail: "补齐头像、兴趣与简介，搭子与活动推荐更准。",
                    systemImage: "person.text.rectangle"
                )
            )
        }

        if !hasOrders, openCount >= 3, !dismissedTipIDs.contains("first-order") {
            tips.append(
                ProductLifecycleTip(
                    id: "first-order",
                    title: "完成一次轻履约",
                    detail: "参加一场活动或预约陪玩，订单会出现在「我的订单」。",
                    systemImage: "checkmark.seal"
                )
            )
        }

        if daysSinceInstall >= 1, !dismissedTipIDs.contains("privacy") {
            tips.append(
                ProductLifecycleTip(
                    id: "privacy",
                    title: "检查隐私与通知",
                    detail: "在设置里管理距离展示、邀约与本地提醒。",
                    systemImage: "hand.raised"
                )
            )
        }

        return tips
    }

    func activeTips(
        isGuest: Bool,
        profileComplete: Bool,
        hasOrders: Bool
    ) -> [ProductLifecycleTip] {
        Array(eligibleTips(isGuest: isGuest, profileComplete: profileComplete, hasOrders: hasOrders).prefix(1))
    }

    func resetAll() {
        let defaults = UserDefaults.standard
        installAt = .now
        lastOpenedAt = nil
        openCount = 0
        dismissedTipIDs = []
        phase = .new
        defaults.set(installAt, forKey: Key.installAt)
        defaults.removeObject(forKey: Key.lastOpenedAt)
        defaults.set(0, forKey: Key.openCount)
        defaults.removeObject(forKey: Key.dismissedTips)
        defaults.removeObject(forKey: Key.lastVersionSeen)
        defaults.removeObject(forKey: Key.tabVisits)
    }
}

//
//  ActivityBrowseShelf.swift
//  坐标系
//
//  活动发现页长列表分区：转化轨优先，浏览轨收紧。
//  各轨由 ActivityRecommender 排序并跨轨去重。
//

import Foundation
import CoordinateModels

/// 分区卡片信息密度 / 视觉形态（活动域）
enum ActivityBrowseShelfLayout: String, Hashable {
    /// 已参加 / 在跟：标题 + 时间（+ 地点），弱转化横滑
    case following
    /// 可参加热场：角标 + 元信息 + 参加，横滑小卡
    case hot
    /// 竖向全宽卡：可扫可读，打断连续横滑
    case list
    /// 竖海报榜单
    case ranked
    /// 全宽活动焦点大卡（单场）
    case editorial
}

struct ActivityBrowseShelf: Identifiable, Hashable {
    let id: String
    let title: String
    let layout: ActivityBrowseShelfLayout
    let activities: [Activity]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

// MARK: - Home catalog

/// 活动 Tab 主列表：转化轨前置，默认最多约 6 条有内容的轨。
@MainActor
enum ActivityBrowseHomeCatalog {
    static let minimumCount = 2
    static let railCap = 10
    /// 首页默认轨数上限，避免长尾稀释参加意图。
    static let maxShelves = 6

    static func shelves(
        activities: [Activity],
        joined: [Activity],
        catalogIndex: [UUID: Int],
        excluding excludedIDs: Set<UUID> = []
    ) -> [ActivityBrowseShelf] {
        let open = activities.filter { !$0.isPast && $0.hasAvailableSpots }
        var used = excludedIDs
        var shelves: [ActivityBrowseShelf] = []

        // 1. 接着逛：仅真实已报名场次，不做开放池兜底
        let followingItems = followingJoined(
            from: joined,
            excluding: used
        )
        if append(
            &shelves,
            id: "following",
            title: ActivityBrowseCopy.Shelf.followingTitle,
            layout: .following,
            items: followingItems
        ) {
            used.formUnion(followingItems.map(\.id))
        }

        // 2–4. 高转化：稀缺 → 今晚 → 免费
        let fillingItems = takeRanked(
            from: open,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: railCap
        ) { $0.isAlmostFull && !$0.isFull }
        if append(
            &shelves,
            id: "filling",
            title: ActivityBrowseCopy.Shelf.fillingTitle,
            layout: .hot,
            items: fillingItems
        ) {
            used.formUnion(fillingItems.map(\.id))
        }

        let tonightItems = takeRanked(
            from: open,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: railCap,
            where: isTonight
        )
        if append(
            &shelves,
            id: "tonight",
            title: ActivityBrowseCopy.Shelf.tonightTitle,
            layout: .following,
            items: tonightItems
        ) {
            used.formUnion(tonightItems.map(\.id))
        }

        let freeItems = takeRanked(
            from: open,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: railCap,
            where: \.isFree
        )
        if append(
            &shelves,
            id: "free",
            title: ActivityBrowseCopy.Shelf.freeTitle,
            layout: .hot,
            items: freeItems
        ) {
            used.formUnion(freeItems.map(\.id))
        }

        // 5. 热场（精选转化交给顶部 Hero，避免与 editorial 轨重复）
        let hotCandidates = ranked(
            from: open,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: railCap + 4
        )
        let hotItems = Array(ActivityRecommender.diversify(hotCandidates).prefix(railCap))
        if append(
            &shelves,
            id: "hot",
            title: ActivityBrowseCopy.Shelf.hotTitle,
            layout: .hot,
            items: hotItems
        ) {
            used.formUnion(hotItems.map(\.id))
        }

        // 出门就能到：仅有距离信号时出现，且不突破轨数上限
        if shelves.count < maxShelves {
            let nearbyItems = takeRanked(
                from: open,
                catalogIndex: catalogIndex,
                excluding: used,
                limit: railCap,
                where: \.isNearby
            )
            if append(
                &shelves,
                id: "nearby",
                title: ActivityBrowseCopy.Shelf.nearbyTitle,
                layout: .hot,
                items: nearbyItems
            ) {
                used.formUnion(nearbyItems.map(\.id))
            }
        }

        return Array(shelves.prefix(maxShelves))
    }

    // MARK: - Helpers

    @discardableResult
    private static func append(
        _ shelves: inout [ActivityBrowseShelf],
        id: String,
        title: String,
        layout: ActivityBrowseShelfLayout,
        items: [Activity]
    ) -> Bool {
        guard items.count >= minimumCount else { return false }
        shelves.append(
            ActivityBrowseShelf(
                id: id,
                title: title,
                layout: layout,
                activities: items
            )
        )
        return true
    }

    private static func ranked(
        from activities: [Activity],
        catalogIndex: [UUID: Int],
        excluding used: Set<UUID>,
        limit: Int
    ) -> [Activity] {
        ActivityRecommender.ranked(
            from: activities,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: limit
        )
    }

    private static func takeRanked(
        from activities: [Activity],
        catalogIndex: [UUID: Int],
        excluding used: Set<UUID>,
        limit: Int,
        where keyPath: KeyPath<Activity, Bool>
    ) -> [Activity] {
        ranked(
            from: activities.filter { $0[keyPath: keyPath] },
            catalogIndex: catalogIndex,
            excluding: used,
            limit: limit
        )
    }

    private static func takeRanked(
        from activities: [Activity],
        catalogIndex: [UUID: Int],
        excluding used: Set<UUID>,
        limit: Int,
        where predicate: (Activity) -> Bool
    ) -> [Activity] {
        ranked(
            from: activities.filter(predicate),
            catalogIndex: catalogIndex,
            excluding: used,
            limit: limit
        )
    }

    /// 仅用户真实已报名且未结束的场次；不足 `minimumCount` 则不展示该轨。
    private static func followingJoined(
        from joined: [Activity],
        excluding used: Set<UUID>
    ) -> [Activity] {
        let active = joined.filter { !$0.isPast && !used.contains($0.id) }
        guard active.count >= minimumCount else { return [] }
        return Array(active.prefix(8))
    }

    private static func isTonight(_ activity: Activity) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(activity.date)
            && calendar.component(.hour, from: activity.date) >= 17
    }
}

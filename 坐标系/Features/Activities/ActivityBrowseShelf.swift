//
//  ActivityBrowseShelf.swift
//  坐标系
//
//  活动发现页长列表分区：App Store / Apple TV 式货架混排。
//  信息密度由 layout 决定；各轨由 ActivityRecommender 排序并跨轨去重。
//

import Foundation

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

/// 活动 Tab 主列表编排：精选、接着逛、Top 10、热场、列表等。
@MainActor
enum ActivityBrowseHomeCatalog {
    static let minimumCount = 2
    static let editorialCap = 5
    static let railCap = 10
    static let listCap = 6

    static func shelves(
        activities: [Activity],
        joined: [Activity],
        catalogIndex: [UUID: Int],
        excluding spotlightIDs: Set<UUID> = []
    ) -> [ActivityBrowseShelf] {
        let open = activities.filter { !$0.isPast && $0.hasAvailableSpots }
        var used = spotlightIDs
        var shelves: [ActivityBrowseShelf] = []

        let featuredItems = ranked(from: open, catalogIndex: catalogIndex, excluding: used, limit: editorialCap)
        if append(
            &shelves,
            id: "featured",
            title: ActivityBrowseCopy.Shelf.featuredTitle,
            layout: .editorial,
            items: featuredItems
        ) {
            used.formUnion(featuredItems.map(\.id))
        }

        let followingItems = following(
            from: joined,
            open: open,
            catalogIndex: catalogIndex,
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

        let topCharts = ranked(from: open, catalogIndex: catalogIndex, excluding: used, limit: railCap)
        if append(
            &shelves,
            id: "topcharts",
            title: ActivityBrowseCopy.Shelf.topChartsTitle,
            layout: .ranked,
            items: topCharts
        ) {
            used.formUnion(topCharts.map(\.id))
        }

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

        let newlyListed = open.sorted {
            (catalogIndex[$0.id] ?? Int.max) < (catalogIndex[$1.id] ?? Int.max)
        }
        let newItems = ranked(
            from: newlyListed,
            catalogIndex: catalogIndex,
            excluding: used,
            limit: editorialCap
        )
        if append(
            &shelves,
            id: "new",
            title: ActivityBrowseCopy.Shelf.newTitle,
            layout: .editorial,
            items: newItems
        ) {
            used.formUnion(newItems.map(\.id))
        }

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

        let editorItems = ranked(from: open, catalogIndex: catalogIndex, excluding: used, limit: editorialCap)
        if append(
            &shelves,
            id: "editors",
            title: ActivityBrowseCopy.Shelf.editorsTitle,
            layout: .editorial,
            items: editorItems
        ) {
            used.formUnion(editorItems.map(\.id))
        }

        let listItems = ranked(from: open, catalogIndex: catalogIndex, excluding: used, limit: listCap)
        append(
            &shelves,
            id: "list",
            title: ActivityBrowseCopy.Shelf.listTitle,
            layout: .list,
            items: listItems
        )

        return shelves
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

    private static func following(
        from joined: [Activity],
        open: [Activity],
        catalogIndex: [UUID: Int],
        excluding used: Set<UUID>
    ) -> [Activity] {
        let active = joined.filter { !$0.isPast && !used.contains($0.id) }
        if active.count >= minimumCount {
            return Array(active.prefix(8))
        }
        return ranked(from: open, catalogIndex: catalogIndex, excluding: used, limit: 8)
    }

    private static func isTonight(_ activity: Activity) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(activity.date)
            && calendar.component(.hour, from: activity.date) >= 17
    }
}

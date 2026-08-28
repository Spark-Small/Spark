//
//  BuddyBrowseShelf.swift
//  坐标系
//
//  搭子发现目录：精选 + 有信号辅轨 + 全量人墙；跨轨去重。
//

import Foundation

enum BuddyBrowseShelfLayout: String, Hashable {
    case editorial
    case hot
    case leaderboard
}

struct BuddyBrowseShelf: Identifiable, Hashable {
    let id: String
    let title: String
    let layout: BuddyBrowseShelfLayout
    let items: [DiscoverBuddyItem]
    /// 是否提供「查看全部」（辅轨）
    var showsSeeAll: Bool = false

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

struct BuddyBrowseHomeSnapshot {
    /// 首轨无分区标题
    let spotlight: [DiscoverBuddyItem]
    /// 有信号辅轨（≤2），已与精选去重
    let rails: [BuddyBrowseShelf]
    /// 主浏览：精选与辅轨之外的剩余全部
    let wall: [DiscoverBuddyItem]
    let wallTitle: String
    /// 预约排行榜（可与墙重叠展示排名，不占墙名额）
    let leaderboard: BuddyBrowseShelf?
}

enum BuddyBrowseHomeCatalog {
    static let minimumCount = 2
    static let paidSpotlightLimit = 5
    static let railItemCap = 8

    // MARK: Free

    static func freeSnapshot(
        people: [DiscoverBuddyItem],
        joinedCircleNames: Set<String>,
        wallTitle: String
    ) -> BuddyBrowseHomeSnapshot {
        guard !people.isEmpty else {
            return BuddyBrowseHomeSnapshot(
                spotlight: [],
                rails: [],
                wall: [],
                wallTitle: wallTitle,
                leaderboard: nil
            )
        }

        var used = Set<UUID>()
        let spotlightLimit = BuddyDiscoveryPicks.limit
        let showSpotlight = people.count > spotlightLimit
        let spotlight = showSpotlight ? Array(people.prefix(spotlightLimit)) : []
        used.formUnion(spotlight.map(\.id))

        var rails: [BuddyBrowseShelf] = []

        // 「附近」用分区展示，不占页内排序按钮
        let nearbyItems = take(
            from: people,
            excluding: used,
            limit: railItemCap
        ) { $0.profile.isNearby }
        if appendRail(
            &rails,
            id: "nearby",
            title: BuddyBrowseCopy.Shelf.nearbyTitle,
            layout: .hot,
            items: nearbyItems
        ) {
            used.formUnion(nearbyItems.map(\.id))
        }

        let affinityItems = take(
            from: people,
            excluding: used,
            limit: railItemCap
        ) { !BuddyMatchScorer.sharedHobbies(with: $0.profile).isEmpty }
        if appendRail(
            &rails,
            id: "affinity",
            title: BuddyBrowseCopy.Shelf.affinityTitle,
            layout: .hot,
            items: affinityItems
        ) {
            used.formUnion(affinityItems.map(\.id))
        }

        let tonightItems = take(
            from: people,
            excluding: used,
            limit: railItemCap,
            where: hasTonightSlot
        )
        if appendRail(
            &rails,
            id: "tonight",
            title: BuddyBrowseCopy.Shelf.tonightTitle,
            layout: .editorial,
            items: tonightItems
        ) {
            used.formUnion(tonightItems.map(\.id))
        }

        if rails.count < 2, !joinedCircleNames.isEmpty {
            let followingItems = take(from: people, excluding: used, limit: railItemCap) { item in
                guard case .free(let buddy) = item else { return false }
                return joinedCircleNames.contains(buddy.circleName)
            }
            if appendRail(
                &rails,
                id: "following",
                title: BuddyBrowseCopy.Shelf.followingTitle,
                layout: .hot,
                items: followingItems
            ) {
                used.formUnion(followingItems.map(\.id))
            }
        }

        let wall = people.filter { !used.contains($0.id) }

        return BuddyBrowseHomeSnapshot(
            spotlight: spotlight,
            rails: rails,
            wall: wall,
            wallTitle: wallTitle,
            leaderboard: nil
        )
    }

    // MARK: Paid

    static func paidSnapshot(
        people: [DiscoverBuddyItem],
        boardPeriod: BuddyPaidBoardPeriod,
        wallTitle: String
    ) -> BuddyBrowseHomeSnapshot {
        let companions = people.compactMap { item -> (DiscoverBuddyItem, PaidCompanion)? in
            guard case .paid(let companion) = item else { return nil }
            return (item, companion)
        }
        guard !companions.isEmpty else {
            return BuddyBrowseHomeSnapshot(
                spotlight: [],
                rails: [],
                wall: [],
                wallTitle: wallTitle,
                leaderboard: nil
            )
        }

        var used = Set<UUID>()
        let availableFirst = companions.sorted { lhs, rhs in
            if lhs.1.isAvailable != rhs.1.isAvailable { return lhs.1.isAvailable && !rhs.1.isAvailable }
            return false
        }
        let spotlight = Array(availableFirst.prefix(paidSpotlightLimit).map(\.0))
        used.formUnion(spotlight.map(\.id))

        let boardItems = BuddyPaidMarketCatalog.ranked(people, period: boardPeriod)
        let leaderboard: BuddyBrowseShelf? = boardItems.count >= minimumCount
            ? BuddyBrowseShelf(
                id: "leaderboard",
                title: BuddyBrowseCopy.Shelf.leaderboardTitle,
                layout: .leaderboard,
                items: boardItems
            )
            : nil

        let wall = people.filter { !used.contains($0.id) }

        return BuddyBrowseHomeSnapshot(
            spotlight: spotlight,
            rails: [],
            wall: wall,
            wallTitle: wallTitle,
            leaderboard: leaderboard
        )
    }

    // MARK: - Helpers

    @discardableResult
    private static func appendRail(
        _ rails: inout [BuddyBrowseShelf],
        id: String,
        title: String,
        layout: BuddyBrowseShelfLayout,
        items: [DiscoverBuddyItem]
    ) -> Bool {
        guard rails.count < 2, items.count >= minimumCount else { return false }
        rails.append(
            BuddyBrowseShelf(
                id: id,
                title: title,
                layout: layout,
                items: items,
                showsSeeAll: true
            )
        )
        return true
    }

    private static func take(
        from people: [DiscoverBuddyItem],
        excluding used: Set<UUID>,
        limit: Int,
        where predicate: (DiscoverBuddyItem) -> Bool
    ) -> [DiscoverBuddyItem] {
        Array(
            people
                .filter { !used.contains($0.id) && predicate($0) }
                .prefix(limit)
        )
    }

    /// 今日晚间可约：用档期解析，而非纯文案包含。
    static func hasTonightSlot(_ item: DiscoverBuddyItem) -> Bool {
        let labels: [String] = {
            switch item {
            case .free(let buddy):
                return buddy.scheduleSlots + [buddy.profile.availability]
            case .paid(let companion):
                return companion.scheduleSlots + [companion.profile.availability]
            }
        }()
        let calendar = Calendar.current
        let now = Date()
        return BuddyScheduleSlot.resolveAll(labels, reference: now, calendar: calendar)
            .contains { resolved in
                guard resolved.bookable else { return false }
                guard calendar.isDateInToday(resolved.start) else { return false }
                return calendar.component(.hour, from: resolved.start) >= 17
                    || labels.contains { $0.contains("今晚") || $0.contains("今夜") }
            }
    }
}

enum BuddyBrowseCopy {
    enum Shelf {
        static let nearbyTitle = "附近的人"
        static let affinityTitle = "同频的人"
        static let followingTitle = "接着逛"
        static let tonightTitle = "今晚有空"
        static let leaderboardTitle = "推荐陪玩"
        static let listTitle = "推荐"
        static let activeWallTitle = "刚活跃"
        static let paidWallTitle = "更多陪玩"
    }

    static let circlesTitle = "兴趣圈子"
    static let searchResultsTitle = "搜索结果"
    static let availableOnlyChip = "仅可约"
    static let leaderboardRankTitle = "排行榜"
    /// 发现卡 / 成员半屏：打开档期选择（详情底栏见 `BuddyDetailCopy.quickBook`）
    static let bookAction = "选档期"
    static let bookUnavailable = BuddyDetailCopy.bookUnavailable
}

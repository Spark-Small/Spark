//
//  ActivityBrowseShelf.swift
//  坐标系
//
//  活动发现页长列表分区：按活动状态 / 兴趣 / 品类编排，支持一直下滑。
//  信息密度由 layout 决定（跟进瘦、热场密、榜单少字）。
//
//  转化 / DAU 相关的编排策略集中在这里：
//  1) 「接着逛」「本周主打」两个转化最强的锚点货架固定在最前——
//     前者留老用户，后者是全宽大图 + 一键参加，趁注意力最高时先亮出来。
//  2) 其余货架按「货架强度」（内部 Top3 活动的推荐分均值）动态排序，
//     强度已经内含兴趣 / 行为学习 / 紧迫度，所以「因你兴趣」「品类」货架
//     天然会按真实匹配度排队，不用再手写优先级。
//  3) 叠加时段上下文：晚上顶「今晚有局」，临近周末顶「周末值得去」，
//     让同一批货架在不同时间点开也会重新洗一次牌。
//  4) 货架 layout 按角色分化（hot / list / ranked / editorial），
//     reorder 后再做相邻 layout 去重，避免连续多行同款横滑小卡。
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
    let subtitle: String?
    let layout: ActivityBrowseShelfLayout
    let activities: [Activity]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

/// 从当前可见目录生成推荐分区（有货才出轨）
@MainActor
enum ActivityBrowseShelfBuilder {
    /// `nonisolated`：可作 default 参数（在 nonisolated 上下文求值）。
    nonisolated static let minimumCount = 2
    nonisolated static let railLimit = 10
    nonisolated static let rankedLimit = 10

    static func build(
        catalog: [Activity],
        featuredIDs: Set<UUID>,
        joinedIDs: Set<UUID>,
        interests: [String],
        catalogIndex: [UUID: Int]
    ) -> [ActivityBrowseShelf] {
        var shelves: [ActivityBrowseShelf] = []
        var claimed = featuredIDs
        let upcoming = catalog.filter { !$0.isPast }
        let open = upcoming.filter(\.hasAvailableSpots)
        let cal = Calendar.current

        func ranked(
            from pool: [Activity],
            excluding: Set<UUID> = claimed,
            limit: Int = railLimit,
            includeFull: Bool = false,
            diversify shouldDiversify: Bool = false
        ) -> [Activity] {
            let items = ActivityRecommender.ranked(
                from: pool.filter { !excluding.contains($0.id) },
                catalogIndex: catalogIndex,
                limit: limit,
                includeFull: includeFull
            )
            return shouldDiversify ? ActivityRecommender.diversify(items) : items
        }

        func append(
            id: String,
            title: String,
            subtitle: String?,
            layout: ActivityBrowseShelfLayout,
            items: [Activity],
            claim: Bool = true
        ) {
            guard items.count >= minimumCount else { return }
            shelves.append(
                ActivityBrowseShelf(
                    id: id,
                    title: title,
                    subtitle: subtitle,
                    layout: layout,
                    activities: items
                )
            )
            if claim {
                claimed.formUnion(items.map(\.id))
            }
        }

        // 1. 接着逛：已参加未结束
        let following = ranked(
            from: upcoming.filter { joinedIDs.contains($0.id) },
            excluding: [],
            limit: 8,
            includeFull: true
        )
        append(
            id: "following",
            title: ActivityBrowseCopy.Shelf.followingTitle,
            subtitle: ActivityBrowseCopy.Shelf.followingSubtitle,
            layout: .following,
            items: following
        )

        // 2. 快被约满
        let filling = ranked(from: open.filter { $0.isAlmostFull && !$0.isFull })
        append(
            id: "filling",
            title: ActivityBrowseCopy.Shelf.fillingTitle,
            subtitle: ActivityBrowseCopy.Shelf.fillingSubtitle(count: filling.count),
            layout: .hot,
            items: filling
        )

        // 3. 出门就能到
        let nearby = ranked(from: open.filter(\.isNearby))
        append(
            id: "nearby",
            title: ActivityBrowseCopy.Shelf.nearbyTitle,
            subtitle: ActivityBrowseCopy.Shelf.nearbySubtitle(count: nearby.count),
            layout: .hot,
            items: nearby
        )

        // 4. 先玩起来（免费）
        let free = ranked(from: open.filter(\.isFree))
        append(
            id: "free",
            title: ActivityBrowseCopy.Shelf.freeTitle,
            subtitle: ActivityBrowseCopy.Shelf.freeSubtitle(count: free.count),
            layout: .hot,
            items: free
        )

        // 5. 这两天就出发
        let soonEnd = cal.date(
            byAdding: .hour,
            value: RecommendationConfig.startingSoonHours,
            to: .now
        ) ?? .now
        let soon = ranked(from: open.filter { $0.date <= soonEnd }, limit: 8)
        append(
            id: "soon",
            title: ActivityBrowseCopy.Shelf.soonTitle,
            subtitle: ActivityBrowseCopy.Shelf.soonSubtitle,
            layout: .hot,
            items: soon
        )

        // 6. 今晚有局（今日 17:00 后）
        let tonight = ranked(from: open.filter { activity in
            cal.isDateInToday(activity.date) && cal.component(.hour, from: activity.date) >= 17
        })
        append(
            id: "tonight",
            title: ActivityBrowseCopy.Shelf.tonightTitle,
            subtitle: ActivityBrowseCopy.Shelf.tonightSubtitle,
            layout: .hot,
            items: tonight
        )

        // 7. 周末值得去
        let weekend = ranked(from: open.filter { activity in
            let weekday = cal.component(.weekday, from: activity.date)
            return weekday == 1 || weekday == 7
        })
        append(
            id: "weekend",
            title: ActivityBrowseCopy.Shelf.weekendTitle,
            subtitle: ActivityBrowseCopy.Shelf.weekendSubtitle,
            layout: .hot,
            items: weekend
        )

        // 8. 猜你想去（竖向精选，打散品类）
        let forYou = ranked(from: open, limit: 8, diversify: true)
        append(
            id: "forYou",
            title: ActivityBrowseCopy.Shelf.forYouTitle,
            subtitle: ActivityBrowseCopy.Shelf.forYouSubtitle,
            layout: .list,
            items: forYou
        )

        // 9. 因你兴趣：竖列表，避免再堆横滑小卡
        for interest in interests {
            let pool = open.filter { matchesInterest($0, interest: interest) }
            let items = ranked(from: pool, limit: 8)
            append(
                id: "interest.\(interest)",
                title: ActivityBrowseCopy.Shelf.interestTitle(interest),
                subtitle: ActivityBrowseCopy.Shelf.interestSubtitle,
                layout: .list,
                items: items
            )
        }

        // 10. 一级品类：竖海报墙，换视觉节奏
        for category in ActivityCategory.allCases where !category.isBrowseAggregate {
            let pool = open.filter { $0.category == category }
            let items = ranked(from: pool, limit: 8)
            append(
                id: "category.\(category.rawValue)",
                title: category.title,
                subtitle: ActivityBrowseCopy.Shelf.categorySubtitle(category),
                layout: .ranked,
                items: items
            )
        }

        // 11. 本周推荐榜（竖海报；不重复占 claimed，用全量打分）
        let rankedList = ActivityRecommender.ranked(
            from: upcoming,
            catalogIndex: catalogIndex,
            limit: rankedLimit,
            includeFull: true
        )
        append(
            id: "ranked",
            title: ActivityBrowseCopy.Shelf.rankedTitle,
            subtitle: ActivityBrowseCopy.Shelf.rankedSubtitle,
            layout: .ranked,
            items: rankedList,
            claim: false
        )

        // 12. 本周主打（横滑焦点大卡，露邻卡，打散品类保持新鲜感）
        let editorial = ranked(from: open, limit: 8, diversify: true)
        append(
            id: "editorial",
            title: ActivityBrowseCopy.Shelf.editorialTitle,
            subtitle: ActivityBrowseCopy.Shelf.editorialSubtitle,
            layout: .editorial,
            items: editorial
        )

        // 13. 还有这些局（竖向兜底）
        let more = ranked(from: upcoming, limit: 12, includeFull: true, diversify: true)
        append(
            id: "more",
            title: ActivityBrowseCopy.Shelf.moreTitle,
            subtitle: ActivityBrowseCopy.Shelf.moreSubtitle,
            layout: .list,
            items: more
        )

        return applyVisualRhythm(reorderForEngagement(shelves))
    }

    // MARK: - 位置编排（转化优先级）

    /// 「接着逛」「本周主打」固定置顶；「本周推荐榜」「还有这些局」固定压底；
    /// 中间货架按强度 + 时段上下文重新排队。
    private static func reorderForEngagement(_ shelves: [ActivityBrowseShelf]) -> [ActivityBrowseShelf] {
        guard shelves.count > 1 else { return shelves }

        let cal = Calendar.current
        let now = Date()
        let hour = cal.component(.hour, from: now)
        let weekday = cal.component(.weekday, from: now)
        let isEvening = hour >= 17
        // 周五（6）起就该把「周末值得去」顶上去，别等到周六才想起来
        let isWeekendMood = weekday == 6 || weekday == 7 || weekday == 1

        let headIDs = ["following", "editorial"]
        let tailIDs = ["ranked", "more"]
        let pinned = Set(headIDs + tailIDs)

        let byID = Dictionary(uniqueKeysWithValues: shelves.map { ($0.id, $0) })
        let head = headIDs.compactMap { byID[$0] }
        let tail = tailIDs.compactMap { byID[$0] }
        let middle = shelves.filter { !pinned.contains($0.id) }

        func strength(_ shelf: ActivityBrowseShelf) -> Double {
            let topScores = shelf.activities.prefix(3).map { Double(ActivityRecommender.score(for: $0)) }
            guard !topScores.isEmpty else { return 0 }
            var value = topScores.reduce(0, +) / Double(topScores.count)

            switch shelf.id {
            case "tonight" where isEvening: value += 40
            case "weekend" where isWeekendMood: value += 30
            case "filling": value += 14
            case "soon": value += 10
            default: break
            }
            return value
        }

        let sortedMiddle = middle.enumerated()
            .sorted { lhs, rhs in
                let lhsStrength = strength(lhs.element)
                let rhsStrength = strength(rhs.element)
                if lhsStrength != rhsStrength { return lhsStrength > rhsStrength }
                return lhs.offset < rhs.offset
            }
            .map(\.element)

        return head + sortedMiddle + tail
    }

    /// 相邻货架尽量不同 layout，打断连续横滑小卡。
    /// 只换中间轨顺序，不改内容；head / tail 固定不动。
    private static func applyVisualRhythm(_ shelves: [ActivityBrowseShelf]) -> [ActivityBrowseShelf] {
        guard shelves.count > 2 else { return shelves }

        let headIDs = Set(["following", "editorial"])
        let tailIDs = Set(["ranked", "more"])

        var head: [ActivityBrowseShelf] = []
        var middle: [ActivityBrowseShelf] = []
        var tail: [ActivityBrowseShelf] = []
        for shelf in shelves {
            if headIDs.contains(shelf.id) {
                head.append(shelf)
            } else if tailIDs.contains(shelf.id) {
                tail.append(shelf)
            } else {
                middle.append(shelf)
            }
        }

        guard middle.count > 1 else { return shelves }

        var rhythm = middle
        for index in 0..<(rhythm.count - 1) {
            guard rhythm[index].layout == rhythm[index + 1].layout else { continue }
            if let swapAt = rhythm[(index + 2)...].firstIndex(where: { $0.layout != rhythm[index].layout }) {
                rhythm.swapAt(index + 1, swapAt)
            }
        }

        // head / tail 保持原相对顺序（following→editorial、ranked→more）
        let orderedHead = ["following", "editorial"].compactMap { id in head.first { $0.id == id } }
        let orderedTail = ["ranked", "more"].compactMap { id in tail.first { $0.id == id } }
        return orderedHead + rhythm + orderedTail
    }

    private static func matchesInterest(_ activity: Activity, interest: String) -> Bool {
        let key = interest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return false }
        if activity.tags.contains(where: { $0.localizedCaseInsensitiveContains(key) }) {
            return true
        }
        if activity.title.localizedCaseInsensitiveContains(key) {
            return true
        }
        return false
    }
}

//
//  ActivityRecommender.swift
//  坐标系
//
//  唯一推荐打分器。
//  推荐分 = 兴趣匹配（显式 + 隐式行为学习） + 距离 + 时间匹配
//         + 紧迫度（转化催化） + 朋友参与 + 活动质量 + 新鲜度
//  发现页各轨排序、精选、「为你精选」、详情相关推荐均以此为准。
//
//  「隐式」「紧迫度」两项是转化 / DAU 优化的核心：
//  - 隐式兴趣随真实点击 / 收藏 / 参加自适应（ActivityEngagementStore），
//    比只认引导页勾选的静态兴趣更准。
//  - 紧迫度把「快满 + 快开场」这种强 FOMO 组合单独加权，专门催转化，
//    而不是和「时间匹配」这种泛相关性混在一起被摊薄。
//

import Foundation

fileprivate struct ActivityRecommendationBreakdown: Hashable {
    let interest: Int
    let implicit: Int
    let distance: Int
    let time: Int
    let urgency: Int
    let friends: Int
    let quality: Int
    let freshness: Int

    var total: Int { interest + implicit + distance + time + urgency + friends + quality + freshness }
}

enum ActivityRecommendationWeights {
    static let interestPerTag = 12
    static let interestCategoryBonus = 8
    static let interestCap = 36

    /// 隐式行为学习（浏览 / 收藏 / 参加），与显式兴趣分开封顶，避免行为数据尚少时被稀释
    static let implicitCap = 22

    static let distanceMax = 25

    static let timeMax = 25

    /// 紧迫度：快满 + 快开场的组合催化转化，独立于「时间匹配」计分
    static let urgencyAlmostFull = 12
    static let urgencyStartingSoon = 9
    static let urgencyComboBonus = 7
    static let urgencyCap = 24

    static let friendPerParticipant = 15
    static let friendsCap = 30

    static let qualityCap = 25

    static let freshnessCap = 20
}

@MainActor
enum ActivityRecommender {
    /// 由 AppModel 在启动 / 引导 / 改资料后注入
    static var userInterests: [String] = SampleData.currentUserInterests
    static var friendNames: Set<String> = []
    static var joinedIDs: Set<UUID> = []
    static var currentUserName: String = SampleData.currentUser.name

    fileprivate static func breakdown(
        for activity: Activity,
        catalogIndex: Int? = nil,
        referenceDate: Date = .now
    ) -> ActivityRecommendationBreakdown {
        ActivityRecommendationBreakdown(
            interest: interestScore(for: activity),
            implicit: implicitScore(for: activity),
            distance: distanceScore(for: activity),
            time: timeScore(for: activity, referenceDate: referenceDate),
            urgency: urgencyScore(for: activity, referenceDate: referenceDate),
            friends: friendsScore(for: activity),
            quality: qualityScore(for: activity),
            freshness: freshnessScore(for: activity, catalogIndex: catalogIndex)
        )
    }

    static func score(
        for activity: Activity,
        catalogIndex: Int? = nil,
        referenceDate: Date = .now
    ) -> Int {
        breakdown(for: activity, catalogIndex: catalogIndex, referenceDate: referenceDate).total
    }

    /// 相近分数（同一「档位」）内按天打散，让每天打开的顺序有细微不同——
    /// 避免同一批人天天看到一模一样的头几张卡而失去打开欲（利好复访）
    private static let sameTierBand = 4

    static func ranked(
        from activities: [Activity],
        catalogIndex: [UUID: Int] = [:],
        excluding: Set<UUID> = [],
        referenceDate: Date = .now,
        limit: Int? = nil,
        includeFull: Bool = false
    ) -> [Activity] {
        let sorted = activities
            .filter { activity in
                guard !excluding.contains(activity.id), !activity.isPast else { return false }
                return includeFull || activity.hasAvailableSpots
            }
            .sorted { lhs, rhs in
                let left = breakdown(
                    for: lhs,
                    catalogIndex: catalogIndex[lhs.id],
                    referenceDate: referenceDate
                )
                let right = breakdown(
                    for: rhs,
                    catalogIndex: catalogIndex[rhs.id],
                    referenceDate: referenceDate
                )
                if left.total != right.total {
                    if abs(left.total - right.total) <= sameTierBand {
                        let lhsSeed = dailySeed(for: lhs.id, referenceDate: referenceDate)
                        let rhsSeed = dailySeed(for: rhs.id, referenceDate: referenceDate)
                        if lhsSeed != rhsSeed { return lhsSeed > rhsSeed }
                    }
                    return left.total > right.total
                }
                if lhs.distanceKM != rhs.distanceKM { return lhs.distanceKM < rhs.distanceKM }
                return lhs.date < rhs.date
            }
        if let limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }

    /// 打散连续同品类，避免整轨清一色导致刷两下就腻（拉长单次浏览时长）
    static func diversify(_ activities: [Activity], maxConsecutiveSameCategory: Int = 2) -> [Activity] {
        guard activities.count > maxConsecutiveSameCategory else { return activities }
        var pool = activities
        var result: [Activity] = []
        result.reserveCapacity(pool.count)

        while !pool.isEmpty {
            var pickedIndex = 0
            if result.count >= maxConsecutiveSameCategory,
               let lastCategory = result.last?.category,
               result.suffix(maxConsecutiveSameCategory).allSatisfy({ $0.category == lastCategory }),
               let alt = pool.firstIndex(where: { $0.category != lastCategory }) {
                pickedIndex = alt
            }
            result.append(pool.remove(at: pickedIndex))
        }
        return result
    }

    /// 稳定在同一天内不变，跨天自然轮换——不是真随机，避免同一次滑动里卡片跳位
    private static func dailySeed(for id: UUID, referenceDate: Date) -> Int {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: referenceDate) ?? 0
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(dayOfYear)
        return hasher.finalize()
    }

    // MARK: - Factors

    private static func interestScore(for activity: Activity) -> Int {
        guard !userInterests.isEmpty else { return 0 }

        var value = 0
        var matchedCategories: Set<ActivityCategory> = []

        for interest in userInterests {
            let tagHit = activity.tags.contains { tag in
                tag.localizedCaseInsensitiveContains(interest)
                    || interest.localizedCaseInsensitiveContains(tag)
            }
            let textHit = activity.title.localizedCaseInsensitiveContains(interest)
                || activity.summary.localizedCaseInsensitiveContains(interest)

            if tagHit || textHit {
                value += ActivityRecommendationWeights.interestPerTag
            }

            if let category = ActivityTaxonomy.category(forSubtype: interest),
               activity.category == category,
               matchedCategories.insert(category).inserted {
                value += ActivityRecommendationWeights.interestCategoryBonus
            }
        }

        return min(value, ActivityRecommendationWeights.interestCap)
    }

    /// 行为学习兴趣：最近真的点开 / 收藏 / 参加过的标签、品类，动态加权
    private static func implicitScore(for activity: Activity) -> Int {
        ActivityEngagementStore.shared.implicitScore(
            for: activity,
            cap: ActivityRecommendationWeights.implicitCap
        )
    }

    private static func distanceScore(for activity: Activity) -> Int {
        let maxKM = 12.0
        guard activity.distanceKM <= maxKM else { return 0 }
        let linear = Int(
            (1 - activity.distanceKM / maxKM) * Double(ActivityRecommendationWeights.distanceMax)
        )
        let nearbyBonus = activity.isNearby ? 4 : 0
        return min(linear + nearbyBonus, ActivityRecommendationWeights.distanceMax)
    }

    private static func timeScore(for activity: Activity, referenceDate: Date) -> Int {
        let hours = activity.date.timeIntervalSince(referenceDate) / 3600
        guard hours >= 0 else { return 0 }

        let base: Int
        switch hours {
        case ..<24: base = ActivityRecommendationWeights.timeMax
        case ..<Double(RecommendationConfig.startingSoonHours): base = 20
        case ..<(24 * 7): base = 14
        case ..<(24 * 14): base = 8
        default: base = 4
        }

        var value = base
        if Calendar.current.isDateInToday(activity.date) {
            value += 3
        } else if Calendar.current.isDateInWeekend(activity.date) {
            value += 2
        }
        return min(value, ActivityRecommendationWeights.timeMax)
    }

    /// 紧迫度：快满、快开场分别加分，两者叠加再给组合奖励——专门催「现在就参加」
    private static func urgencyScore(for activity: Activity, referenceDate: Date) -> Int {
        guard activity.hasAvailableSpots else { return 0 }

        var value = 0
        var hits = 0
        if activity.isAlmostFull {
            value += ActivityRecommendationWeights.urgencyAlmostFull
            hits += 1
        }

        let hours = activity.date.timeIntervalSince(referenceDate) / 3600
        if hours >= 0, hours <= Double(RecommendationConfig.startingSoonHours) {
            value += ActivityRecommendationWeights.urgencyStartingSoon
            hits += 1
        }

        if hits >= 2 {
            value += ActivityRecommendationWeights.urgencyComboBonus
        }

        return min(value, ActivityRecommendationWeights.urgencyCap)
    }

    private static func friendsScore(for activity: Activity) -> Int {
        min(
            matchedFriends(for: activity).count * ActivityRecommendationWeights.friendPerParticipant,
            ActivityRecommendationWeights.friendsCap
        )
    }

    /// 命中的好友名单：卡片上「XX 也去」的社交背书，比抽象分数更能催转化
    static func matchedFriends(for activity: Activity) -> [String] {
        guard !friendNames.isEmpty else { return [] }
        return activity.participantNames.filter { name in
            !name.isEmpty && name != currentUserName && friendNames.contains(name)
        }
    }

    private static func qualityScore(for activity: Activity) -> Int {
        var value = 0

        let trust = ActivityHostTrust.make(hostName: activity.hostName, liveHostedCount: 1)
        value += min(trust.completionRate - 80, 10)

        let fill = activity.fillProgress
        if fill >= 0.2, fill <= 0.75 {
            value += 6
        } else if fill > 0 {
            value += 3
        }

        if activity.localCoverName != nil || ActivityBundledCovers.assetName(for: activity.id) != nil {
            value += 4
        }
        if activity.summary.count >= 24 { value += 3 }
        if activity.joined >= 2 { value += 2 }

        return min(value, ActivityRecommendationWeights.qualityCap)
    }

    private static func freshnessScore(for activity: Activity, catalogIndex: Int?) -> Int {
        var value = 0

        if let catalogIndex {
            switch catalogIndex {
            case 0: value += 20
            case 1: value += 15
            case 2: value += 10
            default: value += 5
            }
        } else {
            value += 6
        }

        if joinedIDs.contains(activity.id) {
            value -= 8
        }

        return max(0, min(value, ActivityRecommendationWeights.freshnessCap))
    }
}

enum ActivityRelatedRecommender {
    /// 详情页相关活动横滑轨条数（纵向上不占屏，左右滑查看更多）
    static let displayLimit = 6

    /// 相关推荐 = 用户推荐分 + 与当前活动的相似加分
    @MainActor
    static func related(
        to activity: Activity,
        from catalog: [Activity],
        limit: Int = displayLimit
    ) -> [Activity] {
        catalog
            .filter { candidate in
                candidate.id != activity.id && !candidate.isPast
            }
            .sorted { lhs, rhs in
                relatedScore(lhs, comparedTo: activity) > relatedScore(rhs, comparedTo: activity)
            }
            .prefix(limit)
            .map { $0 }
    }

    @MainActor
    private static func relatedScore(_ candidate: Activity, comparedTo base: Activity) -> Int {
        var value = ActivityRecommender.score(for: candidate)
        if candidate.category == base.category { value += 28 }
        let sharedTags = Set(candidate.tags).intersection(base.tags).count
        value += sharedTags * 10
        if candidate.hostName == base.hostName { value += 12 }
        let distanceGap = abs(candidate.distanceKM - base.distanceKM)
        value += max(0, 8 - Int(distanceGap))
        return value
    }
}

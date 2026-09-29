//
//  ActivitiesModel+Browse.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation
import CoordinateModels

extension ActivitiesModel {
    /// 默认浏览态：精选 Hero + 目录模块（快捷筛选 / 日期 / 搜索时隐藏精选）
    var showsBrowseModules: Bool {
        quickFilters.isEmpty
            && dayFilter == nil
            && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var catalogIndexByID: [UUID: Int] {
        Dictionary(uniqueKeysWithValues: activities.enumerated().map { ($0.element.id, $0.offset) })
    }

    private var browseCriteria: ActivityBrowseCriteria {
        ActivityBrowseCriteria(
            category: selectedCategory,
            quickFilters: quickFilters,
            dayFilter: dayFilter,
            nearbyRadiusKM: RecommendationConfig.nearbyKM,
            searchText: searchText
        )
    }

    /// 当前可见目录（分类 / 快捷筛选）
    var filtered: [Activity] {
        browse.filter.execute(activities: activities, criteria: browseCriteria)
    }

    var featured: [Activity] {
        ActivityBrowseFeed.featured(
            from: filtered,
            catalogIndex: catalogIndexByID,
            showsHero: showsBrowseModules
        )
    }

    /// 长列表货架（活动 Tab 主列表）。按输入指纹缓存。
    var recommendationShelves: [ActivityBrowseShelf] {
        let key = RecommendationShelvesCacheKey(
            category: selectedCategory,
            filters: quickFilters,
            dayFilter: dayFilter.map { Calendar.current.startOfDay(for: $0).timeIntervalSince1970 },
            searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            activityRevision: activities.map(\.id),
            distanceRevision: activities.map { activity in
                UInt16(min(65_535, max(0, Int((activity.distanceKM * 10).rounded()))))
            },
            availabilityRevision: activities.map { activity in
                (UInt32(min(65_535, activity.joined)) << 16)
                    | UInt32(min(65_535, max(0, activity.capacity)))
            },
            joinedIDs: joinedIDs,
            spotlightID: spotlightActivity?.id
        )
        if key == recommendationShelvesCacheKey {
            return cachedRecommendationShelves
        }
        let built = ActivityBrowseHomeCatalog.shelves(
            activities: filtered,
            joined: joinedActivities,
            catalogIndex: catalogIndexByID,
            excluding: spotlightExcludedIDs
        )
        cachedRecommendationShelves = built
        recommendationShelvesCacheKey = key
        return built
    }

    /// 今日焦点：浏览态用精选池首卡，否则用当前目录首卡。
    var spotlightActivity: Activity? {
        if showsBrowseModules, let featured = featured.first {
            return featured
        }
        return filtered.first
    }

    /// 焦点 Hero 占用的活动 id（货架编排跨轨去重）。
    private var spotlightExcludedIDs: Set<UUID> {
        guard let spotlightActivity else { return [] }
        return [spotlightActivity.id]
    }

    /// 打开详情即记一次隐式浏览信号，喂给推荐做行为学习（见 ActivityEngagementStore）
    func recordDetailView(_ id: Activity.ID) {
        guard let activity = activity(id: id) else { return }
        engagementStore.record(.viewed, for: activity)
        recentBrowseStore.record(activity)
    }

    func clearQuickFilters() {
        quickFilters = []
        dayFilter = nil
    }

    func toggleQuickFilter(_ filter: ActivityQuickFilter) {
        if filter.isTimeFilter {
            dayFilter = nil
            if quickFilters.contains(filter) {
                quickFilters.remove(filter)
            } else {
                quickFilters = Set(quickFilters.filter { !$0.isTimeFilter } + [filter])
            }
        } else if quickFilters.contains(filter) {
            quickFilters.remove(filter)
        } else {
            quickFilters.insert(filter)
        }
    }

    /// 欢迎引导等场景：应用筛选并触发 chip 高亮反馈
    func applyWelcomeQuickFilter(_ filter: ActivityQuickFilter) {
        if !quickFilters.contains(filter) {
            toggleQuickFilter(filter)
        }
        lastHighlightedQuickFilter = filter
        quickFilterHighlightToken += 1
    }

    /// 欢迎意图落地：切到推荐分类，并按目录智能套用快捷筛选。
    @discardableResult
    func applyWelcomeLanding(for intent: AppWelcomeIntent, now: Date = .now) -> String? {
        selectedCategory = .forYou
        switch intent {
        case .findActivity:
            clearQuickFilters()
            if let filter = ActivityWelcomeLanding.recommendedQuickFilter(activities: activities, now: now) {
                applyWelcomeQuickFilter(filter)
                return ActivityWelcomeLanding.confirmation(for: filter)
            }
            return AppWelcomeGuideCopy.findActivityConfirmedGeneric
        case .browse:
            clearQuickFilters()
            return AppWelcomeGuideCopy.browseConfirmed
        case .meetPeople:
            return nil
        }
    }

    /// 发现引导胶囊：套用欢迎落地筛选并返回轻反馈文案。
    @discardableResult
    func applyDiscoverPromoLanding(now: Date = .now) -> String? {
        applyWelcomeLanding(for: .findActivity, now: now)
    }
}

/// 货架缓存指纹：分类 / 筛选 / 目录顺序 / 距离 / 报名变化时失效
struct RecommendationShelvesCacheKey: Equatable {
    var category: ActivityCategory
    var filters: Set<ActivityQuickFilter>
    var dayFilter: TimeInterval?
    var searchText: String
    var activityRevision: [UUID]
    var distanceRevision: [UInt16]
    var availabilityRevision: [UInt32]
    var joinedIDs: Set<UUID>
    var spotlightID: UUID?
}

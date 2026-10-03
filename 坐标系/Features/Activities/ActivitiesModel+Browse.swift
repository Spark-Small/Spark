//
//  ActivitiesModel+Browse.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import CoordinateModels

extension ActivitiesModel {
    /// 默认浏览态：精选 Hero + 目录模块（有快捷筛选时隐藏精选）
    var showsBrowseModules: Bool {
        quickFilters.isEmpty
    }

    private var catalogIndexByID: [UUID: Int] {
        Dictionary(uniqueKeysWithValues: activities.enumerated().map { ($0.element.id, $0.offset) })
    }

    private var browseCriteria: ActivityBrowseCriteria {
        ActivityBrowseCriteria(
            category: selectedCategory,
            quickFilters: quickFilters,
            nearbyRadiusKM: resolvedNearbyRadiusKM
        )
    }

    /// 启用「附近」时用会话半径；未选档位则回落全局默认（仅读，不写）。
    private var resolvedNearbyRadiusKM: Double {
        nearbyFilterRadiusKM ?? RecommendationConfig.nearbyKM
    }

    /// 当前可见目录（分类 / 快捷筛选）
    var filtered: [Activity] {
        browse.filter.execute(activities: activities, criteria: browseCriteria)
    }

    var featured: [Activity] {
        guard let spot = ActivityBrowseFeed.spotlight(
            from: filtered,
            catalogIndex: catalogIndexByID,
            showsHero: showsBrowseModules
        ) else { return [] }
        return [spot]
    }

    /// 长列表货架（活动 Tab 主列表）。按输入指纹缓存。
    var recommendationShelves: [ActivityBrowseShelf] {
        let key = RecommendationShelvesCacheKey(
            category: selectedCategory,
            filters: quickFilters,
            nearbyRadiusKM: quickFilters.contains(.nearby) ? resolvedNearbyRadiusKM : nil,
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

    /// 今日焦点：仅默认浏览态用精选池首卡（筛选时不抢转化路径）。
    var spotlightActivity: Activity? {
        featured.first
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
        nearbyFilterRadiusKM = nil
    }

    func clearBrowseQuery() {
        clearQuickFilters()
    }

    func toggleQuickFilter(_ filter: ActivityQuickFilter) {
        if filter.isTimeFilter {
            if quickFilters.contains(filter) {
                quickFilters.remove(filter)
            } else {
                quickFilters = Set(quickFilters.filter { !$0.isTimeFilter } + [filter])
            }
        } else if filter == .nearby {
            if quickFilters.contains(.nearby) {
                quickFilters.remove(.nearby)
                nearbyFilterRadiusKM = nil
            } else {
                quickFilters.insert(.nearby)
                if nearbyFilterRadiusKM == nil {
                    nearbyFilterRadiusKM = RecommendationConfig.nearbyKM
                }
            }
        } else if quickFilters.contains(filter) {
            quickFilters.remove(filter)
        } else {
            quickFilters.insert(filter)
        }
    }

    /// 欢迎引导等场景：应用筛选
    func applyWelcomeQuickFilter(_ filter: ActivityQuickFilter) {
        if !quickFilters.contains(filter) {
            toggleQuickFilter(filter)
        }
    }

    /// 欢迎意图落地：切到推荐分类，并按目录智能套用快捷筛选。
    @discardableResult
    func applyWelcomeLanding(for intent: AppWelcomeIntent, now: Date = .now) -> String? {
        selectBrowseCategory(.forYou)
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

/// 货架缓存指纹：分类 / 筛选 / 附近半径 / 目录顺序 / 距离 / 报名变化时失效
struct RecommendationShelvesCacheKey: Equatable {
    var category: ActivityCategory
    var filters: Set<ActivityQuickFilter>
    var nearbyRadiusKM: Double?
    var activityRevision: [UUID]
    var distanceRevision: [UInt16]
    var availabilityRevision: [UInt32]
    var joinedIDs: Set<UUID>
    var spotlightID: UUID?
}

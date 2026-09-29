//
//  ActivityWelcomeLanding.swift
//  坐标系
//
//  欢迎引导落地：按目录智能推荐快捷筛选，不固定「本周末」。
//

import CoordinateDomain
import CoordinateModels
import Foundation

enum ActivityWelcomeLanding {
    private static let filter = FilterActivitiesBrowseUseCase()
    private static let nearbyRadiusKM = 20.0

    /// 按「今天 → 本周末 → 免费 → 有空位」优先级，选第一个有结果的条件。
    static func recommendedQuickFilter(
        activities: [Activity],
        now: Date = .now
    ) -> ActivityQuickFilter? {
        let candidates: [ActivityQuickFilter] = [.today, .weekend, .free]
            .filter { ActivityQuickFilter.browseChipOrder.contains($0) }
        for quickFilter in candidates {
            let criteria = ActivityBrowseCriteria(
                category: .forYou,
                quickFilters: [quickFilter],
                nearbyRadiusKM: nearbyRadiusKM,
                now: now
            )
            if !filter.execute(activities: activities, criteria: criteria).isEmpty {
                return quickFilter
            }
        }
        return nil
    }

    static func confirmation(for filter: ActivityQuickFilter?) -> String {
        guard let filter else { return AppWelcomeGuideCopy.findActivityConfirmedGeneric }
        return AppWelcomeGuideCopy.filterConfirmed(filter.rawValue)
    }
}

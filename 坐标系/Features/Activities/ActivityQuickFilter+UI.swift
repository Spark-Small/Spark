//
//  ActivityQuickFilter+UI.swift
//  坐标系
//

import CoordinateModels
import Foundation

extension ActivityQuickFilter {
    var systemImage: String {
        switch self {
        case .weekend: "calendar.badge.clock"
        case .today: "sun.max"
        case .tomorrow: "sunrise"
        case .nearby: "location"
        case .free: "gift"
        case .available: "person.badge.plus"
        }
    }

    /// 活动发现页快捷 chip 展示顺序（其余条件在顶栏筛选 Menu）
    static var browseChipOrder: [ActivityQuickFilter] {
        [.weekend, .today, .free]
    }

    /// 顶栏筛选按钮：未生效 = 漏斗；生效 = 当前主条件图标（多条件取优先项，无角标）。
    static func toolbarSystemImage(
        quickFilters: Set<ActivityQuickFilter>,
        nearbyRadiusKM: Double?
    ) -> String {
        let priority: [ActivityQuickFilter] = [
            .today, .tomorrow, .weekend, .nearby, .free, .available
        ]
        if let match = priority.first(where: { quickFilters.contains($0) }) {
            return match.systemImage
        }
        if nearbyRadiusKM != nil {
            return ActivityQuickFilter.nearby.systemImage
        }
        return "line.3.horizontal.decrease"
    }
}

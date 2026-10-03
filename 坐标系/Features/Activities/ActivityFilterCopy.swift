//
//  ActivityFilterCopy.swift
//  坐标系
//
//  活动筛选文案（顶栏 Menu 即时筛选）。
//

import Foundation
import CoordinateModels

enum ActivityFilterCopy {
    static let menuTitle = "筛选"
    static let menuTitleActive = "筛选（已启用）"
    static let clear = "清除筛选"
    static let menuHint = "选择时间、距离或费用条件"
    static let categoryMenu = "分类"

    static let whenSection = "时间"
    static let whenAny = "不限"
    static let whenToday = "今天"
    static let whenTomorrow = "明天"
    static let whenWeekend = "本周末"

    static let distanceSection = "距离"
    static let distanceAny = "不限"
    static let distanceThree = "3 公里内"
    static let distanceFive = "5 公里内"
    static let distanceTen = "10 公里内"
    static let distanceTwentyFive = "25 公里内"

    static let free = "只看免费"
    static let available = "只看有空位"

    /// VoiceOver：概括当前生效条件。
    static func accessibilityValue(
        quickFilters: Set<ActivityQuickFilter>,
        nearbyRadiusKM: Double?
    ) -> String {
        var parts: [String] = []
        if quickFilters.contains(.today) { parts.append(whenToday) }
        if quickFilters.contains(.tomorrow) { parts.append(whenTomorrow) }
        if quickFilters.contains(.weekend) { parts.append(whenWeekend) }
        if quickFilters.contains(.nearby) {
            if let km = nearbyRadiusKM, km > 0 {
                parts.append("\(Int(km.rounded())) 公里内")
            } else {
                parts.append(ActivityQuickFilter.nearby.rawValue)
            }
        }
        if quickFilters.contains(.free) { parts.append(free) }
        if quickFilters.contains(.available) { parts.append(available) }
        return parts.isEmpty ? whenAny : parts.joined(separator: "、")
    }
}

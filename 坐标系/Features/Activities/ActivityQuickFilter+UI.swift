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

    /// 活动发现页快捷 chip 展示顺序（其余在筛选 Sheet）
    static var browseChipOrder: [ActivityQuickFilter] {
        [.weekend, .today, .free]
    }
}

//
//  ActivityScheduling.swift
//  坐标系
//
//  行程冲突检测等 App 层调度辅助（生命周期见 CoordinateDomain）。
//

import CoordinateDomain
import Foundation
import CoordinateModels

extension Activity {
    /// 本地推算的结束时间（与生命周期宽限一致，用于行程冲突检测）
    var estimatedEndDate: Date {
        date.addingTimeInterval(ActivityLifecycle.ongoingGrace)
    }

    var estimatedTimeRange: Range<Date> {
        date..<estimatedEndDate
    }

    func scheduleOverlaps(_ other: Activity) -> Bool {
        id != other.id && estimatedTimeRange.overlaps(other.estimatedTimeRange)
    }
}

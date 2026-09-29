//
//  ActivityBrowseCriteria.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct ActivityBrowseCriteria: Sendable, Equatable {
    public var category: ActivityCategory
    public var quickFilters: Set<ActivityQuickFilter>
    public var dayFilter: Date?
    public var nearbyRadiusKM: Double
    /// 标题 / 地点 / 主办 / 摘要 / 标签的本地文字搜索。
    public var searchText: String
    public var now: Date

    public init(
        category: ActivityCategory,
        quickFilters: Set<ActivityQuickFilter>,
        dayFilter: Date? = nil,
        nearbyRadiusKM: Double,
        searchText: String = "",
        now: Date = .now
    ) {
        self.category = category
        self.quickFilters = quickFilters
        self.dayFilter = dayFilter
        self.nearbyRadiusKM = nearbyRadiusKM
        self.searchText = searchText
        self.now = now
    }
}

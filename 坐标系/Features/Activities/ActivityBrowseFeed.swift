//
//  ActivityBrowseFeed.swift
//  坐标系
//
//  发现页精选 Hero：只取推荐池首卡作为 spotlight。
//

import Foundation
import CoordinateModels

@MainActor
enum ActivityBrowseFeed {
    /// 浏览态 Hero 首卡；筛选 / 空目录时不展示
    static func spotlight(
        from catalog: [Activity],
        catalogIndex: [UUID: Int],
        showsHero: Bool
    ) -> Activity? {
        guard showsHero, !catalog.isEmpty else { return nil }
        let openSpots = catalog.filter { !$0.isPast && $0.hasAvailableSpots }
        return ActivityRecommender.ranked(
            from: openSpots,
            catalogIndex: catalogIndex,
            limit: 1
        ).first
    }
}

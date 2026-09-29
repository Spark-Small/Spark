//
//  ActivityBrowseFeed.swift
//  坐标系
//
//  发现页精选 Hero 编排。
//

import Foundation
import CoordinateModels

@MainActor
enum ActivityBrowseFeed {
    /// 精选场次：推荐池足够时按分数落在 3–5，不足则按实际数量。
    /// `nonisolated`：可作 default 参数（在 nonisolated 上下文求值）。
    nonisolated static let featuredMinCount = 3
    nonisolated static let featuredMaxCount = 5

    /// 浏览态精选；筛选 / 空目录时不展示 Hero
    static func featured(
        from catalog: [Activity],
        catalogIndex: [UUID: Int],
        showsHero: Bool,
        minCount: Int = featuredMinCount,
        maxCount: Int = featuredMaxCount
    ) -> [Activity] {
        guard showsHero, !catalog.isEmpty else { return [] }
        let openSpots = catalog.filter { !$0.isPast && $0.hasAvailableSpots }
        return featuredSlice(
            from: openSpots,
            catalogIndex: catalogIndex,
            minCount: minCount,
            maxCount: maxCount
        )
    }

    /// 取推荐分最高的一批：最多 max，分数接近头部时扩到 3–5，尾部掉分则提前截断
    private static func featuredSlice(
        from openSpots: [Activity],
        catalogIndex: [UUID: Int],
        minCount: Int,
        maxCount: Int
    ) -> [Activity] {
        let ranked = ActivityRecommender.ranked(
            from: openSpots,
            catalogIndex: catalogIndex,
            limit: maxCount
        )
        guard ranked.count > minCount else { return ranked }

        let scores = ranked.map {
            ActivityRecommender.score(for: $0, catalogIndex: catalogIndex[$0.id])
        }
        guard let top = scores.first, top > 0 else {
            return Array(ranked.prefix(minCount))
        }

        var keep = minCount
        for index in minCount..<ranked.count {
            // 相对头部仍有约七成分数则留下，否则截断
            if scores[index] * 10 >= top * 7 {
                keep = index + 1
            } else {
                break
            }
        }
        return Array(ranked.prefix(keep))
    }
}

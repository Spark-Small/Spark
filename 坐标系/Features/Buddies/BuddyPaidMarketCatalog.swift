//
//  BuddyPaidMarketCatalog.swift
//  坐标系
//
//  陪玩榜周期、排序与展示辅助。
//

import Foundation
import SwiftUI
import CoordinateModels

enum BuddyPaidBoardPeriod: String, CaseIterable, Identifiable {
    case day = "日榜"
    case week = "周榜"
    case month = "月榜"

    var id: String { rawValue }
}

enum BuddyPaidMarketCatalog {
    static func shortSpecialty(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let head = trimmed.split(separator: "/").first {
            let piece = String(head).trimmingCharacters(in: .whitespacesAndNewlines)
            if piece.count <= 8 { return piece }
            return String(piece.prefix(8))
        }
        if trimmed.count <= 8 { return trimmed }
        return String(trimmed.prefix(8))
    }

    static func ranked(
        _ items: [DiscoverBuddyItem],
        period: BuddyPaidBoardPeriod
    ) -> [DiscoverBuddyItem] {
        let paid: [(DiscoverBuddyItem, PaidCompanion)] = items.compactMap {
            guard case .paid(let companion) = $0 else { return nil }
            return ($0, companion)
        }
        let sorted = paid.sorted { lhs, rhs in
            let left = boardScore(lhs.1, period: period)
            let right = boardScore(rhs.1, period: period)
            if left != right { return left > right }
            return lhs.1.hourlyPrice < rhs.1.hourlyPrice
        }
        return sorted.map(\.0)
    }

    static func boardScore(_ companion: PaidCompanion, period: BuddyPaidBoardPeriod) -> Int {
        let base = companion.orderCount
        switch period {
        case .day:
            return max(1, base / 12) + (companion.isAvailable ? 8 : 0)
        case .week:
            return max(1, base / 4) + (companion.isVerified ? 5 : 0)
        case .month:
            return base
        }
    }

    /// 榜行展示分：优先读评价库，无数据时用成单量推导演示分
    @MainActor
    static func displayRating(for companion: PaidCompanion) -> Double {
        PlatformReviewCatalog.displayRating(for: companion)
    }

    @MainActor
    static func reviewCount(for companion: PaidCompanion) -> Int {
        PlatformReviewCatalog.reviewCount(for: companion)
    }

    static func leaderboardTags(for companion: PaidCompanion, limit: Int = 2) -> [String] {
        Array(companion.profile.tags.prefix(limit))
    }

    /// 榜行平台角标（Top 10 展示；与性格亮点区分）
    @MainActor
    static func leaderboardHotBadge(for companion: PaidCompanion, rank: Int) -> BuddyPaidHotBadge? {
        guard rank <= 10 else { return nil }
        return BuddyPaidHotBadge.forCompanion(companion, rank: rank)
    }

    /// 榜行个人亮点：他人评价 / 性格标签（非平台指标）
    static func leaderboardHighlights(for companion: PaidCompanion, limit: Int = 2) -> [String] {
        var boosted: [String] = []
        let specialty = companion.specialty

        switch companion.serviceType {
        case .voice:
            boosted += ["声音好听", "善于倾听", "聊天不尬"]
        case .sport:
            boosted += ["节奏稳定", "新手友好", "鼓励型"]
        case .offline:
            boosted += ["懂氛围", "不冷场", "会找店"]
        case .photo:
            boosted += ["会找角度", "出片快", "审美在线"]
        }

        switch companion.profile.gender {
        case .female:
            boosted += ["甜美可人", "细心体贴", "温柔耐心"]
        case .male:
            boosted += ["阳光开朗", "靠谱领队", "风趣幽默"]
        }

        if specialty.localizedCaseInsensitiveContains("陪吃")
            || specialty.localizedCaseInsensitiveContains("火锅")
            || specialty.localizedCaseInsensitiveContains("探店") {
            boosted.append("懂氛围")
        }
        if specialty.localizedCaseInsensitiveContains("陪练")
            || specialty.localizedCaseInsensitiveContains("羽毛球") {
            boosted.append("专业认真")
        }

        let general = [
            "风趣幽默", "温柔耐心", "准时靠谱", "氛围轻松",
            "沟通顺畅", "专业认真", "节奏稳定", "不冷场",
            "很会聊", "有耐心", "懂路线", "超预期"
        ]

        var candidates: [String] = []
        var seen = Set<String>()
        for item in boosted + general where seen.insert(item).inserted {
            candidates.append(item)
        }

        let seed = abs(companion.id.hashValue)
        var picked: [String] = []
        var index = 0
        while picked.count < limit, index < candidates.count * 2 {
            let trait = candidates[(seed + index * 5) % candidates.count]
            if !picked.contains(trait) {
                picked.append(trait)
            }
            index += 1
        }
        return picked
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}


//
//  BuddyPaidHotBadge.swift
//  坐标系
//
//  陪玩榜 / Top 卡角标推导。
//

import SwiftUI
import CoordinateModels

enum BuddyPaidHotBadge: String, CaseIterable, Hashable {
    case recommended = "推荐"
    case booming = "火爆"
    case popular = "热门"
    case rising = "新晋"
    case topRated = "高评"
    case quickReply = "秒回"
    case reputation = "口碑好"
    case trending = "飙升"
    case reliable = "靠谱"
    case gem = "宝藏"
    case repeatGuest = "回头客"
    case valuePick = "超值"

    var tint: Color {
        switch self {
        case .recommended: Color.accentColor
        case .booming: .pink
        case .popular: .orange
        case .rising: .mint
        case .topRated: .yellow
        case .quickReply: .cyan
        case .reputation: .purple
        case .trending: .indigo
        case .reliable: PlatformStatus.success
        case .gem: .teal
        case .repeatGuest: .brown
        case .valuePick: .blue
        }
    }

    /// Top 卡角标：按名次、成单、评分、响应稳定推导，不用哈希抽签。
    @MainActor
    static func forCompanion(_ companion: PaidCompanion, rank: Int) -> BuddyPaidHotBadge {
        let rating = BuddyPaidMarketCatalog.displayRating(for: companion)
        let reviews = BuddyPaidMarketCatalog.reviewCount(for: companion)

        if rank == 1 { return .recommended }
        if companion.orderCount >= 120 { return .booming }
        if rating >= 4.9, reviews >= 24 { return .topRated }
        if isQuickResponder(companion) { return .quickReply }
        if companion.orderCount >= 80, reviews >= 30 { return .repeatGuest }
        if rank <= 2, companion.orderCount >= 60 { return .popular }
        if reviews >= 36 { return .reputation }
        if companion.orderCount < 45, rank <= 4 { return .rising }
        if companion.hourlyPrice <= 99, companion.isAvailable { return .valuePick }
        if companion.isVerified, companion.isAvailable { return .reliable }
        if companion.orderCount >= 20 { return .rising }
        return .popular
    }

    private static func isQuickResponder(_ companion: PaidCompanion) -> Bool {
        let text = companion.responseTime
        guard text.localizedCaseInsensitiveContains("分钟") else { return false }
        let digits = text.filter(\.isNumber)
        guard let minutes = Int(digits.prefix(2)) else {
            return text.contains("10") || text.contains("15") || text.contains("20")
        }
        return minutes <= 20
    }
}


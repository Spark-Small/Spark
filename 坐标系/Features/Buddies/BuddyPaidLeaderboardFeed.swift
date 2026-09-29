//
//  BuddyPaidLeaderboardFeed.swift
//  坐标系
//
//  陪玩榜 Feed 项与穿插规划。
//

import SwiftUI
import CoordinateModels

enum BuddyPaidLeaderboardFeedItem: Identifiable {
    case companion(DiscoverBuddyItem, rank: Int)
    case promo(BuddyPaidQuickEntry)

    var id: String {
        switch self {
        case .companion(let item, let rank): "companion-\(item.id)-\(rank)"
        case .promo(let entry): "promo-\(entry.rawValue)"
        }
    }
}

enum BuddyPaidLeaderboardFeedPlanner {
    /// 在推荐榜行之间穿插快捷长条：前段语音、中段匹配，随列表长度自适应
    static func buildFeed(from items: [DiscoverBuddyItem], maxRows: Int = 10) -> [BuddyPaidLeaderboardFeedItem] {
        let rows = Array(items.prefix(maxRows))
        guard !rows.isEmpty else { return [] }

        let placements = promoPlacements(rowCount: rows.count)
        var feed: [BuddyPaidLeaderboardFeedItem] = []

        for (index, item) in rows.enumerated() {
            let rank = index + 1
            feed.append(.companion(item, rank: rank))
            for placement in placements where placement.insertAfterRank == rank {
                feed.append(.promo(placement.entry))
            }
        }
        return feed
    }

    private static func promoPlacements(rowCount: Int) -> [(insertAfterRank: Int, entry: BuddyPaidQuickEntry)] {
        var result: [(insertAfterRank: Int, entry: BuddyPaidQuickEntry)] = []
        let voiceAfter = min(2, rowCount)
        result.append((insertAfterRank: voiceAfter, entry: .voiceParty))

        let matchAfter = min(max(4, rowCount / 2 + 1), rowCount)
        if matchAfter != voiceAfter {
            result.append((insertAfterRank: matchAfter, entry: .quickMatch))
        } else if rowCount >= 3 {
            result.append((insertAfterRank: min(voiceAfter + 2, rowCount), entry: .quickMatch))
        }
        return result.sorted { $0.insertAfterRank < $1.insertAfterRank }
    }
}


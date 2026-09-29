//
//  BuddyPaidLeaderboard.swift
//  坐标系
//
//  陪玩发现：推荐榜宿主。
//

import SwiftUI
import CoordinateModels

// MARK: - Leaderboard

struct BuddyPaidLeaderboard: View {
    let items: [DiscoverBuddyItem]
    @Binding var period: BuddyPaidBoardPeriod
    var zoomNamespace: Namespace.ID
    var onBook: (DiscoverBuddyItem) -> Void
    var onQuickEntry: (BuddyPaidQuickEntry) -> Void

    private var topThree: [DiscoverBuddyItem] { Array(items.prefix(3)) }
    private var feedItems: [BuddyPaidLeaderboardFeedItem] {
        BuddyPaidLeaderboardFeedPlanner.buildFeed(from: items)
    }

    var body: some View {
        DiscoverBrowseSection(
            title: "推荐陪玩",
            subtitle: "示例榜 · 按成单与评价排序"
        ) {
            VStack(spacing: PlatformMetrics.discoverCardSpacing) {
                if !topThree.isEmpty {
                    // 轨自带 contentInset，勿再外包一层水平边距
                    DiscoverHorizontalRail {
                        ForEach(Array(topThree.enumerated()), id: \.element.id) { index, item in
                            if case .paid(let companion) = item {
                                BuddyPaidTopCard(
                                    rank: index + 1,
                                    companion: companion,
                                    badge: .forCompanion(companion, rank: index),
                                    zoomNamespace: zoomNamespace,
                                    onBook: { onBook(item) }
                                )
                                .platformPosterRailFrame()
                            }
                        }
                    }
                }

                VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    DiscoverSectionTitleRow(
                        title: BuddyBrowseCopy.leaderboardRankTitle,
                        showsHorizontalInset: false
                    ) {
                        Menu {
                            ForEach(BuddyPaidBoardPeriod.allCases) { option in
                                Button {
                                    period = option
                                } label: {
                                    Label(option.rawValue, systemImage: period == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                Text(period.rawValue)
                                    .font(.caption.weight(.medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(feedItems) { feedItem in
                        switch feedItem {
                        case .companion(let item, let rank):
                            if case .paid(let companion) = item {
                                BuddyPaidLeaderboardRow(
                                    rank: rank,
                                    companion: companion,
                                    zoomNamespace: zoomNamespace,
                                    onBook: { onBook(item) }
                                )
                            }
                        case .promo(let entry):
                            BuddyPaidQuickEntryBar(entry: entry) {
                                onQuickEntry(entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }
        }
    }
}

/// Top 3 奖牌竖卡：封面叠字 + 卡内下单，信息不与按钮重叠

//
//  BuddyPaidLeaderboard.swift
//  坐标系
//
//  陪玩发现：推荐榜 = Top3 + 查看全部；不与下方榜行重复同池。
//

import SwiftUI
import CoordinateModels

// MARK: - Leaderboard

struct BuddyPaidLeaderboard: View {
    let items: [DiscoverBuddyItem]
    @Binding var period: BuddyPaidBoardPeriod
    var zoomNamespace: Namespace.ID
    var contactTitle: (DiscoverBuddyItem) -> String = { _ in BuddyBrowseCopy.chatAction }
    var onChat: (DiscoverBuddyItem) -> Void = { _ in }
    var onBook: (DiscoverBuddyItem) -> Void = { _ in }
    var onQuickEntry: (BuddyPaidQuickEntry) -> Void
    var onSeeAll: (() -> Void)? = nil

    private var topThree: [DiscoverBuddyItem] { Array(items.prefix(3)) }

    private var promoEntries: [BuddyPaidQuickEntry] {
        var result: [BuddyPaidQuickEntry] = []
        if items.count >= 2 { result.append(.voiceParty) }
        if items.count >= 3 { result.append(.quickMatch) }
        return result
    }

    var body: some View {
        DiscoverBrowseSection(
            title: BuddyBrowseCopy.PaidShelf.leaderboardTitle,
            subtitle: BuddyBrowseCopy.PaidShelf.leaderboardSubtitle,
            showsChevron: onSeeAll != nil,
            onSeeAll: onSeeAll
        ) {
            VStack(spacing: PlatformMetrics.discoverCardSpacing) {
                HStack {
                    Spacer(minLength: 0)
                    periodMenu
                }
                .discoverBrowseContentInset()

                if !topThree.isEmpty {
                    DiscoverHorizontalRail {
                        ForEach(Array(topThree.enumerated()), id: \.element.id) { index, item in
                            if case .paid(let companion) = item {
                                BuddyPaidTopCard(
                                    rank: index + 1,
                                    companion: companion,
                                    badge: .forCompanion(companion, rank: index),
                                    zoomNamespace: zoomNamespace,
                                    contextActions: contextActions(for: item)
                                )
                                .platformPosterRailFrame()
                            }
                        }
                    }
                }

                if !promoEntries.isEmpty {
                    VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                        ForEach(promoEntries) { entry in
                            BuddyPaidQuickEntryBar(entry: entry) {
                                onQuickEntry(entry)
                            }
                        }
                    }
                    .discoverBrowseContentInset()
                }
            }
        }
    }

    private var periodMenu: some View {
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
        .accessibilityLabel(BuddyBrowseCopy.leaderboardRankTitle)
        .accessibilityValue(period.rawValue)
    }

    private func contextActions(for item: DiscoverBuddyItem) -> BuddyPersonBrowseContextActions {
        .make(
            item: item,
            contactTitle: contactTitle(item),
            onContact: { onChat(item) },
            onBook: { onBook(item) }
        )
    }
}

/// Top 3 + 查看全部；无同池榜行重复。预约在详情或 Context Menu。

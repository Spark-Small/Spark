//
//  BuddyBrowseShelves.swift
//  坐标系
//
//  搭子发现货架渲染 + 查看全部 + 语音厅。
//

import SwiftUI
import CoordinateModels

// MARK: - See all route

struct BuddyBrowseSeeAllRoute: Hashable, Identifiable {
    let id: String
    let title: String
    let itemIDs: [UUID]
    let pool: BuddyBrowsePool
}

/// 搭子发现分区：同好 / 陪玩（同页零切换）。
enum BuddyBrowsePool: Hashable {
    case free
    case paid
}

struct BuddyBrowseSeeAllView: View {
    let title: String
    let items: [DiscoverBuddyItem]
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var contactTitle: (DiscoverBuddyItem) -> String = { _ in BuddyBrowseCopy.chatAction }
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: (DiscoverBuddyItem) -> Void

    var body: some View {
        ScrollView {
            BuddyPersonGrid(
                items: items,
                intentQuery: intentQuery,
                zoomNamespace: zoomNamespace,
                contactTitle: contactTitle,
                onChat: onChat,
                onBook: onBook
            )
            .padding(.vertical, PlatformMetrics.sectionSpacing)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - Shelf section

struct BuddyBrowseShelfSection: View {
    let shelf: BuddyBrowseShelf
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var boardPeriod: Binding<BuddyPaidBoardPeriod>? = nil
    var contactTitle: (DiscoverBuddyItem) -> String = { _ in BuddyBrowseCopy.chatAction }
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: (DiscoverBuddyItem) -> Void
    var onQuickEntry: ((BuddyPaidQuickEntry) -> Void)? = nil
    var onSeeAll: ((BuddyBrowseShelf) -> Void)? = nil

    var body: some View {
        switch shelf.layout {
        case .leaderboard:
            if let boardPeriod {
                BuddyPaidLeaderboard(
                    items: shelf.items,
                    period: boardPeriod,
                    zoomNamespace: zoomNamespace,
                    contactTitle: contactTitle,
                    onChat: onChat,
                    onBook: onBook,
                    onQuickEntry: { onQuickEntry?($0) },
                    onSeeAll: shelf.showsSeeAll ? { onSeeAll?(shelf) } : nil
                )
            }
        default:
            DiscoverBrowseSection(
                title: shelf.title,
                showsChevron: shelf.showsSeeAll && onSeeAll != nil,
                onSeeAll: shelf.showsSeeAll ? { onSeeAll?(shelf) } : nil
            ) {
                BuddyBrowseShelfRailContent(
                    shelf: shelf,
                    intentQuery: intentQuery,
                    zoomNamespace: zoomNamespace,
                    contactTitle: contactTitle,
                    onChat: onChat,
                    onBook: onBook
                )
            }
        }
    }
}

struct BuddyBrowseShelfRailContent: View {
    let shelf: BuddyBrowseShelf
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var contactTitle: (DiscoverBuddyItem) -> String = { _ in BuddyBrowseCopy.chatAction }
    var onChat: (DiscoverBuddyItem) -> Void = { _ in }
    var onBook: (DiscoverBuddyItem) -> Void = { _ in }

    var body: some View {
        switch shelf.layout {
        case .editorial:
            editorialRail(shelf.items)
        case .hot:
            hotRail(shelf.items)
        case .leaderboard:
            EmptyView()
        }
    }

    private func editorialRail(_ items: [DiscoverBuddyItem]) -> some View {
        DiscoverHorizontalRail {
            ForEach(items) { item in
                BuddyPickCard(
                    item: item,
                    intentQuery: intentQuery,
                    zoomNamespace: zoomNamespace,
                    contextActions: .make(
                        item: item,
                        contactTitle: contactTitle(item),
                        onContact: { onChat(item) },
                        onBook: { onBook(item) }
                    )
                )
                .platformPersonFeaturedRailFrame()
            }
        }
    }

    private func hotRail(_ items: [DiscoverBuddyItem]) -> some View {
        DiscoverHorizontalRail {
            ForEach(items) { item in
                BuddyGridCard(
                    item: item,
                    intentQuery: intentQuery,
                    zoomNamespace: zoomNamespace,
                    contextActions: .make(
                        item: item,
                        contactTitle: contactTitle(item),
                        onContact: { onChat(item) },
                        onBook: { onBook(item) }
                    )
                )
                .platformPosterRailFrame()
            }
        }
    }
}

// MARK: - 语音厅

struct BuddyVoiceChannelCard: View {
    let hall: VoiceHall
    var onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dynamicMicSide: CGFloat {
        (dynamicTypeSize.listAvatarSide * 0.85).rounded(.toNearestOrAwayFromZero)
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.minContentGap) {
                    Label(hall.title, systemImage: "speaker.wave.2.fill")
                        .font(.headline.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(hall.isLive ? BuddyBrowseCopy.VoiceHall.live : BuddyBrowseCopy.VoiceHall.idle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hall.isLive ? PlatformStatus.success : .secondary)
                }

                Text(hall.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                    micAvatarStack
                    Text(hall.audienceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Text(BuddyBrowseCopy.ShelfA11y.enterVoiceHall)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(PlatformMetrics.contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hall.title)，\(hall.topic)，\(hall.audienceText)")
        .accessibilityHint(BuddyBrowseCopy.ShelfA11y.enterVoiceHallHint)
    }

    private var micAvatarStack: some View {
        HStack(spacing: -PlatformMetrics.minContentGap) {
            ForEach(Array(hall.onMicNicknames.prefix(4).enumerated()), id: \.offset) { _, name in
                PlatformListAvatarView(name: name, side: dynamicMicSide)
                    .overlay {
                        Circle().strokeBorder(PlatformSurface.elevated, lineWidth: 2)
                    }
            }
            if hall.onMicNicknames.count > 4 {
                Text("+\(hall.onMicNicknames.count - 4)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, PlatformMetrics.minContentGap)
            }
        }
        .accessibilityHidden(true)
    }
}

struct BuddyVoiceChannelRail: View {
    let halls: [VoiceHall]
    var onOpen: (VoiceHall) -> Void

    var body: some View {
        DiscoverBrowseSection(
            title: BuddyBrowseCopy.VoiceHall.sectionTitle,
            subtitle: BuddyBrowseCopy.VoiceHall.sectionSubtitle
        ) {
            DiscoverHorizontalRail {
                ForEach(halls) { hall in
                    BuddyVoiceChannelCard(hall: hall) {
                        onOpen(hall)
                    }
                    .platformContinueRailFrame()
                }
            }
        }
    }
}

//
//  BuddyBrowseShelves.swift
//  坐标系
//
//  搭子发现货架渲染 + 查看全部 + 语音厅。
//

import SwiftUI

// MARK: - See all route

struct BuddyBrowseSeeAllRoute: Hashable, Identifiable {
    let id: String
    let title: String
    let itemIDs: [UUID]
}

struct BuddyBrowseSeeAllView: View {
    let title: String
    let items: [DiscoverBuddyItem]
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: (DiscoverBuddyItem) -> Void

    var body: some View {
        ScrollView {
            BuddyPersonGrid(
                items: items,
                intentQuery: intentQuery,
                zoomNamespace: zoomNamespace,
                onChat: onChat,
                onBook: onBook
            )
            .padding(.vertical, PlatformMetrics.sectionSpacing)
        }
        .background(PlatformSurface.groupedPage)
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
                    onBook: onBook,
                    onQuickEntry: { onQuickEntry?($0) }
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
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: (DiscoverBuddyItem) -> Void

    @Environment(AppModel.self) private var app

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
                    contactActionTitle: contactTitle(for: item),
                    zoomNamespace: zoomNamespace,
                    onAction: { action(for: item) }
                )
                .platformEditorialRailFrame()
            }
        }
    }

    private func hotRail(_ items: [DiscoverBuddyItem]) -> some View {
        DiscoverHorizontalRail {
            ForEach(items) { item in
                BuddyGridCard(
                    item: item,
                    intentQuery: intentQuery,
                    contactActionTitle: contactTitle(for: item),
                    zoomNamespace: zoomNamespace,
                    onAction: { action(for: item) }
                )
                .platformPosterRailFrame()
            }
        }
    }

    private func contactTitle(for item: DiscoverBuddyItem) -> String {
        app.peerContactActionTitle(
            for: item.profile.nickname,
            context: .forBuddyItem(item)
        )
    }

    private func action(for item: DiscoverBuddyItem) {
        switch item {
        case .free: onChat(item)
        case .paid: onBook(item)
        }
    }
}

// MARK: - Circles rail

struct BuddyInterestCirclesRail: View {
    let circles: [InterestCircle]
    var onOpen: (InterestCircle) -> Void
    var onSeeAll: () -> Void

    var body: some View {
        DiscoverBrowseSection(
            title: BuddyBrowseCopy.circlesTitle,
            showsChevron: true,
            onSeeAll: onSeeAll
        ) {
            DiscoverHorizontalRail {
                ForEach(circles) { circle in
                    BuddyPosterShelfCard.circle(circle) {
                        onOpen(circle)
                    }
                    .platformPosterRailFrame()
                }
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

                    Text(hall.isLive ? "直播中" : "休息中")
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
                    Text("进厅")
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
        .accessibilityHint("进入语音厅")
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
        DiscoverBrowseSection(title: "语音厅") {
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

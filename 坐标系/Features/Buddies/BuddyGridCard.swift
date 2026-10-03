//
//  BuddyGridCard.swift
//  坐标系
//
//  双列人像卡：图下文案；grid 密度无卡内 CTA，点封面进详情；长按 Context Menu。
//

import SwiftUI
import CoordinateModels

/// 双列发现人物卡：点封面进详情
struct BuddyGridCard: View {
    let item: DiscoverBuddyItem
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var contextActions: BuddyPersonBrowseContextActions? = nil

    private var metaLine: String { BuddyPersonBrowseChrome.metaLine(for: item) }
    private var intentHit: Bool { BuddyPersonBrowseChrome.intentHit(for: item, query: intentQuery) }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            coverLink
            BuddyPersonBrowseInfo(
                profile: item.profile,
                metaLine: metaLine,
                density: .grid
            )
            .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
        .accessibilityElement(children: .contain)
        .buddyPersonBrowseContextMenu(contextActions)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: "grid", namespace: zoomNamespace) {
            BuddyPersonBrowseCoverMedia(
                profile: item.profile,
                aspectRatio: PlatformMetrics.personGridCardAspectRatio
            )
            .overlay { BuddyPersonBrowseCoverBadges(item: item, density: .grid) }
        }
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(coverAccessibilityHint)
    }

    private var coverAccessibilityHint: String {
        item.profile.photoRefs.count > 1
            ? BuddyBrowseCopy.ShelfA11y.coverSwipeHint
            : ActivityCardStatus.openHint
    }

    private var accessibilitySummary: String {
        var parts = [item.profile.nickname]
        if intentHit { parts.insert("契合搜索", at: 0) }
        if !metaLine.isEmpty { parts.append(metaLine) }
        if item.profile.photoRefs.count > 1 {
            parts.append(BuddyBrowseCopy.ShelfA11y.coverMediaCount(item.profile.photoRefs.count))
        }
        if !BuddyPersonBrowseChrome.isPaid(item) {
            parts.append(contentsOf: BuddyPersonBrowseChrome.affinityTags(for: item.profile))
        }
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }
}

/// 同好双列发现网格
struct BuddyPersonGrid: View {
    let items: [DiscoverBuddyItem]
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var contactTitle: (DiscoverBuddyItem) -> String = { _ in BuddyBrowseCopy.chatAction }
    var onChat: (DiscoverBuddyItem) -> Void = { _ in }
    var onBook: ((DiscoverBuddyItem) -> Void)? = nil

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
            ForEach(items) { item in
                BuddyGridCard(
                    item: item,
                    intentQuery: intentQuery,
                    zoomNamespace: zoomNamespace,
                    contextActions: .make(
                        item: item,
                        contactTitle: contactTitle(item),
                        onContact: { onChat(item) },
                        onBook: onBook.map { book in { book(item) } }
                    )
                )
            }
        }
        .discoverBrowseContentInset()
    }
}

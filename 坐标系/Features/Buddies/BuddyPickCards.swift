//
//  BuddyPickCards.swift
//  坐标系
//
//  搭子精选 Hero（hero 密度 + CTA）+ editorial 辅卡（grid 密度，无 CTA）。
//

import SwiftUI
import CoordinateModels

enum BuddyDiscoveryPicks {
    static let spotlightLimit = 1
}

// MARK: - Spotlight Hero

struct BuddyFeaturedCard: View {
    let item: DiscoverBuddyItem
    var intentQuery: String = ""
    var contactActionTitle = BuddyBrowseCopy.chatAction
    var zoomNamespace: Namespace.ID
    var onAction: () -> Void
    var onContact: (() -> Void)? = nil
    var onBook: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var metaLine: String { BuddyPersonBrowseChrome.metaLine(for: item) }
    private var intentHit: Bool { BuddyPersonBrowseChrome.intentHit(for: item, query: intentQuery) }

    private var prefersStackedAction: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    private var openAccessibilityLabel: String {
        var parts = [item.profile.nickname]
        if intentHit { parts.insert("契合搜索", at: 0) }
        if !metaLine.isEmpty { parts.append(metaLine) }
        if item.profile.photoRefs.count > 1 {
            parts.append(BuddyBrowseCopy.ShelfA11y.coverMediaCount(item.profile.photoRefs.count))
        }
        parts.append(contentsOf: BuddyPersonBrowseChrome.affinityTags(for: item.profile))
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            cover
            footer
                .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
        .accessibilityElement(children: .contain)
        .buddyPersonBrowseContextMenu(
            .make(
                item: item,
                contactTitle: contactActionTitle,
                onContact: { (onContact ?? onAction)() },
                onBook: onBook ?? (BuddyPersonBrowseChrome.isPaid(item) ? onAction : nil)
            )
        )
    }

    private var cover: some View {
        BuddyZoomNavigationLink(item: item, slot: "spotlight", namespace: zoomNamespace) {
            BuddyPersonBrowseCoverMedia(
                profile: item.profile,
                aspectRatio: PlatformMetrics.featuredCardAspectRatio
            )
            .overlay { BuddyPersonBrowseCoverBadges(item: item, density: .hero) }
        }
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint(
            item.profile.photoRefs.count > 1
                ? BuddyBrowseCopy.ShelfA11y.coverSwipeHint
                : ActivityCardStatus.openHint
        )
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var footer: some View {
        let info = BuddyPersonBrowseInfo(
            profile: item.profile,
            metaLine: metaLine,
            density: .hero,
            intentHit: intentHit
        )
        let action = BuddyPersonBrowseAction(
            item: item,
            contactActionTitle: contactActionTitle,
            controlSize: .large,
            onAction: onAction
        )
        if prefersStackedAction {
            VStack(alignment: .leading, spacing: PlatformMetrics.cardFooterSpacing) {
                info
                action
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
                info
                action
            }
        }
    }
}

struct BuddyFeaturedSpotlightSection: View {
    let item: DiscoverBuddyItem
    var intentQuery: String = ""
    var contactActionTitle: String
    var zoomNamespace: Namespace.ID
    var onAction: () -> Void
    var onContact: (() -> Void)? = nil
    var onBook: (() -> Void)? = nil

    var body: some View {
        BuddyFeaturedCard(
            item: item,
            intentQuery: intentQuery,
            contactActionTitle: contactActionTitle,
            zoomNamespace: zoomNamespace,
            onAction: onAction,
            onContact: onContact,
            onBook: onBook
        )
        .discoverBrowseContentInset()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Editorial rail pick

struct BuddyPickCard: View {
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
                density: .grid,
                titleFont: .headline.weight(.semibold),
                metaFont: .subheadline
            )
            .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
        .accessibilityElement(children: .contain)
        .buddyPersonBrowseContextMenu(contextActions)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: "pick", namespace: zoomNamespace) {
            BuddyPersonBrowseCoverMedia(
                profile: item.profile,
                aspectRatio: PlatformMetrics.personGridCardAspectRatio
            )
            .overlay { BuddyPersonBrowseCoverBadges(item: item, density: .grid) }
        }
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(
            item.profile.photoRefs.count > 1
                ? BuddyBrowseCopy.ShelfA11y.coverSwipeHint
                : ActivityCardStatus.openHint
        )
    }

    private var accessibilitySummary: String {
        var parts = [item.profile.nickname]
        if intentHit { parts.insert("契合搜索", at: 0) }
        if !metaLine.isEmpty { parts.append(metaLine) }
        if item.profile.photoRefs.count > 1 {
            parts.append(BuddyBrowseCopy.ShelfA11y.coverMediaCount(item.profile.photoRefs.count))
        }
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }
}

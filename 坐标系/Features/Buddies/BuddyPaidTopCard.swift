//
//  BuddyPaidTopCard.swift
//  坐标系
//
//  陪玩发现：榜 Top 卡。grid 密度；名次角标在封面；无卡内 CTA。
//

import SwiftUI
import CoordinateModels

struct BuddyPaidTopCard: View {
    let rank: Int
    let companion: PaidCompanion
    let badge: BuddyPaidHotBadge
    var zoomNamespace: Namespace.ID
    var contextActions: BuddyPersonBrowseContextActions? = nil

    private var item: DiscoverBuddyItem { .paid(companion) }

    private var metaLine: String {
        let availability = companion.isAvailable
            ? BuddyDetailCopy.available
            : BuddyDetailCopy.unavailable
        return "\(companion.priceText) · \(availability) · \(BuddyBrowseCopy.ShelfA11y.ordersCount(companion.orderCount))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            coverLink
            BuddyPersonBrowseInfo(
                profile: companion.profile,
                metaLine: metaLine,
                density: .grid
            )
            .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
        .accessibilityElement(children: .contain)
        .buddyPersonBrowseContextMenu(contextActions)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: "top", namespace: zoomNamespace) {
            BuddyPersonBrowseCoverMedia(
                profile: companion.profile,
                aspectRatio: PlatformMetrics.personGridCardAspectRatio
            )
            .overlay(alignment: .topLeading) {
                HStack(spacing: PlatformMetrics.hairlineSpacing) {
                    PlatformRankMark(rank: rank, foregroundTint: .white)
                        .font(.caption2.weight(.bold))
                    Text(badge.rawValue)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                .background(badge.tint.opacity(0.88), in: Capsule())
                .padding(PlatformMetrics.captionBadgeInset)
                .allowsHitTesting(false)
            }
        }
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(
            companion.profile.photoRefs.count > 1
                ? BuddyBrowseCopy.ShelfA11y.coverSwipeHint
                : ActivityCardStatus.openHint
        )
    }

    private var accessibilitySummary: String {
        var parts = [
            BuddyBrowseCopy.ShelfA11y.topRankLabel(
                rank: rank,
                nickname: companion.profile.nickname,
                price: companion.priceText
            )
        ]
        if companion.profile.photoRefs.count > 1 {
            parts.append(BuddyBrowseCopy.ShelfA11y.coverMediaCount(companion.profile.photoRefs.count))
        }
        return parts.joined(separator: "，")
    }
}

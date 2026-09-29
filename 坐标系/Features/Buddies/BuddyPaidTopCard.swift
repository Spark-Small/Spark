//
//  BuddyPaidTopCard.swift
//  坐标系
//
//  陪玩发现：榜 Top 卡。
//

import SwiftUI
import CoordinateModels

struct BuddyPaidTopCard: View {
    let rank: Int
    let companion: PaidCompanion
    let badge: BuddyPaidHotBadge
    var zoomNamespace: Namespace.ID
    var onBook: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var item: DiscoverBuddyItem { .paid(companion) }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                    footerChrome(onMedia: false)
                        .padding(.horizontal, PlatformMetrics.captionBadgeInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    footerChrome(onMedia: true)
                        .padding(PlatformMetrics.captionBadgeInset)
                }
            }
        }
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: "top", namespace: zoomNamespace) {
            Color.clear
                .aspectRatio(PlatformMetrics.personGridCardAspectRatio, contentMode: .fit)
                .overlay { CommunityRemotePhoto(ref: companion.profile.coverPhoto) }
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
                .overlay(alignment: .bottom) {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.75), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: PlatformMetrics.contentInset * 5)
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
        }
        .accessibilityLabel("第\(rank)名，\(companion.profile.nickname)，\(companion.priceText)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            topCardMeta(onMedia: onMedia)
            topCardAction(onMedia: onMedia)
        }
    }

    private func topCardMeta(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            Text(companion.profile.nickname)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text("\(companion.orderCount) 单 · \(companion.priceText)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func topCardAction(onMedia: Bool) -> some View {
        Button(companion.isAvailable ? BuddyBrowseCopy.bookAction : BuddyBrowseCopy.bookUnavailable, action: onBook)
            .activityPrimaryCTA(controlSize: .large)
            .disabled(!companion.isAvailable)
            .colorScheme(onMedia ? .dark : .light)
            .layoutPriority(1)
    }
}

/// 排行榜行：系统字阶 + subtitleCell 图文/主副间距；右侧小 CTA

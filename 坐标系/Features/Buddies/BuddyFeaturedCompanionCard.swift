//
//  BuddyFeaturedCompanionCard.swift
//  坐标系
//
//  陪玩发现：精选卡与横滑轨。
//

import SwiftUI
import CoordinateModels

// MARK: - Featured companion card

/// 陪玩页精选大卡：全宽人像 + 底栏信息与 CTA（同列不重叠）
struct BuddyFeaturedCompanionCard: View {
    let companion: PaidCompanion
    var slot: String = "hero"
    var usesRailLayout = false
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
                        .padding(.horizontal, PlatformMetrics.contentInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    footerChrome(onMedia: true)
                        .padding(PlatformMetrics.contentInset)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .padding(.horizontal, usesRailLayout ? 0 : PlatformMetrics.contentInset)
    }

    private var coverLink: some View {
        BuddyZoomNavigationLink(item: item, slot: slot, namespace: zoomNamespace) {
            Color.clear
                .aspectRatio(PlatformMetrics.editorialCardAspectRatio, contentMode: .fit)
                .overlay {
                    CommunityRemotePhoto(ref: companion.profile.coverPhoto)
                }
                .overlay {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.72), .black.opacity(0.18), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }
                }
                .clipped()
        }
        .accessibilityLabel("\(companion.profile.nickname)，\(companion.priceText)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            footerInfo(onMedia: onMedia)
            footerAction(onMedia: onMedia)
        }
    }

    private func footerInfo(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                Text(companion.profile.nickname)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if companion.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("平台认证")
                }
            }
            HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                Label(companion.priceText, systemImage: "tag")
                Label("\(companion.orderCount) 单", systemImage: "checkmark.rectangle")
                if companion.isAvailable {
                    Label(BuddyDetailCopy.available, systemImage: "calendar")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func footerAction(onMedia: Bool) -> some View {
        Button(companion.isAvailable ? BuddyBrowseCopy.bookAction : BuddyBrowseCopy.bookUnavailable, action: onBook)
            .activityPrimaryCTA(controlSize: .large)
            .disabled(!companion.isAvailable)
            .colorScheme(onMedia ? .dark : .light)
            .layoutPriority(1)
    }
}

/// 精选大卡横滑轨：左滑切换，邻卡露出提示可继续浏览
struct BuddyFeaturedCompanionRail: View {
    let companions: [PaidCompanion]
    var zoomNamespace: Namespace.ID
    var onBook: (PaidCompanion) -> Void

    var body: some View {
        Group {
            if companions.count <= 1, let companion = companions.first {
                BuddyFeaturedCompanionCard(
                    companion: companion,
                    slot: "hero-0",
                    zoomNamespace: zoomNamespace,
                    onBook: { onBook(companion) }
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(Array(companions.enumerated()), id: \.element.id) { index, companion in
                        BuddyFeaturedCompanionCard(
                            companion: companion,
                            slot: "hero-\(index)",
                            usesRailLayout: true,
                            zoomNamespace: zoomNamespace,
                            onBook: { onBook(companion) }
                        )
                        .platformEditorialRailFrame()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("精选陪玩")
    }
}


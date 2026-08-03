//
//  BuddyGridCard.swift
//  坐标系
//
//  同好 / 陪玩双列卡：照片上叠距离与共同兴趣；底部一句状态（微信附近的人语义）。
//

import SwiftUI

/// 双列发现人物卡：点封面进详情；陪玩保留底栏邀约 CTA
struct BuddyGridCard: View {
    let item: DiscoverBuddyItem
    var zoomNamespace: Namespace.ID
    var onAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var profile: BuddyProfile { item.profile }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    private var isPaid: Bool {
        if case .paid = item { return true }
        return false
    }

    var body: some View {
        Group {
            if prefersStacked {
                stackedBody
            } else {
                overlayBody
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Overlay

    private var overlayBody: some View {
        ZStack(alignment: .bottom) {
            BuddyZoomNavigationLink(item: item, namespace: zoomNamespace) {
                coverFill
                    .overlay(alignment: .topLeading) { overlayTagRow }
                    .overlay(alignment: .topTrailing) { trailingBadge }
            }
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint(ActivityCardStatus.openHint)

            footer(onMedia: true)
                .padding(PlatformMetrics.captionBadgeInset)
        }
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
    }

    // MARK: - Stacked

    private var stackedBody: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            BuddyZoomNavigationLink(item: item, namespace: zoomNamespace) {
                coverFill
                    .overlay(alignment: .topLeading) { overlayTagRow }
                    .overlay(alignment: .topTrailing) { trailingBadge }
                    .clipShape(PlatformMetrics.cardShape)
            }
            .accessibilityLabel(accessibilitySummary)
            .accessibilityHint(ActivityCardStatus.openHint)

            footer(onMedia: false)
        }
    }

    private var coverFill: some View {
        Color.clear
            .aspectRatio(PlatformMetrics.personGridCardAspectRatio, contentMode: .fit)
            .overlay {
                CommunityRemotePhoto(ref: profile.coverPhoto)
            }
            .clipped()
    }

    /// 叠在照片上：距离 + 共同兴趣（无共同则取个人爱好）
    private var overlayTagRow: some View {
        FlowTagRow(tags: overlayTags)
            .padding(PlatformMetrics.captionBadgeInset)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var overlayTags: [String] {
        var tags: [String] = []
        if PrivacyPreferences.showDistance {
            tags.append(profile.distanceText)
        }
        let shared = BuddyMatchScorer.sharedHobbies(with: profile)
        if !shared.isEmpty {
            tags.append(contentsOf: shared.prefix(2))
        } else {
            tags.append(contentsOf: profile.tags.prefix(2))
        }
        return Array(tags.prefix(3))
    }

    @ViewBuilder
    private func footer(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.minContentGap) {
                    Text(profile.nickname)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(profile.gender.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(profile.gender.tint)
                        .accessibilityHidden(true)
                }

                Text(item.cardMoodLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(onMedia ? .primary : .secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))

                if isPaid {
                    Text(paidMetaLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .colorScheme(onMedia ? .dark : .light)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            if isPaid {
                Button(item.inviteEnabled ? "邀约" : "暂不可约", action: onAction)
                    .font(.subheadline.weight(.semibold))
                    .activityPrimaryCTA(controlSize: .regular)
                    .disabled(!item.inviteEnabled)
                    .accessibilityLabel("\(item.inviteEnabled ? "邀约" : "暂不可约")，\(profile.nickname)")
            }
        }
    }

    @ViewBuilder
    private var trailingBadge: some View {
        let flags = TrustPublicCredentials.flags(
            nickname: profile.nickname,
            currentUserName: "",
            buddyItem: item,
            membershipActive: false
        )
        Group {
            if case .paid(let companion) = item, companion.isAvailable {
                PlatformMediaCaptionBadge(title: "可约", tint: PlatformStatus.success)
            } else if flags.photoVerified {
                PlatformMediaCaptionBadge(title: "形象认证", tint: .accentColor)
            } else if item.isOnline, PrivacyPreferences.showOnline {
                PlatformMediaCaptionBadge(title: "在线", tint: PlatformStatus.success)
            }
        }
    }

    private var paidMetaLine: String {
        guard case .paid(let companion) = item else { return "" }
        return PrivacyPreferences.buddyCardMeta(
            distanceText: profile.distanceText,
            statusLine: companion.isAvailable ? companion.priceText : "暂不可约",
            extra: [item.cardHobbyLine].filter { !$0.isEmpty }
        )
    }

    private var accessibilitySummary: String {
        let tags = overlayTags.joined(separator: "，")
        return "\(profile.nickname)，\(item.cardMoodLine)，\(tags)"
    }
}

/// 照片角上的小标签行（距离 / 兴趣）
private struct FlowTagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags, id: \.self) { tag in
                PlatformCaptionBadge(title: tag, chrome: .material)
            }
        }
        .colorScheme(.dark)
    }
}

/// 同好 / 陪玩双列发现网格
struct BuddyPersonGrid: View {
    let items: [DiscoverBuddyItem]
    var zoomNamespace: Namespace.ID
    var onChat: (DiscoverBuddyItem) -> Void
    var onInvite: (DiscoverBuddyItem) -> Void

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: PlatformMetrics.discoverCardSpacing) {
            ForEach(items) { item in
                BuddyGridCard(
                    item: item,
                    zoomNamespace: zoomNamespace,
                    onAction: {
                        switch item {
                        case .free: onChat(item)
                        case .paid: onInvite(item)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
}

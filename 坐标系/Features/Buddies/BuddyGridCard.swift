//
//  BuddyGridCard.swift
//  坐标系
//
//  同好 / 陪玩双列卡：封面叠字；卡内 CTA（同好「聊天」/ 陪玩「邀约」）。
//

import SwiftUI

/// 双列发现网格人物卡：点封面进详情；底栏 CTA 在卡内、不进 NavigationLink
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

    private var actionTitle: String {
        switch item {
        case .free: "聊天"
        case .paid: item.inviteEnabled ? "邀约" : "暂不可约"
        }
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
                    .overlay(alignment: .topLeading) { leadingBadge }
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
                    .overlay(alignment: .topLeading) { leadingBadge }
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

                Text(primaryMeta)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(onMedia ? .primary : .secondary)
                    .lineLimit(1)

                Text(secondaryMeta)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .colorScheme(onMedia ? .dark : .light)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button(actionTitle, action: onAction)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .regular)
                .disabled(isPaid && !item.inviteEnabled)
                .accessibilityLabel("\(actionTitle)，\(profile.nickname)")
        }
    }

    @ViewBuilder
    private var leadingBadge: some View {
        if case .paid(let companion) = item, companion.isVerified {
            PlatformMediaCaptionBadge(title: "认证", tint: .accentColor)
        } else if item.isOnline {
            PlatformMediaCaptionBadge(title: "在线", tint: PlatformStatus.success)
        }
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if case .paid(let companion) = item, companion.isAvailable {
            PlatformMediaCaptionBadge(title: "可约", tint: PlatformStatus.success)
        }
    }

    private var primaryMeta: String {
        switch item {
        case .paid(let companion):
            return companion.isAvailable ? companion.priceText : "暂不可约"
        case .free:
            return item.cardHobbyLine
        }
    }

    private var secondaryMeta: String {
        switch item {
        case .paid:
            return [item.cardHobbyLine, profile.distanceText, item.cardStatusLine]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        case .free:
            return [profile.distanceText, "\(profile.age)岁", item.cardStatusLine]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    private var accessibilitySummary: String {
        switch item {
        case .paid(let companion):
            return "\(profile.nickname)，\(companion.priceText)，\(item.cardHobbyLine)"
        case .free:
            return "\(profile.nickname)，\(item.cardHobbyLine)"
        }
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

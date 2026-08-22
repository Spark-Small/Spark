//
//  BuddyGridCard.swift
//  坐标系
//
//  免费找人双列照片卡：封面叠字 + 卡内 CTA（大字阶落到图下）。
//

import SwiftUI

/// 双列发现人物卡：点封面进详情；底栏左信息 / 右聊天或选档期
struct BuddyGridCard: View {
    let item: DiscoverBuddyItem
    var intentQuery: String = ""
    var contactActionTitle = "聊天"
    var zoomNamespace: Namespace.ID
    var onAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var profile: BuddyProfile { item.profile }

    private var isPaid: Bool {
        if case .paid = item { return true }
        return false
    }

    private var intentHit: Bool {
        BuddyMatchScorer.matchesIntent(profile, query: intentQuery)
    }

    private var reasonLine: String {
        BuddyMatchScorer.browseReason(
            for: profile,
            isOnline: item.isOnline,
            intentQuery: intentQuery
        )
    }

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
        BuddyZoomNavigationLink(item: item, slot: "grid", namespace: zoomNamespace) {
            coverFill
                .overlay(alignment: .topLeading) { overlayTagRow }
                .overlay(alignment: .topTrailing) { trailingBadge }
                .overlay(alignment: .bottom) {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.72), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: PlatformMetrics.contentInset * 4.5)
                        .allowsHitTesting(false)
                    }
                }
        }
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            footerInfo(onMedia: onMedia)
            actionButton(onMedia: onMedia)
        }
    }

    private func footerInfo(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.hairlineSpacing) {
                Text(profile.nickname)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(profile.gender.symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(onMedia ? .white.opacity(0.9) : profile.gender.tint)
                    .accessibilityHidden(true)
                if intentHit {
                    PlatformCaptionBadge(
                        title: "契合",
                        chrome: onMedia ? .material : .tint(.accentColor)
                    )
                }
            }

            Text(item.cardMoodLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))

            if !reasonLine.isEmpty {
                Text(reasonLine)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func actionButton(onMedia: Bool) -> some View {
        if isPaid {
            Button(item.inviteEnabled ? "选档期" : "暂不可约", action: onAction)
                .font(.caption.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .disabled(!item.inviteEnabled)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
        } else {
            Button(contactActionTitle, action: onAction)
                .font(.caption.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
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

    private var overlayTagRow: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            ForEach(overlayTags, id: \.self) { tag in
                PlatformCaptionBadge(title: tag, chrome: .material)
            }
        }
        .padding(PlatformMetrics.captionBadgeInset)
        .colorScheme(.dark)
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
            tags.append(contentsOf: shared.prefix(1))
        }
        return Array(tags.prefix(2))
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if case .paid(let companion) = item, companion.isAvailable {
            PlatformMediaCaptionBadge(title: "可约", tint: PlatformStatus.success)
        } else if item.isOnline, PrivacyPreferences.showOnline {
            PlatformMediaCaptionBadge(title: "在线", tint: PlatformStatus.success)
        }
    }

    private var accessibilitySummary: String {
        var parts = [profile.nickname, item.cardMoodLine]
        if intentHit { parts.insert("契合搜索", at: 0) }
        parts.append(contentsOf: overlayTags)
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }
}

/// 同好双列发现网格
struct BuddyPersonGrid: View {
    let items: [DiscoverBuddyItem]
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: ((DiscoverBuddyItem) -> Void)? = nil

    @Environment(AppModel.self) private var app

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
                    intentQuery: intentQuery,
                    contactActionTitle: app.peerContactActionTitle(
                        for: item.profile.nickname,
                        context: .forBuddyItem(item)
                    ),
                    zoomNamespace: zoomNamespace,
                    onAction: {
                        switch item {
                        case .free: onChat(item)
                        case .paid: onBook?(item)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
}

// MARK: - 精选轨（Bumble For You 语义：少而精，非全宽 Hero）

enum BuddyDiscoveryPicks {
    static let limit = 4

    static func split(_ items: [DiscoverBuddyItem]) -> (picks: [DiscoverBuddyItem], rest: [DiscoverBuddyItem]) {
        guard items.count > limit else { return ([], items) }
        return (Array(items.prefix(limit)), Array(items.dropFirst(limit)))
    }
}

/// 精选大卡：4:5 editorial 横滑；封面叠字 + 卡内 CTA。
struct BuddyPickCard: View {
    let item: DiscoverBuddyItem
    var intentQuery: String = ""
    var contactActionTitle = "聊天"
    var zoomNamespace: Namespace.ID
    var onAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var profile: BuddyProfile { item.profile }

    private var reasonLine: String {
        BuddyMatchScorer.browseReason(
            for: profile,
            isOnline: item.isOnline,
            intentQuery: intentQuery
        )
    }

    private var isPaid: Bool {
        if case .paid = item { return true }
        return false
    }

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
        BuddyZoomNavigationLink(item: item, slot: "pick", namespace: zoomNamespace) {
            Color.clear
                .aspectRatio(PlatformMetrics.editorialCardAspectRatio, contentMode: .fit)
                .overlay {
                    CommunityRemotePhoto(ref: profile.coverPhoto)
                }
                .overlay(alignment: .topLeading) {
                    PlatformMediaCaptionBadge(title: isPaid ? "优先" : "精选", tint: .accentColor)
                }
                .overlay(alignment: .topTrailing) {
                    if case .paid(let companion) = item, companion.isAvailable {
                        PlatformMediaCaptionBadge(title: "可约", tint: PlatformStatus.success)
                    } else if item.isOnline, PrivacyPreferences.showOnline {
                        PlatformMediaCaptionBadge(title: "在线", tint: PlatformStatus.success)
                    }
                }
                .overlay(alignment: .bottom) {
                    if !prefersStacked {
                        LinearGradient(
                            colors: [.black.opacity(0.72), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: PlatformMetrics.contentInset * 4.5)
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
        }
        .accessibilityLabel("\(profile.nickname)，\(item.cardMoodLine)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private func footerChrome(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            pickInfo(onMedia: onMedia)
            pickAction(onMedia: onMedia)
        }
    }

    private func pickInfo(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            Text(profile.nickname)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(item.cardMoodLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !reasonLine.isEmpty {
                Text(reasonLine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pickAction(onMedia: Bool) -> some View {
        if isPaid {
            Button(item.inviteEnabled ? "选档期" : "暂不可约", action: onAction)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .disabled(!item.inviteEnabled)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
        } else {
            Button(contactActionTitle, action: onAction)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
        }
    }

    @ViewBuilder
    private func actionButton(onMedia: Bool) -> some View {
        if isPaid {
            Button(item.inviteEnabled ? "选档期" : "暂不可约", action: onAction)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .disabled(!item.inviteEnabled)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
        } else {
            Button(contactActionTitle, action: onAction)
                .font(.subheadline.weight(.semibold))
                .activityPrimaryCTA(controlSize: .small)
                .colorScheme(onMedia ? .dark : .light)
                .layoutPriority(1)
        }
    }
}

struct BuddyPickRail: View {
    let items: [DiscoverBuddyItem]
    var title: String
    var subtitle: String
    var intentQuery: String = ""
    var zoomNamespace: Namespace.ID
    var onChat: (DiscoverBuddyItem) -> Void
    var onBook: ((DiscoverBuddyItem) -> Void)? = nil

    @Environment(AppModel.self) private var app

    var body: some View {
        DiscoverBrowseSection(title: title, subtitle: subtitle) {
            DiscoverHorizontalRail {
                ForEach(items) { item in
                    BuddyPickCard(
                        item: item,
                        intentQuery: intentQuery,
                        contactActionTitle: app.peerContactActionTitle(
                            for: item.profile.nickname,
                            context: .forBuddyItem(item)
                        ),
                        zoomNamespace: zoomNamespace,
                        onAction: {
                            switch item {
                            case .free: onChat(item)
                            case .paid: onBook?(item)
                            }
                        }
                    )
                    .platformEditorialRailFrame()
                }
            }
        }
    }
}

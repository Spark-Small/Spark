//
//  ActivityCards.swift
//  坐标系
//
//  活动卡片：精选 Hero + 发现流大卡。
//

import SwiftUI
import CoordinateModels

/// 精选 Hero：3:4 卡片；水平页边与发现货架一致（`PlatformMetrics.contentInset`）。
struct ActivityFeaturedCard: View {
    @Environment(ActivitiesModel.self) private var activities
    @Environment(LocationService.self) private var location
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let activity: Activity
    /// 传入后封面走唯一 zoom 入口 `ActivityZoomNavigationLink`
    var zoomNamespace: Namespace.ID?
    var onJoin: (() -> Void)?

    private var live: Activity { activities.activity(id: activity.id) ?? activity }
    private var isJoined: Bool { activities.isJoined(activity.id) }
    private var isWaitlisted: Bool { activities.isWaitlisted(activity.id) }
    private var hasUserLocation: Bool { location.coordinate != nil }

    private var statusCaption: String? {
        if isJoined { return ActivityCardStatus.joined }
        return ActivityCardStatus.captionBadge(for: live)
    }

    /// VoiceOver：封面一次说完；文案层隐藏，避免与 NavigationLink 重复朗读
    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            status: statusCaption,
            title: live.title,
            parts: Formatters.activityEventTime(from: live.date),
            metaLine
        )
    }

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(spacing: PlatformMetrics.stackedMediaSpacing) {
                    cover
                        .aspectRatio(PlatformMetrics.featuredCardAspectRatio, contentMode: .fit)
                        .clipped()
                    heroFooter(onMedia: false)
                        .padding(.horizontal, PlatformMetrics.contentInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    cover
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()

                    heroFooter(onMedia: true)
                        .padding(.horizontal, PlatformMetrics.contentInset)
                        .padding(.bottom, PlatformMetrics.contentInset)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var cover: some View {
        let media = CommunityRemotePhoto(ref: live.coverPhoto)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

        if let zoomNamespace {
            ActivityZoomNavigationLink(
                activityID: live.id,
                namespace: zoomNamespace
            ) {
                media
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(openAccessibilityLabel)
            .accessibilityHint(ActivityCardStatus.openHint)
            .accessibilityAddTraits(.isImage)
        } else {
            media
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func heroFooter(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            copy(onMedia: onMedia)
            joinCTA(onMedia: onMedia)
        }
    }

    private func copy(onMedia: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(live.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
            Text(Formatters.activityEventTime(from: live.date))
                .font(.body)
                .foregroundStyle(.secondary)
            Text(metaLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func joinCTA(onMedia: Bool) -> some View {
        ActivityPrimaryAction(
            isJoined: isJoined,
            isWaitlisted: isWaitlisted,
            isFull: live.isFull,
            controlSize: .large,
            onMedia: onMedia,
            onJoin: onJoin
        )
        .layoutPriority(1)
    }

    private var metaLine: String {
        let fee = live.isFull ? ActivityCardStatus.full : (live.isFree ? ActivityCardStatus.free : live.fee)
        if let friend = ActivityRecommender.matchedFriends(for: live).first {
            return "\(live.location) · \(ActivityCardStatus.friendAlsoGoing(friend)) · \(fee)"
        }
        guard hasUserLocation else {
            return "\(live.location) · \(live.hostName) · \(fee)"
        }
        return "\(live.location) · \(live.distanceLabel(hasUserLocation: true)) · \(fee)"
    }
}

/// 发现流大卡 — 16:9；封面 Zoom
struct ActivityDiscoverCard: View {
    @Environment(ActivitiesModel.self) private var activities
    let activity: Activity
    var isJoined: Bool = false
    var zoomNamespace: Namespace.ID? = nil
    var enablesOpenTap = true
    var onOpen: () -> Void = {}
    var onJoin: (() -> Void)?

    private var hasUserLocation: Bool { location.coordinate != nil }

    @Environment(LocationService.self) private var location

    var body: some View {
        ActivityHeroCard(
            activity: activity,
            isJoined: isJoined,
            isWaitlisted: activities.isWaitlisted(activity.id),
            layout: .discover,
            zoomNamespace: zoomNamespace,
            enablesOpenTap: enablesOpenTap,
            onOpen: onOpen,
            onJoin: onJoin
        ) {
            HeroMediaMetaLine(
                text: Formatters.activityEventTime(from: activity.date),
                font: HeroMediaCardLayout.discover.timeFont
            )
            HeroMediaMetaLine(
                text: "\(activity.location) · \(activity.distanceLabel(hasUserLocation: hasUserLocation)) · \(ActivityCardStatus.spotsText(for: activity))",
                font: HeroMediaCardLayout.discover.metaFont,
                opacity: 0.88
            )
        }
    }
}

struct ActivityParticipantAvatars: View {
    let names: [String]
    var maxVisible: Int = 5

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var size: CGFloat {
        dynamicTypeSize.listAvatarSide
    }

    var body: some View {
        HStack(spacing: -size * 0.28) {
            ForEach(Array(names.prefix(maxVisible).enumerated()), id: \.offset) { _, name in
                PlatformListAvatarView(name: name)
                    .overlay {
                        Circle().strokeBorder(
                            PlatformSurface.canvas,
                            lineWidth: PlatformMetrics.avatarBadgeStroke
                        )
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("参与者 \(min(names.count, maxVisible)) 人")
    }
}

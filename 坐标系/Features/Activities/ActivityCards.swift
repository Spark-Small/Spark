//
//  ActivityCards.swift
//  坐标系
//
//  活动卡片：精选 Hero + 发现流大卡。
//

import SwiftUI
import CoordinateModels

/// 精选 Hero：4:5 卡片；水平页边与发现货架一致（`PlatformMetrics.contentInset`）。
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
            parts: secondaryLine
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
                        .clipShape(PlatformMetrics.cardShape)
                        .contentShape(PlatformMetrics.cardShape)
                    heroFooter
                        // 卡内近缘 inset；页边由 Spotlight 的 discoverBrowseContentInset 负责，避免双重对齐线。
                        .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
                }
            } else {
                ZStack(alignment: .bottom) {
                    cover
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()

                    heroFooter
                        .platformMediaInfoBarChrome(.hero)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .clipShape(PlatformMetrics.cardShape)
                .contentShape(PlatformMetrics.cardShape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var cover: some View {
        let photo = CommunityRemotePhoto(ref: live.coverPhoto)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

        if let zoomNamespace {
            ActivityZoomNavigationLink(
                activityID: live.id,
                namespace: zoomNamespace
            ) {
                photo
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(openAccessibilityLabel)
            .accessibilityHint(ActivityCardStatus.openHint)
            .accessibilityAddTraits(.isImage)
        } else {
            photo
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var heroFooter: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
            copy
            joinCTA
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(live.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
            Text(secondaryLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var joinCTA: some View {
        ActivityPrimaryAction(
            isJoined: isJoined,
            isWaitlisted: isWaitlisted,
            isFull: live.isFull,
            controlSize: .large,
            onJoin: onJoin
        )
        .layoutPriority(1)
    }

    /// Material 栏第二行：时间 · 地点/距离 · 费用（App Store Today 双行信息）
    private var secondaryLine: String {
        let time = Formatters.activityEventTime(from: live.date)
        let fee = live.isFull ? ActivityCardStatus.full : (live.isFree ? ActivityCardStatus.free : live.fee)
        if let friend = ActivityRecommender.matchedFriends(for: live).first {
            return "\(time) · \(ActivityCardStatus.friendAlsoGoing(friend)) · \(fee)"
        }
        guard hasUserLocation else {
            return "\(time) · \(live.location) · \(fee)"
        }
        return "\(time) · \(live.distanceLabel(hasUserLocation: true)) · \(fee)"
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
                text: "\(Formatters.activityEventTime(from: activity.date)) · \(activity.location) · \(ActivityCardStatus.spotsText(for: activity))",
                font: HeroMediaCardLayout.discover.metaFont,
                opacity: 0.88,
                lineLimit: 1
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
        HStack(spacing: PlatformMetrics.avatarStackSpacing(avatarSide: size)) {
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

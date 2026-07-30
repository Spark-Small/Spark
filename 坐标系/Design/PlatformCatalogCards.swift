//
//  PlatformCatalogCards.swift
//  坐标系
//
//  活动目录卡（官方 SwiftUI）：
//  跟进横卡 / 热场横卡 / 榜单海报 / 焦点大卡
//  打开详情：NavigationLink + matchedTransitionSource（与精选一致）
//

import SwiftUI

// MARK: - Shared chrome

private enum PlatformCatalogCardChrome {
    static var shape: RoundedRectangle { PlatformMetrics.posterShape }
    /// 与 `PlatformMetrics.captionBadgeInset` 对齐
    static var inset: CGFloat { PlatformMetrics.captionBadgeInset }
    /// 卡内信息行距
    static var infoSpacing: CGFloat { PlatformMetrics.cardInfoSpacing }
}

/// 定框封面（无底栏；底栏由卡片自己叠）
private struct PlatformCatalogCoverFill: View {
    var photo: CommunityPhotoRef?
    var aspectRatio: CGFloat

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                CommunityRemotePhoto(ref: photo)
            }
            .clipped()
    }
}

/// 精选 Hero 同款底栏：左信息 / 右「参加」glass
private struct PlatformCatalogHeroFooter: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let timeLine: String
    let metaLine: String
    var isJoined = false
    var isFull = false
    /// true：叠在封面上（深色字阶）；false：图下文（页面语义色）
    var onMedia = true
    var onJoin: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                Text(timeLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
                if !metaLine.isEmpty {
                    Text(metaLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(DiscoverAccessibility.bodyLineLimit(for: dynamicTypeSize, regular: 2))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .colorScheme(onMedia ? .dark : .light)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ActivityPrimaryAction(
                isJoined: isJoined,
                isFull: isFull,
                controlSize: .regular,
                onMedia: onMedia,
                onJoin: onJoin
            )
        }
    }
}

// MARK: - 活动紧凑横卡（16:9）

/// 活动页与个人内容库共用的小卡：16:9 封面内叠放标题与时间。
/// 外层负责 NavigationLink / Zoom 和轨道宽度，本组件只管理卡内视觉。
struct PlatformActivityCompactCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var photo: CommunityPhotoRef?
    var badge: String? = nil
    var title: String
    var metaLine: String

    var body: some View {
        Group {
            if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize) {
                stackedBody
            } else {
                overlayBody
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ActivityCardStatus.openAccessibilityLabel(
                status: badge,
                title: title,
                parts: metaLine
            )
        )
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private var stackedBody: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            cover
            copy(onMedia: false)
        }
    }

    private var overlayBody: some View {
        ZStack {
            cover

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let badge, !badge.isEmpty {
                PlatformMediaCaptionBadge(title: badge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(PlatformMetrics.captionBadgeInset)
            }

            copy(onMedia: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(PlatformMetrics.captionBadgeInset)
        }
        .clipShape(PlatformMetrics.mediaShape)
        .contentShape(PlatformMetrics.mediaShape)
        .colorScheme(.dark)
    }

    private var cover: some View {
        PlatformCatalogCoverFill(
            photo: photo,
            aspectRatio: PlatformMetrics.activityCardAspectRatio
        )
        .overlay(alignment: .topLeading) {
            if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize),
               let badge,
               !badge.isEmpty {
                PlatformMediaCaptionBadge(title: badge)
                    .padding(PlatformMetrics.captionBadgeInset)
            }
        }
        .clipShape(PlatformMetrics.mediaShape)
    }

    private func copy(onMedia: Bool) -> some View {
        VStack(
            alignment: .leading,
            spacing: PlatformConversationListRow.textToSecondarySpacing
        ) {
            titleView(onMedia: onMedia)

            Text(metaLine)
                .font(.caption)
                .foregroundStyle(onMedia ? .white.opacity(0.82) : .secondary)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
    }

    @ViewBuilder
    private func titleView(onMedia: Bool) -> some View {
        let text = Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(onMedia ? .white : .primary)
            .multilineTextAlignment(.leading)

        if dynamicTypeSize.isAccessibilitySize {
            text.fixedSize(horizontal: false, vertical: true)
        } else {
            text.lineLimit(2)
        }
    }
}

// MARK: - 跟进横卡（16:9）

/// 左下信息 + 右下参加；封面 zoom 打开
struct PlatformContinueCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var title: String
    var timeLine: String
    var metaLine: String
    var isJoined = false
    var isFull = false
    var onJoin: (() -> Void)?

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                        .clipShape(PlatformCatalogCardChrome.shape)
                    PlatformCatalogHeroFooter(
                        title: title,
                        timeLine: timeLine,
                        metaLine: metaLine,
                        isJoined: isJoined,
                        isFull: isFull,
                        onMedia: false,
                        onJoin: onJoin
                    )
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    PlatformCatalogHeroFooter(
                        title: title,
                        timeLine: timeLine,
                        metaLine: metaLine,
                        isJoined: isJoined,
                        isFull: isFull,
                        onMedia: true,
                        onJoin: onJoin
                    )
                    .padding(PlatformCatalogCardChrome.inset)
                }
                .clipShape(PlatformCatalogCardChrome.shape)
                .contentShape(PlatformCatalogCardChrome.shape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        ActivityZoomNavigationLink(
            activityID: activityID,
            namespace: zoomNamespace,
            clip: .rail
        ) {
            PlatformCatalogCoverFill(
                photo: photo,
                aspectRatio: PlatformMetrics.continueCardAspectRatio
            )
        }
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            title: title,
            parts: timeLine, metaLine
        )
    }
}

// MARK: - 赛事 / 专题横卡（16:9）

/// 左下信息 + 右下参加；左上角标；封面 zoom 打开
struct PlatformEventCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var badge: String?
    var title: String
    var timeLine: String
    var metaLine: String
    var isJoined = false
    var isFull = false
    var onJoin: (() -> Void)?

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                        .overlay(alignment: .topLeading) { badgeView(onMedia: true) }
                        .clipShape(PlatformCatalogCardChrome.shape)
                    PlatformCatalogHeroFooter(
                        title: title,
                        timeLine: timeLine,
                        metaLine: metaLine,
                        isJoined: isJoined,
                        isFull: isFull,
                        onMedia: false,
                        onJoin: onJoin
                    )
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    badgeView(onMedia: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    PlatformCatalogHeroFooter(
                        title: title,
                        timeLine: timeLine,
                        metaLine: metaLine,
                        isJoined: isJoined,
                        isFull: isFull,
                        onMedia: true,
                        onJoin: onJoin
                    )
                    .padding(PlatformCatalogCardChrome.inset)
                }
                .clipShape(PlatformCatalogCardChrome.shape)
                .contentShape(PlatformCatalogCardChrome.shape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        ActivityZoomNavigationLink(
            activityID: activityID,
            namespace: zoomNamespace,
            clip: .rail
        ) {
            PlatformCatalogCoverFill(
                photo: photo,
                aspectRatio: PlatformMetrics.continueCardAspectRatio
            )
        }
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    @ViewBuilder
    private func badgeView(onMedia: Bool) -> some View {
        if let badge, !badge.isEmpty {
            PlatformMediaCaptionBadge(title: badge, onMedia: onMedia)
        }
    }

    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            status: badge,
            title: title,
            parts: timeLine, metaLine
        )
    }
}

// MARK: - 榜单竖海报（3:4）

/// 排名角标 + 海报 + 底标题/类型；整卡 zoom（手机密度；比例 / 轨宽见 `PlatformMetrics`）
struct PlatformPosterRankCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var rank: Int
    var title: String
    var genre: String

    var body: some View {
        ActivityZoomNavigationLink(
            activityID: activityID,
            namespace: zoomNamespace,
            clip: .poster
        ) {
            ZStack(alignment: .bottom) {
                PlatformCatalogCoverFill(
                    photo: photo,
                    aspectRatio: PlatformMetrics.posterCardAspectRatio
                )

                VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                    Text(genre)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
                }
                .frame(maxWidth: .infinity)
                .padding(PlatformCatalogCardChrome.inset)
                .colorScheme(.dark)
                .accessibilityHidden(true)
            }
            .overlay(alignment: .topLeading) {
                Text("\(rank)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                    .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.leading, PlatformMetrics.rankBadgeLeading)
                    .padding(.top, PlatformMetrics.rankBadgeTop)
                    .colorScheme(.dark)
                    .accessibilityHidden(true)
            }
            .clipShape(PlatformCatalogCardChrome.shape)
        }
        .accessibilityLabel("第 \(rank) 名，\(title)，\(genre)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }
}


// MARK: - 活动焦点大卡

/// 横滑宽卡：左上角标 + 底左大标题/meta；右下「参加」
struct PlatformEditorialCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var badge: String?
    var title: String
    /// 一行 meta，如「美食活动 · 火锅 · 今晚」
    var metaLine: String
    var metaSymbol: String = "sparkles"
    var isJoined = false
    var isFull = false
    var onJoin: (() -> Void)?

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                        .overlay(alignment: .topLeading) { badgeView(onMedia: true) }
                        .clipShape(PlatformMetrics.editorialShape)
                    infoRow(onMedia: false)
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    badgeView(onMedia: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    infoRow(onMedia: true)
                        .padding(PlatformCatalogCardChrome.inset)
                }
                .clipShape(PlatformMetrics.editorialShape)
                .contentShape(PlatformMetrics.editorialShape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        ActivityZoomNavigationLink(
            activityID: activityID,
            namespace: zoomNamespace,
            clip: .editorial
        ) {
            PlatformCatalogCoverFill(
                photo: photo,
                aspectRatio: PlatformMetrics.editorialCardAspectRatio
            )
        }
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    @ViewBuilder
    private func badgeView(onMedia: Bool) -> some View {
        if let badge, !badge.isEmpty {
            PlatformMediaCaptionBadge(title: badge, onMedia: onMedia)
        }
    }

    private func infoRow(onMedia: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PlatformMetrics.cardFooterSpacing) {
            VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                    .minimumScaleFactor(0.85)

                HStack(spacing: PlatformMetrics.metaSymbolSpacing) {
                    Image(systemName: metaSymbol)
                        .font(.caption2.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                    Text(metaLine)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .colorScheme(onMedia ? .dark : .light)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ActivityPrimaryAction(
                isJoined: isJoined,
                isFull: isFull,
                controlSize: .regular,
                onMedia: onMedia,
                onJoin: onJoin
            )
        }
    }

    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            status: badge,
            title: title,
            parts: metaLine
        )
    }
}

// MARK: - Rail helpers

extension View {
    /// 跟进 / 热场横卡轨：接近一整张，露邻卡
    func platformContinueRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.continueRailVisibleFraction
        }
    }

    /// 焦点大卡轨：露邻卡
    func platformEditorialRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.editorialRailVisibleFraction
        }
    }

    /// 榜单海报轨：露出邻卡
    func platformPosterRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.posterRailVisibleFraction
        }
    }

    /// 我的活动横卡轨：系统相对容器一屏两张完整卡。
    func platformProfileActivityHistoryRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.profileActivityHistoryRailColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 个人内容库竖海报轨：约三张完整卡，并露出第四张。
    func platformProfileLibraryRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.profileLibraryRailVisibleFraction
        }
    }

    /// 「我的发布」媒体库行缩略图：与一屏两张的活动卡等宽。
    func platformProfileMediaLibraryThumbnailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            let contentWidth = length - PlatformMetrics.contentInset * 2
            return (contentWidth - PlatformMetrics.railCardSpacing) / 2
        }
    }
}

#Preview("Editorial rail") {
    @Previewable @Namespace var ns
    let activity = SampleData.activities[1]
    ScrollView {
        DiscoverBrowseSection(
            title: "本周主打",
            subtitle: "左右滑看看",
            showsChevron: true,
            onSeeAll: {}
        ) {
            DiscoverHorizontalRail {
                PlatformEditorialCard(
                    activityID: activity.id,
                    zoomNamespace: ns,
                    photo: activity.coverPhoto,
                    badge: "新",
                    title: activity.title,
                    metaLine: "\(activity.category.title) · 骑行 · 今晚",
                    metaSymbol: activity.category.systemImage,
                    onJoin: {}
                )
                .platformEditorialRailFrame()

                PlatformEditorialCard(
                    activityID: SampleData.activities[0].id,
                    zoomNamespace: ns,
                    photo: SampleData.activities[0].coverPhoto,
                    badge: "快满",
                    title: SampleData.activities[0].title,
                    metaLine: "运动户外 · 羽毛球",
                    metaSymbol: "figure.badminton",
                    isJoined: true
                )
                .platformEditorialRailFrame()
            }
        }
        .padding(.vertical, PlatformMetrics.sectionSpacing)
    }
    .background(PlatformSurface.groupedPage)
    .activityZoomNavigationDestination(namespace: ns)
}

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
    static var shape: RoundedRectangle { PlatformMetrics.cardShape }
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
            namespace: zoomNamespace
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

/// 左下信息 + 右下参加；左上角标；封面 zoom 或 `onCoverTap` 打开详情
struct PlatformEventCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID? = nil
    var photo: CommunityPhotoRef?
    var badge: String?
    var title: String
    var timeLine: String
    var metaLine: String
    var isJoined = false
    var isFull = false
    var onCoverTap: (() -> Void)? = nil
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

    @ViewBuilder
    private var coverLink: some View {
        let cover = PlatformCatalogCoverFill(
            photo: photo,
            aspectRatio: PlatformMetrics.continueCardAspectRatio
        )

        if let zoomNamespace {
            ActivityZoomNavigationLink(
                activityID: activityID,
                namespace: zoomNamespace
            ) {
                cover
            }
            .accessibilityLabel(openAccessibilityLabel)
            .accessibilityHint(ActivityCardStatus.openHint)
        } else if let onCoverTap {
            Button(action: onCoverTap) {
                cover
            }
            .buttonStyle(.plain)
            .accessibilityLabel(openAccessibilityLabel)
            .accessibilityHint(ActivityCardStatus.openHint)
        } else {
            cover
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func badgeView(onMedia: Bool) -> some View {
        if let badge, !badge.isEmpty {
            PlatformMediaCaptionBadge(title: badge, onMedia: onMedia)
                .allowsHitTesting(false)
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

/// 排名符号 + 海报 + 底标题/类型；封面 zoom（手机密度；比例 / 轨宽见 `PlatformMetrics`）
struct PlatformPosterRankCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var rank: Int
    var title: String
    var genre: String

    var body: some View {
        ZStack(alignment: .bottom) {
            coverLink
            footerOverlay
        }
        .overlay(alignment: .topLeading) {
            PlatformRankMark(rank: rank)
                .font(.title2)
                .padding(.leading, PlatformMetrics.rankBadgeLeading)
                .padding(.top, PlatformMetrics.rankBadgeTop)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .aspectRatio(PlatformMetrics.posterCardAspectRatio, contentMode: .fit)
        .clipShape(PlatformCatalogCardChrome.shape)
        .contentShape(PlatformCatalogCardChrome.shape)
        .colorScheme(.dark)
        .accessibilityElement(children: .contain)
    }

    private var footerOverlay: some View {
        VStack(spacing: PlatformMetrics.cardInfoSpacing) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
            Text(genre)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
        .frame(maxWidth: .infinity)
        .padding(PlatformCatalogCardChrome.inset)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var coverLink: some View {
        ActivityZoomNavigationLink(
            activityID: activityID,
            namespace: zoomNamespace
        ) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { CommunityRemotePhoto(ref: photo) }
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.black.opacity(0.75), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: PlatformMetrics.contentInset * 4)
                    .allowsHitTesting(false)
                }
                .clipped()
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
            namespace: zoomNamespace
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
                .allowsHitTesting(false)
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
    /// 跟进 / 热场横卡轨：页边内一屏 1 卡全宽（`PlatformContinueCard` / `PlatformEventCard`）
    func platformContinueRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.discoverRailFullWidthColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 焦点大卡轨：页边内一屏 1 卡全宽（`PlatformEditorialCard`）
    func platformEditorialRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.discoverRailFullWidthColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 榜单海报轨：页边内一屏 2 卡（`PlatformPosterRankCard`）
    func platformPosterRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.posterRailColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 「我的」Wallet 票面轨：与竖海报同宽占比，高度由票面 3:4 比例推导。
    func platformProfileWalletPassRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.profileLibraryRailVisibleFraction
        }
    }

    /// 个人内容库竖海报轨（圈子等）：约三张完整卡，并露出第四张。
    func platformProfileLibraryRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.profileLibraryRailVisibleFraction
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

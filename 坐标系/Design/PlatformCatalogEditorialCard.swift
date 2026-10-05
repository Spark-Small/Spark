//
//  PlatformCatalogEditorialCard.swift
//  坐标系
//
//  活动焦点大卡 + Material 底栏。
//

import SwiftUI
import CoordinateModels

/// 横滑宽卡：左上角标 + 底左标题/meta；右下「参加」。
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
    var isWaitlisted = false
    var isFull = false
    var isLifecycleEnded = false
    var onJoin: (() -> Void)?

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    var body: some View {
        Group {
            if prefersStacked {
                VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
                    coverLink
                        .overlay(alignment: .topLeading) { badgeView }
                        .clipShape(PlatformMetrics.editorialShape)
                    infoRow
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    badgeView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    infoRow
                        .platformMediaInfoBarChrome(.hero)
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
    private var badgeView: some View {
        if let badge, !badge.isEmpty {
            PlatformMediaCaptionBadge(title: badge)
                .allowsHitTesting(false)
        }
    }

    private var infoRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
            VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)

                HStack(spacing: PlatformMetrics.metaSymbolSpacing) {
                    Image(systemName: metaSymbol)
                        .font(.caption2.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                    Text(metaLine)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ActivityPrimaryAction(
                isJoined: isJoined,
                isWaitlisted: isWaitlisted,
                isFull: isFull,
                isLifecycleEnded: isLifecycleEnded,
                controlSize: .regular,
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

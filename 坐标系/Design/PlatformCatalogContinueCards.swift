//
//  PlatformCatalogContinueCards.swift
//  坐标系
//
//  跟进横卡 / 赛事专题横卡（16:9）+ Material 底栏。
//

import SwiftUI
import CoordinateModels

/// 左下信息 + 右下参加；封面 zoom 打开。
struct PlatformContinueCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var activityID: Activity.ID
    var zoomNamespace: Namespace.ID
    var photo: CommunityPhotoRef?
    var title: String
    var timeLine: String
    var metaLine: String
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
                        .clipShape(PlatformCatalogCardChrome.shape)
                    footer
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    footer
                        .platformMediaInfoBarChrome(.standard)
                }
                .clipShape(PlatformCatalogCardChrome.shape)
                .contentShape(PlatformCatalogCardChrome.shape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var footer: some View {
        PlatformCatalogHeroFooter(
            title: title,
            timeLine: timeLine,
            metaLine: metaLine,
            isJoined: isJoined,
            isWaitlisted: isWaitlisted,
            isFull: isFull,
            isLifecycleEnded: isLifecycleEnded,
            onJoin: onJoin
        )
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

/// 左下信息 + 右下参加；左上角标；封面 zoom 或 `onCoverTap`。
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
    var isWaitlisted = false
    var isFull = false
    var isLifecycleEnded = false
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
                        .overlay(alignment: .topLeading) { badgeView }
                        .clipShape(PlatformCatalogCardChrome.shape)
                    footer
                }
            } else {
                ZStack(alignment: .bottom) {
                    coverLink
                    badgeView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    footer
                        .platformMediaInfoBarChrome(.standard)
                }
                .clipShape(PlatformCatalogCardChrome.shape)
                .contentShape(PlatformCatalogCardChrome.shape)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var footer: some View {
        PlatformCatalogHeroFooter(
            title: title,
            timeLine: timeLine,
            metaLine: metaLine,
            isJoined: isJoined,
            isWaitlisted: isWaitlisted,
            isFull: isFull,
            isLifecycleEnded: isLifecycleEnded,
            onJoin: onJoin
        )
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
    private var badgeView: some View {
        if let badge, !badge.isEmpty {
            PlatformMediaCaptionBadge(title: badge)
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

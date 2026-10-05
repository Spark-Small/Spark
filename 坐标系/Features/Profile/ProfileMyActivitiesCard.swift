//
//  ProfileMyActivitiesCard.swift
//  坐标系
//
//  「我的活动」场次卡：与发现跟进横卡同构（封面比 / Material / token）；
//  无参加 CTA；间距只走 PlatformMetrics / PlatformCatalogCardChrome。
//

import SwiftUI
import CoordinateModels

struct ProfileMyActivitiesCard: View {
    let activity: Activity
    var zoomNamespace: Namespace.ID
    var intent: ActivityZoomIntent
    var badge: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var prefersStacked: Bool {
        DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize)
    }

    private var timeLine: String {
        Formatters.activityEventTime(from: activity.date)
    }

    private var metaLine: String {
        activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if prefersStacked {
                stackedChrome
            } else {
                overlayChrome
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Accessibility 大字：图下文案；水平 inset = `heroStackedTextInset`（与 Featured 同）。
    private var stackedChrome: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            coverLink
                .overlay(alignment: .topLeading) { badgeView }
                .clipShape(PlatformCatalogCardChrome.shape)
            infoBlock
                .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
    }

    /// 常规字阶：封面 + `.standard` Material 底栏（inset 由 `platformMediaInfoBarChrome` 提供）。
    private var overlayChrome: some View {
        ZStack(alignment: .bottom) {
            coverLink
            badgeView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            infoBlock
                .platformMediaInfoBarChrome(.standard)
        }
        .clipShape(PlatformCatalogCardChrome.shape)
        .contentShape(PlatformCatalogCardChrome.shape)
    }

    private var coverLink: some View {
        ActivityZoomNavigationLink(
            activity: activity,
            namespace: zoomNamespace,
            intent: intent
        ) {
            PlatformCatalogCoverFill(
                photo: activity.coverPhoto,
                aspectRatio: PlatformMetrics.continueCardAspectRatio
            )
        }
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint(ActivityCardStatus.openHint)
    }

    /// 主副文距 = `cardInfoSpacing`；字阶与跟进横卡一致（无手写 lineSpacing）。
    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
            Text(activity.title)
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
    private var badgeView: some View {
        if let badge, !badge.isEmpty {
            // 与 PlatformEventCard / Hero 同：`PlatformMediaCaptionBadge` 已含 captionBadgeInset，勿再叠 mediaChromeInset。
            PlatformMediaCaptionBadge(title: badge)
                .allowsHitTesting(false)
        }
    }

    private var secondaryLine: String {
        if metaLine.isEmpty { return timeLine }
        return "\(timeLine) · \(metaLine)"
    }

    private var openAccessibilityLabel: String {
        ActivityCardStatus.openAccessibilityLabel(
            status: badge,
            title: activity.title,
            parts: timeLine, metaLine
        )
    }
}

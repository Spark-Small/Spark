//
//  ActivityNextUpBanner.swift
//  坐标系
//
//  活动 Tab 顶部品牌紫胶囊：下一场 Continue / 无行程发现引导。
//

import SwiftUI
import CoordinateModels

struct ActivityNextUpBanner: View {
    let summary: ActivityNextUpPresentation.Summary
    var onOpenJourney: () -> Void
    var onNavigate: () -> Void

    var body: some View {
        DiscoverPromoCapsuleBanner(
            content: DiscoverPromoCapsuleContent(
                title: summary.promoContent.title,
                subtitle: summary.promoContent.subtitle
            ),
            action: performPrimary
        )
        .activityBrowsePromoBannerChrome()
        .accessibilityLabel(summary.promoAccessibilitySummary)
        .accessibilityHint(summary.trailingActionTitle)
    }

    private func performPrimary() {
        switch summary.primaryAction {
        case .openJourney: onOpenJourney()
        case .navigate: onNavigate()
        }
    }
}

struct ActivityDiscoverPromoBanner: View {
    var onDiscover: () -> Void

    var body: some View {
        DiscoverPromoCapsuleBanner(
            content: DiscoverPromoCapsuleContent(
                title: ActivityNextUpPresentation.DiscoverPromo.title,
                subtitle: ActivityNextUpPresentation.DiscoverPromo.subtitle
            ),
            action: onDiscover
        )
        .activityBrowsePromoBannerChrome()
        .accessibilityHint(ActivityNextUpPresentation.DiscoverPromo.accessibilityHint)
    }
}

private extension View {
    func activityBrowsePromoBannerChrome() -> some View {
        discoverBrowseContentInset()
            .padding(.bottom, PlatformMetrics.sectionHeaderSpacing)
    }
}

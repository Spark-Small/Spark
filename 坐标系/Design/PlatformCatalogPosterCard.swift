//
//  PlatformCatalogPosterCard.swift
//  坐标系
//
//  榜单竖海报（3:4）+ Material 底栏。
//

import SwiftUI
import CoordinateModels

/// 排名符号 + 海报 + 底标题/类型；封面 zoom。
struct PlatformPosterRankCard: View {
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
        .accessibilityElement(children: .contain)
    }

    private var footerOverlay: some View {
        VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
            Text(genre)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformMediaInfoBarChrome(.compact)
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
                .clipped()
        }
        .accessibilityLabel("第 \(rank) 名，\(title)，\(genre)")
        .accessibilityHint(ActivityCardStatus.openHint)
    }
}

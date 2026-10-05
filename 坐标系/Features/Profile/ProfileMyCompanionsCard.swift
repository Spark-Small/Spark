//
//  ProfileMyCompanionsCard.swift
//  坐标系
//
//  「我的陪玩」预约卡：对齐搭子双列人像小卡（`BuddyGridCard`）—
//  封面比 `personGridCardAspectRatio`、图下昵称+meta；点进预约凭证展开页。
//

import SwiftUI
import CoordinateModels

struct ProfileMyCompanionsCard: View {
    let record: BuddyBookingRecord
    var photo: CommunityPhotoRef?
    var badge: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var timeLine: String {
        Formatters.activityEventTime(from: record.scheduledAt)
    }

    private var metaLine: String {
        var parts: [String] = [timeLine, "\(record.hours) 小时"]
        let price = record.priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !price.isEmpty {
            parts.append(price)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.stackedMediaSpacing) {
            coverLink
            infoBlock
                .padding(.horizontal, PlatformMetrics.heroStackedTextInset)
        }
        .accessibilityElement(children: .contain)
    }

    private var coverLink: some View {
        NavigationLink {
            BookingCredentialExpandedView(recordID: record.id)
        } label: {
            PlatformCatalogCoverFill(
                photo: photo,
                aspectRatio: PlatformMetrics.personGridCardAspectRatio
            )
            .overlay(alignment: .topLeading) { badgeView }
            .clipShape(PlatformMetrics.cardShape)
            .contentShape(PlatformMetrics.cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(openAccessibilityLabel)
        .accessibilityHint("打开预约凭证")
    }

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(record.companionNickname)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
            Text(metaLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
            title: record.companionNickname,
            parts: metaLine
        )
    }
}

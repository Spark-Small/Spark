//
//  BuddyPaidLeaderboardRow.swift
//  坐标系
//
//  陪玩发现：榜行。
//

import SwiftUI
import CoordinateModels

struct BuddyPaidLeaderboardRow: View {
    let rank: Int
    let companion: PaidCompanion
    var zoomNamespace: Namespace.ID
    var onBook: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var item: DiscoverBuddyItem { .paid(companion) }

    /// 榜行头像用「好友动态封面」档，约列表头像 × 1.6
    private var avatarSide: CGFloat { dynamicTypeSize.friendPostCoverSide }

    private var displayRating: Double {
        BuddyPaidMarketCatalog.displayRating(for: companion)
    }

    private var reviewCount: Int {
        BuddyPaidMarketCatalog.reviewCount(for: companion)
    }

    private var displayTags: [String] {
        BuddyPaidMarketCatalog.leaderboardTags(for: companion)
    }

    private var displayHighlights: [String] {
        BuddyPaidMarketCatalog.leaderboardHighlights(for: companion)
    }

    private var displayHotBadge: BuddyPaidHotBadge? {
        BuddyPaidMarketCatalog.leaderboardHotBadge(for: companion, rank: rank)
    }

    private var leaderboardAccessibilityLabel: String {
        var parts = [
            "第\(rank)名",
            companion.profile.nickname,
            "评分 \(String(format: "%.1f", displayRating))",
            "\(companion.orderCount) 单",
        ]
        if let displayHotBadge {
            parts.append(displayHotBadge.rawValue)
        }
        if !displayTags.isEmpty {
            parts.append("兴趣 \(displayTags.joined(separator: "、"))")
        }
        if !displayHighlights.isEmpty {
            parts.append("亮点 \(displayHighlights.joined(separator: "、"))")
        }
        parts.append(companion.priceText)
        return parts.joined(separator: "，")
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
            BuddyZoomNavigationLink(item: item, slot: "board", namespace: zoomNamespace) {
                HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                    portrait

                    VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                        HStack(spacing: PlatformMetrics.minContentGap) {
                            Text(companion.profile.nickname)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if companion.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityLabel("平台认证")
                            }
                        }

                        HStack(spacing: PlatformMetrics.minContentGap) {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(String(format: "%.1f", displayRating))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                            }
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(reviewCount) 评")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(companion.orderCount) 单")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .lineLimit(1)

                        if !displayTags.isEmpty || displayHotBadge != nil || !displayHighlights.isEmpty {
                            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                                if let displayHotBadge {
                                    PlatformCaptionBadge(
                                        title: displayHotBadge.rawValue,
                                        chrome: .tint(displayHotBadge.tint)
                                    )
                                }
                                ForEach(displayTags, id: \.self) { tag in
                                    PlatformCaptionBadge(title: tag, chrome: .material)
                                }
                                ForEach(displayHighlights, id: \.self) { highlight in
                                    PlatformCaptionBadge(title: highlight, chrome: .material)
                                }
                            }
                            .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 价 ↔ 钮：与 ActivityFeaturedCard 图下「文案 + CTA」同用 cardFooterSpacing
            VStack(alignment: .trailing, spacing: PlatformMetrics.cardFooterSpacing) {
                Text(companion.priceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PlatformStatus.warning)
                    .lineLimit(1)
                    .monospacedDigit()
                Button(companion.isAvailable ? BuddyBrowseCopy.bookAction : BuddyBrowseCopy.bookUnavailable, action: onBook)
                    .activityPrimaryCTA(controlSize: .regular)
                    .disabled(!companion.isAvailable)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, PlatformMetrics.cardInfoSpacing)
        .padding(.vertical, PlatformConversationListRow.verticalInset)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            leaderboardAccessibilityLabel
        )
    }

    private var portrait: some View {
        PlatformListAvatarView(
            name: companion.profile.nickname,
            photoRef: companion.profile.coverPhoto,
            side: avatarSide
        )
        .overlay(alignment: .bottomTrailing) {
            PlatformRankMark(rank: rank)
                .font(.caption2)
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
    }
}


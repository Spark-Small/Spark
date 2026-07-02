// Module: SparkBuddy — Companion listing row (Messages ConversationRow parity).

import SparkDesignSystem
import SwiftUI

public struct BuddyListRow: View {
    public let listing: BuddyListing
    public let showsChevron: Bool

    public init(listing: BuddyListing, showsChevron: Bool = false) {
        self.listing = listing
        self.showsChevron = showsChevron
    }

    private var priceLine: String {
        if let firstPackage = listing.packages.first {
            return BuddyFormatting.packagePriceLine(
                amount: firstPackage.priceAmount,
                currencyCode: firstPackage.priceCurrencyCode
            )
        }
        return BuddyFormatting.priceLine(
            amount: listing.priceAmount,
            currencyCode: listing.priceCurrencyCode,
            billingKind: listing.billingKind
        )
    }

    private var metadataLine: String {
        var parts: [String] = [listing.serviceCategory.localizedTitle]
        if !listing.city.isEmpty {
            parts.append(listing.city)
        }
        return parts.joined(separator: " · ")
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            avatar
            VStack(alignment: .leading, spacing: 6) {
                titleRow
                Text(listing.headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(metadataLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                tagsRow
                matchRow
            }
            Spacer(minLength: 8)
            trailingColumn
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
        .frame(
            minHeight: SparkLayoutMetrics.inboxConversationRowMinHeight,
            alignment: .center
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = listing.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    avatarPlaceholder
                }
            )
            .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
            .clipShape(Circle())
            .overlay { verifiedBadge }
        } else {
            avatarPlaceholder
                .overlay { verifiedBadge }
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color(.tertiarySystemFill))
            Image(systemName: listing.serviceCategory.systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .frame(width: SparkLayoutMetrics.tabPersonAvatarSize, height: SparkLayoutMetrics.tabPersonAvatarSize)
    }

    @ViewBuilder
    private var verifiedBadge: some View {
        if listing.isVerified || listing.trust?.isFullyVerified == true {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption2)
                .foregroundStyle(Color.accentColor)
                .offset(x: 16, y: 16)
                .accessibilityHidden(true)
        }
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(listing.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(listing.billingKind.localizedTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
    }

    @ViewBuilder
    private var tagsRow: some View {
        if !listing.tags.isEmpty {
            Text(listing.tags.prefix(3).joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var matchRow: some View {
        if let insight = listing.matchInsight {
            Text(BuddyFormatting.matchLine(insight))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
        }
    }

    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(priceLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            if let ratingLine = BuddyFormatting.listRatingLine(
                rating: listing.rating,
                completedOrderCount: listing.completedOrderCount,
                reviewCount: listing.reviewCount
            ) {
                Text(ratingLine)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var accessibilityLabelText: String {
        var parts = [listing.displayName, listing.headline, priceLine, metadataLine]
        if let ratingLine = BuddyFormatting.listRatingLine(
            rating: listing.rating,
            completedOrderCount: listing.completedOrderCount,
            reviewCount: listing.reviewCount
        ) {
            parts.append(ratingLine)
        }
        if let insight = listing.matchInsight {
            parts.append(BuddyFormatting.matchLine(insight))
        }
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

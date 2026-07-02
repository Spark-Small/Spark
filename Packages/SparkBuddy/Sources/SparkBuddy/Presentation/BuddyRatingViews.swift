// Module: SparkBuddy — Visual rating / review components.

import SparkDesignSystem
import SwiftUI

struct BuddyStarRatingView: View {
    let rating: Double
    var starSize: Font = .caption

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 5, id: \.self) { index in
                Image(systemName: symbolName(for: index))
                    .font(starSize)
                    .foregroundStyle(symbolName(for: index).contains("fill") ? Color.yellow : Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(BuddyFormatting.starRatingAccessibilityLabel(rating: rating))
    }

    private func symbolName(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold {
            return "star.fill"
        }
        if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}

struct BuddyRatingSummaryHeader: View {
    let rating: Double
    let reviewCount: Int
    let recommendScore: Double?

    var body: some View {
        HStack(alignment: .center, spacing: SparkLayoutMetrics.standardHorizontalPadding) {
            VStack(spacing: 4) {
                Text(BuddyFormatting.ratingScoreText(rating))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                BuddyStarRatingView(rating: rating, starSize: .subheadline)
                Text(BuddyFormatting.reviewCountText(reviewCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 88)

            if let recommendScore {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        String(
                            localized: "buddy.review.recommend",
                            defaultValue: "推荐指数",
                            comment: "Recommend score label"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(BuddyFormatting.ratingScoreText(recommendScore))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                    BuddyStarRatingView(rating: recommendScore, starSize: .caption)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct BuddyReviewDimensionBars: View {
    let rows: [(title: String, score: Double)]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.title) { row in
                HStack(spacing: 10) {
                    Text(row.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                            Capsule()
                                .fill(Color.yellow.opacity(0.85))
                                .frame(width: max(0, proxy.size.width * row.score / 5))
                        }
                    }
                    .frame(height: 6)
                    Text(BuddyFormatting.ratingScoreText(row.score))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    String(
                        format: String(
                            localized: "buddy.review.dimension.a11y.format",
                            defaultValue: "%@ %@ 分",
                            comment: "Review dimension a11y; dimension name and score"
                        ),
                        locale: .current,
                        row.title,
                        BuddyFormatting.ratingScoreText(row.score)
                    )
                )
            }
        }
    }
}

struct BuddyReviewHighlightList: View {
    let reviews: [BuddyReview]

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            Text(
                String(
                    localized: "buddy.detail.reviews.highlights",
                    defaultValue: "用户评价",
                    comment: "Highlighted user reviews"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(review.authorDisplayName)
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8)
                        BuddyStarRatingView(rating: review.rating, starSize: .caption2)
                    }
                    Text(review.comment)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let createdAt = review.createdAt {
                        Text(BuddyFormatting.reviewDateText(createdAt))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(SparkLayoutMetrics.compactVerticalPadding + 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle.sparkCard)
            }
        }
    }
}

#Preview("Buddy rating views") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            BuddyRatingSummaryHeader(rating: 4.8, reviewCount: 54, recommendScore: 4.9)
            BuddyReviewDimensionBars(
                rows: BuddyReviewSnapshot(
                    punctuality: 4.9,
                    communication: 4.8,
                    expertise: 4.9,
                    safety: 5,
                    fun: 4.7,
                    recommend: 4.9
                ).dimensionRows
            )
            BuddyReviewHighlightList(
                reviews: [
                    BuddyReview(
                        id: "1",
                        authorDisplayName: "小林",
                        rating: 5,
                        comment: "路线规划很贴心，拍照也很会找角度，整体体验超出预期。",
                        createdAt: .now
                    )
                ]
            )
        }
        .padding()
    }
}

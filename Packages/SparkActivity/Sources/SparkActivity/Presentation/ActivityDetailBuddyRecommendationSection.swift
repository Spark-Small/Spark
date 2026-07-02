// Module: SparkActivity — Buddy cross-tab recommendation card on activity detail.

import SparkDesignSystem
import SwiftUI

struct ActivityBuddyRecommendation: Equatable, Sendable {
    let listingID: String
    let title: String
    let subtitle: String
}

struct ActivityDetailBuddyRecommendationSection: View {
    let activityCategory: String
    let fetchRecommendation: (String) async -> ActivityBuddyRecommendation?
    let onOpenListing: (String) -> Void

    @State private var recommendation: ActivityBuddyRecommendation?

    var body: some View {
        Group {
            if let recommendation {
                recommendationCard(recommendation)
            }
        }
        .task(id: activityCategory) {
            if let fetched = await fetchRecommendation(activityCategory) {
                recommendation = fetched
            } else {
                recommendation = nil
            }
        }
    }

    @ViewBuilder
    private func recommendationCard(_ recommendation: ActivityBuddyRecommendation) -> some View {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                Text(
                    String(
                        localized: "activity.detail.buddy.section",
                        defaultValue: "配套陪玩",
                        comment: "Buddy recommendation section"
                    )
                )
                .font(.headline)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)

                Button {
                    onOpenListing(recommendation.listingID)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.2.wave.2.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(recommendation.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(SparkLayoutMetrics.compactVerticalPadding)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(
                            cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                .accessibilityLabel(
                    String(
                        localized: "activity.detail.buddy.card.a11y",
                        defaultValue: "查看配套陪玩 \(recommendation.title)",
                        comment: "Buddy recommendation card"
                    )
                )
            }
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }
}

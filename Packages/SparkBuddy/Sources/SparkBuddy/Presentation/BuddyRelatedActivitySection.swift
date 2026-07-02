// Module: SparkBuddy — Related activity cross-tab recommendation on buddy detail.

import SparkDesignSystem
import SwiftUI

struct BuddyRelatedActivitySection: View {
    let fetchRecommendedActivity: () async -> (id: String, title: String)?
    let onOpenActivity: (String) -> Void

    @State private var activityID: String?
    @State private var activityTitle: String?

    var body: some View {
        Group {
            if let activityID, let activityTitle {
                relatedActivityCard(activityID: activityID, activityTitle: activityTitle)
            }
        }
        .task {
            guard let recommendation = await fetchRecommendedActivity() else { return }
            activityID = recommendation.id
            activityTitle = recommendation.title
        }
    }

    @ViewBuilder
    private func relatedActivityCard(activityID: String, activityTitle: String) -> some View {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                Text(
                    String(
                        localized: "buddy.detail.activity.section",
                        defaultValue: "相关活动",
                        comment: "Related activity section"
                    )
                )
                .font(.headline)

                Button {
                    onOpenActivity(activityID)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activityTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(
                                String(
                                    localized: "buddy.detail.activity.subtitle",
                                    defaultValue: "看看同城正在组局的活动",
                                    comment: "Related activity subtitle"
                                )
                            )
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
                .accessibilityLabel(
                    String(
                        localized: "buddy.detail.activity.card.a11y",
                        defaultValue: "查看相关活动 \(activityTitle)",
                        comment: "Related activity card"
                    )
                )
            }
            .sparkInboxModuleSurface()
    }
}

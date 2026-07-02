// Module: SparkCommunity — Linked activity summary card for recap posts.

import SparkDesignSystem
import SwiftUI

struct CommunityPostLinkedActivitySummaryCard: View {
    let activity: LinkedActivityContext
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
            HStack(alignment: .top, spacing: 12) {
                coverThumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let scheduleLine = activity.scheduleLine, !scheduleLine.isEmpty {
                        Text(scheduleLine)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let attendeeSummary = activity.attendeeSummary, !attendeeSummary.isEmpty {
                        Text(attendeeSummary)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            Button(action: onOpen) {
                Text(
                    String(
                        localized: "community.linkedActivity.open.cta",
                        defaultValue: "查看活动",
                        comment: "Primary CTA to open linked activity"
                    )
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .background(.regularMaterial, in: RoundedRectangle.sparkCard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel)
        .accessibilityHint(
            String(
                localized: "community.detail.activityBanner.action",
                defaultValue: "查看活动详情",
                comment: "Open activity"
            )
        )
    }

    @ViewBuilder
    private var coverThumbnail: some View {
        if let coverURL = activity.coverURL {
            SparkCachedRemoteImage(
                url: coverURL,
                maxPixelSize: 240,
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                },
                placeholder: {
                    coverPlaceholder
                }
            )
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            coverPlaceholder
                .frame(width: 72, height: 72)
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.quaternary)
            .overlay {
                Image(systemName: "calendar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
    }

    private var summaryAccessibilityLabel: String {
        var parts = [activity.name]
        if let scheduleLine = activity.scheduleLine {
            parts.append(scheduleLine)
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Linked activity summary card") {
        CommunityPostLinkedActivitySummaryCard(
            activity: LinkedActivityContext(
                id: "act_browse_2",
                name: String(
                    localized: "community.mock.activity.book",
                    defaultValue: "咖啡聊天局",
                    comment: "Activity"
                ),
                scheduleLine: String(
                    localized: "community.mock.activity.schedule",
                    defaultValue: "周六 9:30",
                    comment: "Schedule"
                ),
                coverURL: URL(string: "https://picsum.photos/seed/feed-recap/112/112"),
                attendeeSummary: String(
                    localized: "community.mock.activity.attendees",
                    defaultValue: "12 人参加",
                    comment: "Attendee summary"
                )
            ),
            onOpen: {}
        )
        .padding()
    }
}

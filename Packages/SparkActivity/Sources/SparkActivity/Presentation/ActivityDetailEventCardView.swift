// Module: SparkActivity — Compact horizontal event card (Meetup-style recommendations).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailEventCardView: View {
    let item: ActivityItem

    private let cardWidth: CGFloat = 260

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SparkCachedRemoteImage(
                url: ActivityCoverImage.url(activityID: item.id),
                maxPixelSize: 240,
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                },
                placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                }
            )
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let startsAt = item.startsAt {
                    Text(ActivityFormatting.listCardScheduleLine(startsAt: startsAt, endsAt: item.endsAt))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(
                    ActivityFormatting.attendeeLine(
                        attendeeCount: item.attendeeCount,
                        capacity: item.capacity
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: cardWidth, alignment: .leading)
        .padding(SparkLayoutMetrics.compactVerticalPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        let attendeeLine = ActivityFormatting.attendeeLine(
            attendeeCount: item.attendeeCount,
            capacity: item.capacity
        )
        return [item.title, item.scheduleLine, attendeeLine]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            if let item = MockActivityCatalog.detail(id: "act_hike_2")?.asListItem() {
                ActivityDetailEventCardView(item: item)
            }
        }
        .padding()
    }
}

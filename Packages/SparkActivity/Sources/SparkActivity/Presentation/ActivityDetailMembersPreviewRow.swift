// Module: SparkActivity — Meetup-style horizontal member avatar preview.

import SparkDesignSystem
import SwiftUI

struct ActivityDetailMembersPreviewRow: View {
    let attendees: [ActivityAttendee]
    let totalCount: Int
    let maxVisible: Int

    init(attendees: [ActivityAttendee], totalCount: Int, maxVisible: Int = 10) {
        self.attendees = attendees
        self.totalCount = totalCount
        self.maxVisible = maxVisible
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                ForEach(previewAttendees) { attendee in
                    VStack(spacing: 4) {
                        Text(String(attendee.displayName.prefix(1)))
                            .font(.caption.weight(.semibold))
                            .frame(width: 40, height: 40)
                            .background(.quaternary, in: Circle())
                        Text(attendee.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(width: 48)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(attendee.displayName)
                }

                if totalCount > previewAttendees.count {
                    VStack(spacing: 4) {
                        Text("+\(totalCount - previewAttendees.count)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 40, height: 40)
                            .background(.quaternary, in: Circle())
                        Text(
                            String(localized: "activity.detail.members.more", defaultValue: "更多", comment: "More members")
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 48)
                    }
                    .accessibilityLabel(
                        String(
                            format: String(
                                localized: "activity.detail.members.more.a11y.format",
                                defaultValue: "还有 %lld 位参加者",
                                comment: "More members a11y; %lld is count"
                            ),
                            locale: .current,
                            totalCount - previewAttendees.count
                        )
                    )
                }
            }
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        }
    }

    private var previewAttendees: [ActivityAttendee] {
        Array(attendees.prefix(maxVisible))
    }
}

#Preview {
    ActivityDetailMembersPreviewRow(
        attendees: [
            ActivityAttendee(id: "1", displayName: "阿乐", isHost: true),
            ActivityAttendee(id: "2", displayName: "小林", isVerified: true),
            ActivityAttendee(id: "3", displayName: "Mia")
        ],
        totalCount: 12
    )
}

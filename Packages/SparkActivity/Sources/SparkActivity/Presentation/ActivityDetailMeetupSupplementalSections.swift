// Module: SparkActivity — Meetup-parity detail sections (meta · related topics).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    // MARK: - Related topics (Meetup: Related topics)

    @ViewBuilder
    func meetupRelatedTopicsSection(activity: ActivityDetail) -> some View {
        let topics = ActivityRelatedTopics.topics(for: activity)
        if !topics.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.detail.relatedTopics.section",
                        defaultValue: "相关主题",
                        comment: "Related topics section"
                    )
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .sparkGlassControl(Capsule())
                        }
                    }
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                }
            }
        }
    }

    // MARK: - Decision feedback (near RSVP / logistics)

    @ViewBuilder
    func meetupDecisionNoticesSection(activity: ActivityDetail) -> some View {
        if activity.rsvpStatus == .waitlisted {
            meetupNoticeBlock(
                String(
                    localized: "activity.waitlist.status",
                    defaultValue: "你已在候补名单，有空位时主办可提升你为参加。",
                    comment: "Waitlist status"
                )
            )
        } else if let blocked = activity.registrationBlockedMessage, activity.rsvpStatus == .invited {
            meetupNoticeBlock(blocked)
        }

        if let error = viewModel.rsvpErrorMessage {
            meetupNoticeBlock(error)
        }
    }

    // MARK: - Secondary feedback (host actions · calendar already inline)

    @ViewBuilder
    func meetupSecondaryNoticesSection() -> some View {
        if let hostMessage = viewModel.hostFeedbackMessage {
            meetupNoticeBlock(hostMessage)
        }
    }
}

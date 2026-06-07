// Module: SparkActivity — Post-event summary and community share entry.

import SparkDesignSystem
import SwiftUI

struct ActivityPastRecapView: View {
    let activity: ActivityDetail
    let feedbackSubmitted: Bool
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    let onSubmitFeedback: (ActivityHostFeedback) async -> Void
    let onHostAgain: (() -> Void)?

    var body: some View {
        List {
            Section {
                Label(activity.title, systemImage: "flag.checkered")
                Label(activity.scheduleLine, systemImage: "clock")
                Label(activity.locationName, systemImage: "mappin.and.ellipse")
                if activity.attendeeCount > 0 {
                    let format = String(
                        localized: "activity.pastRecap.attendees.format",
                        defaultValue: "共 %lld 人参加",
                        comment: "Post-event attendee count"
                    )
                    Text(String(format: format, locale: .current, Int64(activity.attendeeCount)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(
                    String(
                        localized: "activity.pastRecap.summary.section",
                        defaultValue: "活动信息",
                        comment: "Post-event summary"
                    )
                )
            }

            if !activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    NavigationLink {
                        ActivityMeetupMapView(
                            activityTitle: activity.title,
                            locationName: activity.locationName
                        )
                    } label: {
                        Label(
                            String(
                                localized: "activity.pastRecap.map",
                                defaultValue: "查看碰头地点",
                                comment: "Post-event map"
                            ),
                            systemImage: "map"
                        )
                    }
                }
            }

            Section {
                if let onCommunityRecap {
                    Button {
                        onCommunityRecap(activity)
                    } label: {
                        Label(
                            String(
                                localized: "activity.shareToCommunity.cta",
                                defaultValue: "分享到社区",
                                comment: "Share ended activity to community"
                            ),
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                }
                if activity.rsvpStatus != .host, !feedbackSubmitted {
                    Button {
                        Task { await onSubmitFeedback(.positive) }
                    } label: {
                        Label(ActivityHostFeedback.positive.localizedLabel, systemImage: "hand.thumbsup")
                    }
                    Button {
                        Task { await onSubmitFeedback(.negative) }
                    } label: {
                        Label(ActivityHostFeedback.negative.localizedLabel, systemImage: "hand.thumbsdown")
                    }
                } else if feedbackSubmitted {
                    Label(
                        String(
                            localized: "activity.feedback.submitted",
                            defaultValue: "已提交反馈",
                            comment: "Feedback submitted"
                        ),
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.secondary)
                }
                if let onHostAgain {
                    Button(action: onHostAgain) {
                        Label(
                            String(
                                localized: "activity.hostAgain.cta",
                                defaultValue: "再办一场",
                                comment: "Host again"
                            ),
                            systemImage: "arrow.clockwise"
                        )
                    }
                }
            } header: {
                Text(
                    String(
                        localized: "activity.pastRecap.actions.section",
                        defaultValue: "事后",
                        comment: "Post-event actions"
                    )
                )
            } footer: {
                Text(
                    String(
                        localized: "activity.shareToCommunity.footer",
                        defaultValue: "带上现场照片发到社区，帮其他人了解这场局。",
                        comment: "Share to community footer"
                    )
                )
            }
        }
        .sparkScreenListStyle()
        .navigationTitle(
            String(localized: "activity.pastRecap.title", defaultValue: "活动后记", comment: "Post-event title")
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_4") {
        NavigationStack {
            ActivityPastRecapView(
                activity: activity,
                feedbackSubmitted: false,
                onCommunityRecap: { _ in },
                onSubmitFeedback: { _ in },
                onHostAgain: nil
            )
        }
    }
}

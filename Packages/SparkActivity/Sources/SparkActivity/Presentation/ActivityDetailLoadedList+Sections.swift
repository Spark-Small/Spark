// Module: SparkActivity — Activity detail list section builders.

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    func showsInviteFriendsSection(for activity: ActivityDetail) -> Bool {
        viewModel.context == .externalEntry
            && activity.lifecycleStatus == .scheduled
            && activity.rsvpStatus != .host
    }

    @ViewBuilder
    func postEventScrollSection(activity: ActivityDetail) -> some View {
        if activity.showsEndedRecap {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.pastRecap.section",
                        defaultValue: "活动已结束",
                        comment: "Past event section"
                    )
                )

                meetupInsetActionsGroup {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                        }
                        .buttonStyle(.plain)
                        meetupActionDivider()
                    }

                    NavigationLink {
                        ActivityPastRecapView(
                            activity: activity,
                            feedbackSubmitted: viewModel.feedbackSubmitted,
                            onCommunityRecap: onCommunityRecap,
                            onSubmitFeedback: { feedback in
                                await viewModel.submitHostFeedback(feedback)
                            },
                            onHostAgain: activity.rsvpStatus.hasGroupChatAccess && activity.rsvpStatus != .host
                                ? { showHostAgainCreate = true }
                                : nil
                        )
                    } label: {
                        Label(
                            String(
                                localized: "activity.pastRecap.entry",
                                defaultValue: "活动后记与反馈",
                                comment: "Open post-event summary"
                            ),
                            systemImage: "clock.arrow.circlepath"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                    }
                    .buttonStyle(.plain)
                }

                Text(
                    String(
                        localized: "activity.shareToCommunity.footer",
                        defaultValue: "带上现场照片发到社区，帮其他人了解这场局。",
                        comment: "Share to community footer"
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        }
    }

}

// Module: SparkActivity — Loaded activity detail (Meetup-style scroll layout).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailLoadedList: View {
    @Environment(\.openURL) var openURL
    @Bindable var viewModel: ActivityDetailViewModel
    let activity: ActivityDetail
    let inviteCandidates: [ActivityInviteCandidate]
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    @Binding var showEditActivity: Bool
    @Binding var showAnnounceSheet: Bool
    @Binding var showHostAgainCreate: Bool
    @Binding var showCancelActivityConfirm: Bool

    private var usesBottomRSVPBar: Bool {
        activity.canChangeRSVP && activity.rsvpStatus == .invited
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                meetupCoverSection(activity: activity)
                meetupTitleSection(activity: activity)
                meetupHostSection(activity: activity)
                meetupGroupSection(activity: activity)
                meetupScheduleLocationSection(activity: activity)
                meetupAttendeesPreviewSection(activity: activity)
                meetupDetailsSection(activity: activity)
                meetupRelatedTopicsSection(activity: activity)
                meetupHostOtherEventsSection()

                if !activity.attendees.isEmpty {
                    meetupFullAttendeesSection(activity: activity)
                }

                if showsInviteFriendsSection(for: activity) {
                    meetupInviteFriendsSection(activity: activity)
                }

                postEventScrollSection(activity: activity)

                if activity.showsHostManagement {
                    hostManagementScrollSection(activity: activity)
                } else if activity.canChangeRSVP, !usesBottomRSVPBar {
                    registrationScrollSection(activity: activity, showsRSVPButtons: true)
                } else if activity.rsvpStatus == .waitlisted {
                    registrationScrollSection(activity: activity, showsRSVPButtons: false)
                } else if let blocked = activity.registrationBlockedMessage {
                    meetupNoticeBlock(blocked)
                }

                registrantActionsScrollSection(activity: activity)
                groupChatScrollSection(activity: activity)

                if let hostMessage = viewModel.hostFeedbackMessage {
                    meetupNoticeBlock(hostMessage)
                }
            }
            .padding(.bottom, usesBottomRSVPBar ? 120 : SparkLayoutMetrics.sectionVerticalPadding)
        }
        .background(.background)
        .disabled(viewModel.isUpdatingRSVP || viewModel.isPerformingHostAction)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "activity.detail.loaded.a11y",
                defaultValue: "活动详情",
                comment: "Activity detail list"
            )
        )
    }

    @ViewBuilder
    private func meetupFullAttendeesSection(activity: ActivityDetail) -> some View {
        let isHostView = activity.rsvpStatus == .host
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupDetailSubsectionHeader(
                isHostView
                    ? String(
                        localized: "activity.host.roster.section",
                        defaultValue: "报名名单",
                        comment: "Host roster"
                    )
                    : String(
                        localized: "activity.detail.attendees.section",
                        defaultValue: "参加者",
                        comment: "Attendees section"
                    )
            )

            meetupInsetActionsGroup {
                ForEach(activity.attendees) { attendee in
                    attendeeRow(attendee: attendee, isHostView: isHostView)
                    if attendee.id != activity.attendees.last?.id {
                        meetupActionDivider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func attendeeRow(attendee: ActivityAttendee, isHostView: Bool) -> some View {
        HStack(spacing: 10) {
            Text(String(attendee.displayName.prefix(1)))
                .font(.caption.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.quaternary, in: Circle())

            Text(attendee.displayName)
                .font(.body)
            Spacer(minLength: 0)
            if attendee.isHost {
                Text(
                    String(localized: "activity.attendee.host", defaultValue: "主办", comment: "Host badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if attendee.isVerified {
                Text(
                    String(localized: "activity.attendee.verified", defaultValue: "已实名", comment: "Verified badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if attendee.isCoHost {
                Text(
                    String(localized: "activity.host.cohost.badge", defaultValue: "协办", comment: "Co-host badge")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if isHostView, let status = attendee.rsvpStatus {
                Text(status.localizedLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if status == .waitlisted {
                    Button(
                        String(
                            localized: "activity.host.promote",
                            defaultValue: "提升",
                            comment: "Promote waitlist"
                        )
                    ) {
                        Task { await viewModel.promoteWaitlistedAttendee(attendee.id) }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }

    @ViewBuilder
    private func meetupInviteFriendsSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupDetailSubsectionHeader(
                String(
                    localized: "activity.inviteFriends.section",
                    defaultValue: "邀请好友",
                    comment: "Invite friends section"
                )
            )
            ActivityInviteFriendsSection(
                activity: activity,
                inviteCandidates: inviteCandidates
            ) {
                viewModel.notifyInviteCopied()
            }
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.blockSpacing)

            if viewModel.shouldPromptInviteFriends {
                Text(
                    String(
                        localized: "activity.inviteFriends.afterRSVP",
                        defaultValue: "已报名！把活动发给好友，约好一起参加。",
                        comment: "Post-RSVP invite hint"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        }
    }

}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        NavigationStack {
            ActivityDetailLoadedList(
                viewModel: ActivityDetailViewModel(
                    activityID: activity.id,
                    repository: MockActivityFeedRepository()
                ),
                activity: activity,
                inviteCandidates: [],
                onOpenGroupChat: nil,
                onCommunityRecap: nil,
                showEditActivity: .constant(false),
                showAnnounceSheet: .constant(false),
                showHostAgainCreate: .constant(false),
                showCancelActivityConfirm: .constant(false)
            )
            .environment(ActivityFavoriteStore())
        }
    }
}

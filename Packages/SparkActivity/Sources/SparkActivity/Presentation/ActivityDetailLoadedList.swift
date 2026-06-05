// Module: SparkActivity — Loaded activity detail list sections.

import SparkDesignSystem
import SwiftUI

struct ActivityDetailLoadedList: View {
    @Environment(\.openURL) private var openURL
    @Bindable var viewModel: ActivityDetailViewModel
    let activity: ActivityDetail
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    @Binding var showEditActivity: Bool
    @Binding var showAnnounceSheet: Bool
    @Binding var showHostAgainCreate: Bool
    @Binding var showCancelActivityConfirm: Bool

    var body: some View {
        List {
            if activity.lifecycleStatus != .scheduled {
                Section {
                    Text(activity.lifecycleStatus.localizedLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Label(activity.hostDisplayName, systemImage: "person.crop.circle")
                if let bio = activity.hostBio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label(activity.scheduleLine, systemImage: "calendar")
                locationRow(activity: activity)
                Label(activity.attendeeLine, systemImage: "person.2")
            } header: {
                Text(
                    String(localized: "activity.detail.info.section", defaultValue: "邀请信息", comment: "Activity section")
                )
            }

            if !viewModel.hostOtherActivities.isEmpty {
                Section {
                    ForEach(viewModel.hostOtherActivities) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                Text(item.scheduleLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(
                        String(
                            localized: "activity.host.more.section",
                            defaultValue: "主办的其他活动",
                            comment: "More from host"
                        )
                    )
                }
            } else if viewModel.hostOtherActivitiesLoadFailed {
                Section {
                    Text(
                        String(
                            localized: "activity.host.more.failed",
                            defaultValue: "暂时无法加载主办的其他活动",
                            comment: "Host more load failed"
                        )
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            if !activity.attendees.isEmpty {
                attendeesSection(activity: activity, isHostView: activity.rsvpStatus == .host)
            }

            Section {
                Text(activity.description)
                    .font(.body)
            } header: {
                Text(
                    String(localized: "activity.detail.about.section", defaultValue: "活动说明", comment: "Activity section")
                )
            }

            if showsInviteFriendsSection(for: activity) {
                ActivityInviteFriendsSection(activity: activity) {
                    viewModel.notifyInviteCopied()
                }
                if viewModel.shouldPromptInviteFriends {
                    Section {
                        Text(
                            String(
                                localized: "activity.inviteFriends.afterRSVP",
                                defaultValue: "已报名！把活动发给好友，约好一起参加。",
                                comment: "Post-RSVP invite hint"
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            postEventSection(activity: activity)

            if activity.showsHostManagement {
                hostManagementSection(activity: activity)
            } else if activity.canChangeRSVP {
                registrationSection(activity: activity)
            } else if let blocked = activity.registrationBlockedMessage {
                Section {
                    Text(blocked)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            registrantActionsSection(activity: activity)
            groupChatSection(activity: activity)

            if let hostMessage = viewModel.hostFeedbackMessage {
                Section {
                    Text(hostMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sparkScreenListStyle()
        .disabled(viewModel.isUpdatingRSVP || viewModel.isPerformingHostAction)
    }
}

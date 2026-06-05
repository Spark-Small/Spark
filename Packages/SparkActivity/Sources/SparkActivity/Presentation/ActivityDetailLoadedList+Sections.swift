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
    func postEventSection(activity: ActivityDetail) -> some View {
        if activity.showsEndedRecap {
            Section {
                Label(activity.scheduleLine, systemImage: "clock")
                Label(activity.locationName, systemImage: "mappin.and.ellipse")
                if activity.attendeeCount > 0 {
                    let format = String(
                        localized: "activity.recap.attendees.format",
                        defaultValue: "共 %lld 人参加",
                        comment: "Recap attendee count"
                    )
                    Text(String(format: format, locale: .current, Int64(activity.attendeeCount)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let onCommunityRecap {
                    Button {
                        onCommunityRecap(activity)
                    } label: {
                        Label(
                            String(
                                localized: "activity.recap.community",
                                defaultValue: "发一条感受",
                                comment: "Community recap"
                            ),
                            systemImage: "text.bubble"
                        )
                    }
                }
                if activity.rsvpStatus != .host, !viewModel.feedbackSubmitted {
                    Button {
                        Task { await viewModel.submitHostFeedback(.positive) }
                    } label: {
                        Label(ActivityHostFeedback.positive.localizedLabel, systemImage: "hand.thumbsup")
                    }
                    Button {
                        Task { await viewModel.submitHostFeedback(.negative) }
                    } label: {
                        Label(ActivityHostFeedback.negative.localizedLabel, systemImage: "hand.thumbsdown")
                    }
                }
                if activity.rsvpStatus.hasGroupChatAccess, activity.rsvpStatus != .host {
                    Button {
                        showHostAgainCreate = true
                    } label: {
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
                        localized: "activity.postEvent.section",
                        defaultValue: "活动已结束",
                        comment: "Post event section"
                    )
                )
            }
        }
    }

    @ViewBuilder
    func hostManagementSection(activity: ActivityDetail) -> some View {
        Section {
            Text(activity.signupCounts.localizedSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showEditActivity = true
            } label: {
                Label(
                    String(localized: "activity.host.edit", defaultValue: "编辑活动", comment: "Host edit"),
                    systemImage: "pencil"
                )
            }
            Button {
                showAnnounceSheet = true
            } label: {
                Label(
                    String(localized: "activity.host.announce", defaultValue: "通知报名者", comment: "Host announce"),
                    systemImage: "megaphone"
                )
            }
            Button(role: .destructive) {
                showCancelActivityConfirm = true
            } label: {
                Label(
                    String(localized: "activity.host.cancel", defaultValue: "取消活动", comment: "Host cancel"),
                    systemImage: "xmark.circle"
                )
            }
        } header: {
            Text(
                String(localized: "activity.host.manage.section", defaultValue: "主办管理", comment: "Host section")
            )
        }
    }

    @ViewBuilder
    func locationRow(activity: ActivityDetail) -> some View {
        if let url = ActivityMapURL.mapsURL(locationName: activity.locationName) {
            Button {
                openURL(url)
            } label: {
                Label(activity.locationName, systemImage: "mappin.and.ellipse")
            }
            .accessibilityHint(
                String(
                    localized: "activity.detail.map.hint",
                    defaultValue: "在地图中打开地点",
                    comment: "Map hint"
                )
            )
        } else {
            Label(activity.locationName, systemImage: "mappin.and.ellipse")
        }
    }

    @ViewBuilder
    func attendeesSection(activity: ActivityDetail, isHostView: Bool) -> some View {
        Section {
            ForEach(activity.attendees) { attendee in
                HStack(spacing: 10) {
                    Image(systemName: attendee.isHost ? "star.circle.fill" : "person.circle.fill")
                        .foregroundStyle(attendee.isHost ? .primary : .secondary)
                        .accessibilityHidden(true)
                    Text(attendee.displayName)
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
            }
        } header: {
            if isHostView {
                Text(
                    String(localized: "activity.host.roster.section", defaultValue: "报名名单", comment: "Host roster")
                )
            } else {
                Text(
                    String(
                        localized: "activity.detail.attendees.section",
                        defaultValue: "参加者",
                        comment: "Attendees section"
                    )
                )
            }
        }
    }

}

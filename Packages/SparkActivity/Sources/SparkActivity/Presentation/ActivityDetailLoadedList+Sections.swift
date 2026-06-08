// Module: SparkActivity — Activity detail list section builders.

import SparkCore
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
                }
            } header: {
                Text(
                    String(
                        localized: "activity.pastRecap.section",
                        defaultValue: "活动已结束",
                        comment: "Past event section"
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
            NavigationLink {
                ActivityHostApprovalView(viewModel: viewModel, activity: activity)
            } label: {
                Label(
                    String(
                        localized: "activity.host.approval.entry",
                        defaultValue: "审批与协办",
                        comment: "Host approval entry"
                    ),
                    systemImage: "person.crop.circle.badge.checkmark"
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
        if activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Label(activity.locationName, systemImage: "mappin.and.ellipse")
        } else {
            NavigationLink {
                ActivityMeetupMapView(activityTitle: activity.title, locationName: activity.locationName)
            } label: {
                Label(activity.locationName, systemImage: "mappin.and.ellipse")
            }
            .accessibilityHint(
                String(
                    localized: "activity.detail.map.hint",
                    defaultValue: "查看碰头地点地图",
                    comment: "Map hint"
                )
            )
        }
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
                            IntegrationTelemetry.activityEndToRecap(activityID: activity.id)
                            onCommunityRecap(activity)
                        } label: {
                            Label(
                                String(
                                    localized: "activity.shareToCommunity.cta.primary",
                                    defaultValue: "发局后随拍到社区",
                                    comment: "Primary post-event recap CTA"
                                ),
                                systemImage: "photo.on.rectangle.angled"
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
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

    @ViewBuilder
    func hostManagementScrollSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupDetailSubsectionHeader(
                String(localized: "activity.host.manage.section", defaultValue: "主办管理", comment: "Host section")
            )

            meetupInsetActionsGroup {
                Text(activity.signupCounts.localizedSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                    .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                meetupActionDivider()

                hostActionButton(
                    title: String(localized: "activity.host.edit", defaultValue: "编辑活动", comment: "Host edit"),
                    systemImage: "pencil"
                ) {
                    showEditActivity = true
                }
                meetupActionDivider()

                if canAccessHostTools {
                    NavigationLink {
                        ActivityHostApprovalView(viewModel: viewModel, activity: activity)
                    } label: {
                        hostActionLabel(
                            title: String(
                                localized: "activity.host.approval.entry",
                                defaultValue: "审批与协办",
                                comment: "Host approval entry"
                            ),
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    hostLockedActionButton(
                        title: String(
                            localized: "activity.host.approval.entry",
                            defaultValue: "审批与协办",
                            comment: "Host approval entry"
                        ),
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                }
                meetupActionDivider()

                if canAccessHostTools {
                    hostActionButton(
                        title: String(localized: "activity.host.announce", defaultValue: "通知报名者", comment: "Host announce"),
                        systemImage: "megaphone"
                    ) {
                        showAnnounceSheet = true
                    }
                } else {
                    hostLockedActionButton(
                        title: String(localized: "activity.host.announce", defaultValue: "通知报名者", comment: "Host announce"),
                        systemImage: "megaphone"
                    )
                }
                meetupActionDivider()

                Button(role: .destructive) {
                    showCancelActivityConfirm = true
                } label: {
                    hostActionLabel(
                        title: String(localized: "activity.host.cancel", defaultValue: "取消活动", comment: "Host cancel"),
                        systemImage: "xmark.circle"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func hostActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            hostActionLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func hostLockedActionButton(title: String, systemImage: String) -> some View {
        Button {
            onHostToolsLocked?()
        } label: {
            HStack {
                hostActionLabel(title: title, systemImage: systemImage)
                Spacer(minLength: 0)
                Image(systemName: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            String(
                localized: "activity.host.tools.locked.hint",
                defaultValue: "升级后可使用主办工具",
                comment: "Host tools paywall hint"
            )
        )
    }

    private func hostActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
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

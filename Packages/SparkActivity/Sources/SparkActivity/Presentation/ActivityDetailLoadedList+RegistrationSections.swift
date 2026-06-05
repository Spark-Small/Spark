// Module: SparkActivity — Activity detail registration and group chat sections.

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    @ViewBuilder
    func registrationSection(activity: ActivityDetail) -> some View {
        Section {
            if let blocked = activity.registrationBlockedMessage {
                Text(blocked)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            rsvpButtons(for: activity)
            if activity.canJoinWaitlist {
                Button {
                    Task { await viewModel.joinWaitlist() }
                } label: {
                    Text(
                        String(
                            localized: "activity.waitlist.join",
                            defaultValue: "加入候补",
                            comment: "Join waitlist"
                        )
                    )
                }
            }
            if activity.rsvpStatus == .waitlisted {
                Text(
                    String(
                        localized: "activity.waitlist.status",
                        defaultValue: "你已在候补名单，有空位时主办可提升你为参加。",
                        comment: "Waitlist status"
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            if let error = viewModel.rsvpErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(ActivityRSVPStatus.invited.registrationSectionTitle)
        } footer: {
            Text(
                String(
                    localized: "activity.detail.registration.footer",
                    defaultValue: "选择参加或也许后，可进入活动群聊与主办人、其他报名者沟通。",
                    comment: "Registration footer"
                )
            )
        }
    }

    @ViewBuilder
    func registrantActionsSection(activity: ActivityDetail) -> some View {
        if activity.showsRegistrantActions {
            Section {
                Button {
                    Task { await viewModel.addToCalendar() }
                } label: {
                    Label(
                        String(
                            localized: "activity.detail.addCalendar",
                            defaultValue: "加入日历",
                            comment: "Add to calendar"
                        ),
                        systemImage: "calendar.badge.plus"
                    )
                }
                if activity.rsvpStatus == .going || activity.rsvpStatus == .maybe {
                    Button(role: .destructive) {
                        Task { await viewModel.cancelAttendance() }
                    } label: {
                        Text(
                            String(
                                localized: "activity.detail.cancelAttendance",
                                defaultValue: "取消参加",
                                comment: "Cancel RSVP"
                            )
                        )
                    }
                }
            } header: {
                Text(
                    String(
                        localized: "activity.detail.myPlan.section",
                        defaultValue: "我的安排",
                        comment: "Registrant actions"
                    )
                )
            } footer: {
                if let message = viewModel.calendarFeedbackMessage {
                    Text(message)
                        .font(.footnote)
                }
            }
        }
    }

    @ViewBuilder
    func groupChatSection(activity: ActivityDetail) -> some View {
        if activity.rsvpStatus.hasGroupChatAccess, let onOpenGroupChat {
            Section {
                Button(
                    String(
                        localized: "activity.detail.openChat",
                        defaultValue: "活动群聊",
                        comment: "Open activity chat"
                    )
                ) {
                    Task { await onOpenGroupChat(activity) }
                }
            } footer: {
                Text(
                    String(
                        localized: "activity.detail.openChat.footer",
                        defaultValue: "与已报名者一起讨论集合时间与细节。",
                        comment: "Group chat footer"
                    )
                )
            }
        } else if activity.conversationThreadID != nil, activity.lifecycleStatus == .scheduled {
            Section {
                Text(
                    String(
                        localized: "activity.detail.chat.locked",
                        defaultValue: "报名后可进入活动群聊",
                        comment: "Chat locked hint"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    func rsvpButtons(for activity: ActivityDetail) -> some View {
        ForEach(ActivityRSVPStatus.selectableResponses, id: \.self) { status in
            let isGoing = status == .going
            let disabled = viewModel.isUpdatingRSVP || (isGoing && !activity.canSelectGoing)
            Button {
                Task { await viewModel.submitRSVP(status) }
            } label: {
                HStack {
                    Text(status.localizedLabel)
                    Spacer()
                    if viewModel.activity?.rsvpStatus == status {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .disabled(disabled)
            .accessibilityAddTraits(viewModel.activity?.rsvpStatus == status ? .isSelected : [])
        }
    }
}

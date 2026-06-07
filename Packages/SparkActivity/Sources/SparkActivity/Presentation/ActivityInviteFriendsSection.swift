// Module: SparkActivity — Path B→A: invite friends to join (share + copy).

import SparkDesignSystem
import SwiftUI

struct ActivityInviteFriendsSection: View {
    let activity: ActivityDetail
    let inviteCandidates: [ActivityInviteCandidate]
    let onCopied: () -> Void

    @State private var showInvitePicker = false
    @State private var showWeChatShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            meetupInsetActionsGroup {
                if !inviteCandidates.isEmpty {
                    inviteButton(
                        title: String(
                            localized: "activity.inviteFriends.inApp",
                            defaultValue: "从好友中选择",
                            comment: "In-app invite picker"
                        ),
                        systemImage: "person.2.circle"
                    ) {
                        showInvitePicker = true
                    }
                    meetupActionDivider()
                }

                ShareLink(
                    item: ActivityInviteURL.shareLink(activityID: activity.id),
                    subject: Text(activity.title),
                    message: Text(ActivityInviteURL.inviteCopyText(activity: activity))
                ) {
                    inviteLabel(
                        title: String(
                            localized: "activity.inviteFriends.share",
                            defaultValue: "分享给好友",
                            comment: "Invite friends share"
                        ),
                        systemImage: "square.and.arrow.up"
                    )
                }
                .buttonStyle(.plain)
                meetupActionDivider()

                inviteButton(
                    title: String(
                        localized: "activity.inviteFriends.copyWeChat",
                        defaultValue: "分享到微信",
                        comment: "Share to WeChat"
                    ),
                    systemImage: "message.fill"
                ) {
                    showWeChatShare = true
                }
                .accessibilityHint(
                    String(
                        localized: "activity.inviteFriends.copyWeChat.hint",
                        defaultValue: "复制邀请文案后粘贴到微信",
                        comment: "WeChat copy hint"
                    )
                )
                meetupActionDivider()

                inviteButton(
                    title: String(
                        localized: "activity.inviteFriends.copy",
                        defaultValue: "复制邀请文案",
                        comment: "Invite friends copy"
                    ),
                    systemImage: "doc.on.doc"
                ) {
                    ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                    onCopied()
                }
                .accessibilityHint(
                    String(
                        localized: "activity.inviteFriends.copy.hint",
                        defaultValue: "复制后可粘贴给好友",
                        comment: "Copy invite hint"
                    )
                )
            }

            Text(
                String(
                    localized: "activity.inviteFriends.footer",
                    defaultValue: "把活动发给朋友，他们打开链接即可一起报名。",
                    comment: "Invite friends footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showInvitePicker) {
            ActivityInvitePickerView(
                activity: activity,
                candidates: inviteCandidates,
                onInvite: { _ in onCopied() }
            )
        }
        .sheet(isPresented: $showWeChatShare) {
            ActivityWeChatShareSheet(activity: activity, onCopied: onCopied)
        }
    }

    private func inviteButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            inviteLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func inviteLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }

    private func meetupInsetActionsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
    }

    private func meetupActionDivider() -> some View {
        Divider()
            .padding(.leading, ActivityDetailMeetupLayout.horizontalPadding)
    }
}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        ScrollView {
            ActivityInviteFriendsSection(activity: activity, inviteCandidates: [], onCopied: {})
                .padding()
        }
    }
}

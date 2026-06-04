// Module: SparkActivity — Path B→A: invite friends to join (share + copy).

import SwiftUI

struct ActivityInviteFriendsSection: View {
    let activity: ActivityDetail
    let onCopied: () -> Void

    var body: some View {
        Section {
            ShareLink(
                item: ActivityInviteURL.shareLink(activityID: activity.id),
                subject: Text(activity.title),
                message: Text(ActivityInviteURL.inviteCopyText(activity: activity))
            ) {
                Label(
                    String(
                        localized: "activity.inviteFriends.share",
                        defaultValue: "分享给好友",
                        comment: "Invite friends share"
                    ),
                    systemImage: "square.and.arrow.up"
                )
            }
            Button {
                ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                onCopied()
            } label: {
                Label(
                    String(
                        localized: "activity.inviteFriends.copy",
                        defaultValue: "复制邀请文案",
                        comment: "Invite friends copy"
                    ),
                    systemImage: "doc.on.doc"
                )
            }
        } header: {
            Text(
                String(
                    localized: "activity.inviteFriends.section",
                    defaultValue: "邀请好友",
                    comment: "Invite friends section"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.inviteFriends.footer",
                    defaultValue: "把活动发给朋友，他们打开链接即可一起报名。",
                    comment: "Invite friends footer"
                )
            )
        }
    }
}

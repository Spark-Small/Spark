// Module: SparkMessages — DM and group chat avatar stacks.

import SparkDesignSystem
import SwiftUI

struct DMAvatar: View {
    let partner: InboxUserProfile?
    let displayName: String
    let isOnline: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            if isOnline {
                Circle()
                    .fill(Color(.systemGreen))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(.background, lineWidth: 2))
                    .offset(x: 2, y: 2)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(displayName)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let url = partner?.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    initialsPlaceholder
                }
            )
        } else {
            initialsPlaceholder
        }
    }

    private var initialsPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.accentColor)
    }
}

struct GroupChatAvatar: View {
    let activity: InboxActivitySummary?
    let displayName: String

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: 48, height: 48)
                .sparkGlassSurface(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if let url = activity?.coverURL {
                SparkCachedRemoteImage(
                    url: url,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        groupIcon
                    }
                )
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                groupIcon
            }
        }
        .accessibilityLabel(displayName)
    }

    private var groupIcon: some View {
        Image(systemName: "figure.hiking")
            .font(.title3)
            .foregroundStyle(Color.accentColor)
    }
}

#Preview("DM avatar") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 1)
    HStack(spacing: 24) {
        if let dm = inbox.dmConversations.first {
            DMAvatar(
                partner: dm.dmPartner,
                displayName: dm.displayName,
                isOnline: true
            )
            DMAvatar(
                partner: dm.dmPartner,
                displayName: dm.displayName,
                isOnline: false
            )
        }
    }
    .padding()
}

#Preview("Group chat avatar") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 1)
    if let group = inbox.activeGroupChats.first {
        GroupChatAvatar(activity: group.activity, displayName: group.displayName)
            .padding()
    }
}

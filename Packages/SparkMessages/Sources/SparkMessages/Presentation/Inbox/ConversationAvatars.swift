// Module: SparkMessages — Inbox conversation avatars (DM + group, shared chrome).

import SparkDesignSystem
import SwiftUI

struct DMAvatar: View {
    let partner: InboxUserProfile?
    let displayName: String
    let isOnline: Bool
    var unreadCount: Int = 0

    var body: some View {
        InboxConversationAvatar(
            imageURL: partner?.avatarURL,
            displayName: displayName,
            placeholderSystemImage: "person.circle.fill",
            showsOnlineIndicator: isOnline,
            unreadCount: unreadCount
        )
    }
}

struct GroupChatAvatar: View {
    let activity: InboxActivitySummary?
    let displayName: String
    var unreadCount: Int = 0

    var body: some View {
        InboxConversationAvatar(
            imageURL: activity?.coverURL,
            displayName: displayName,
            placeholderSystemImage: "person.3.fill",
            showsOnlineIndicator: false,
            unreadCount: unreadCount
        )
    }
}

struct ConversationHeaderAvatar: View {
    let imageURL: URL?
    let displayName: String
    let placeholderSystemImage: String

    var body: some View {
        InboxConversationAvatar(
            imageURL: imageURL,
            displayName: displayName,
            placeholderSystemImage: placeholderSystemImage,
            showsOnlineIndicator: false,
            diameter: 32
        )
    }
}

/// Shared circular avatar for inbox rows and conversation navigation.
private struct InboxConversationAvatar: View {
    let imageURL: URL?
    let displayName: String
    let placeholderSystemImage: String
    let showsOnlineIndicator: Bool
    var unreadCount: Int = 0
    var diameter: CGFloat = SparkLayoutMetrics.tabPersonAvatarSize

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
            if showsOnlineIndicator {
                Circle()
                    .fill(Color(.systemGreen))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(.background, lineWidth: 2))
                    .offset(x: 2, y: 2)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topTrailing) {
            if unreadCount > 0 {
                UnreadBadge(count: unreadCount)
                    .offset(
                        x: SparkLayoutMetrics.inboxAvatarUnreadBadgeOffset,
                        y: -SparkLayoutMetrics.inboxAvatarUnreadBadgeOffset
                    )
            }
        }
        .accessibilityLabel(displayName)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageURL {
            SparkCachedRemoteImage(
                url: imageURL,
                maxPixelSize: 128,
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                },
                placeholder: {
                    placeholder
                }
            )
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: placeholderSystemImage)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
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
                isOnline: true,
                unreadCount: 3
            )
            DMAvatar(
                partner: dm.dmPartner,
                displayName: dm.displayName,
                isOnline: false,
                unreadCount: 0
            )
        }
    }
    .padding()
}

#Preview("Group chat avatar") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 1)
    if let group = inbox.activeGroupChats.first {
        GroupChatAvatar(activity: group.activity, displayName: group.displayName, unreadCount: 2)
            .padding()
    }
}

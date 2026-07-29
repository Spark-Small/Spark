//
//  CommunityFeedChannel.swift
//  坐标系
//
//  社区顶栏下方横滑频道：好友 / 爱好 / 群聊，点选切换 Feed。
//

import SwiftUI

// MARK: - Channel model

enum CommunityFeedChannelKind: Hashable {
    case all
    case friend(name: String)
    case interest(tag: String)
    case group(conversationID: UUID, title: String, memberNames: [String], relatedActivityID: UUID?)
}

struct CommunityFeedChannel: Identifiable, Hashable {
    let id: String
    let title: String
    let kind: CommunityFeedChannelKind

    static let all = CommunityFeedChannel(id: "all", title: "全部", kind: .all)

    var symbolName: String {
        switch kind {
        case .all:
            return "square.grid.2x2"
        case .friend:
            return "person.crop.circle.fill"
        case .interest(let tag):
            return ActivityTaxonomy.systemImage(forSubtype: tag)
        case .group:
            return "person.crop.rectangle.stack"
        }
    }

    var accessibilityLabel: String {
        switch kind {
        case .all: "全部分享"
        case .friend(let name): "好友 \(name) 的分享"
        case .interest(let tag): "爱好 \(tag) 相关分享"
        case .group(_, let title, _, _): "群聊 \(title) 相关分享"
        }
    }
}

enum CommunityFeedChannelCatalog {
    @MainActor
    static func channels(
        interests: [String],
        messages: MessagesModel,
        buddies: BuddiesModel,
        blockedNames: Set<String>
    ) -> [CommunityFeedChannel] {
        var result = [CommunityFeedChannel.all]
        var seenFriends = Set<String>()

        func appendFriend(_ name: String) {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seenFriends.contains(key) else { return }
            if blockedNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                return
            }
            seenFriends.insert(key)
            result.append(
                CommunityFeedChannel(
                    id: "friend:\(key)",
                    title: messages.displayName(for: trimmed),
                    kind: .friend(name: trimmed)
                )
            )
        }

        for conversation in messages.conversations
            where conversation.isFriendChat && !conversation.isMessageRequest {
            appendFriend(conversation.title)
        }
        for record in buddies.inviteRecords {
            appendFriend(record.nickname)
        }
        for record in buddies.bookingRecords {
            appendFriend(record.companionNickname)
        }

        for interest in interests {
            let trimmed = interest.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            result.append(
                CommunityFeedChannel(
                    id: "interest:\(key)",
                    title: trimmed,
                    kind: .interest(tag: trimmed)
                )
            )
        }

        for conversation in messages.conversations where conversation.isActivityGroup {
            result.append(
                CommunityFeedChannel(
                    id: "group:\(conversation.id.uuidString)",
                    title: conversation.title,
                    kind: .group(
                        conversationID: conversation.id,
                        title: conversation.title,
                        memberNames: conversation.memberNames,
                        relatedActivityID: conversation.relatedActivityID
                    )
                )
            )
        }

        return result
    }
}

extension CommunityFeedChannelKind {
    func matches(_ post: CommunityPost) -> Bool {
        switch self {
        case .all:
            return true
        case .friend(let name):
            return post.author.caseInsensitiveCompare(name) == .orderedSame
        case .interest(let tag):
            return post.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
                || post.body.localizedCaseInsensitiveContains(tag)
                || post.messageText.localizedCaseInsensitiveContains(tag)
        case .group(_, _, let memberNames, let relatedActivityID):
            let authorInGroup = memberNames.contains {
                $0.caseInsensitiveCompare(post.author) == .orderedSame
            }
            if authorInGroup { return true }
            if let relatedActivityID, post.relatedActivityID == relatedActivityID { return true }
            return false
        }
    }
}

// MARK: - Rail UI

struct CommunityFeedChannelRail: View {
    let channels: [CommunityFeedChannel]
    let selectedKind: CommunityFeedChannelKind
    var onSelect: (CommunityFeedChannelKind) -> Void

    var body: some View {
        DiscoverHorizontalRail(spacing: PlatformMetrics.railCardSpacing) {
            ForEach(channels) { channel in
                CommunityFeedChannelAvatarButton(
                    channel: channel,
                    isSelected: channel.kind == selectedKind,
                    action: { onSelect(channel.kind) }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("分享频道")
    }
}

private struct CommunityFeedChannelAvatarButton: View {
    let channel: CommunityFeedChannel
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var avatarSide: CGFloat { dynamicTypeSize.channelRailAvatarSide }
    private var itemWidth: CGFloat { avatarSide + PlatformMetrics.minContentGap }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                avatar
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    }
                Text(channel.title)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .frame(width: itemWidth, alignment: .leading)
            }
            .frame(width: itemWidth, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(channel.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    @ViewBuilder
    private var avatar: some View {
        switch channel.kind {
        case .friend:
            ZStack {
                Color(.tertiarySystemFill)
                PlatformSystemAvatar(side: avatarSide)
            }
            .frame(width: avatarSide, height: avatarSide)
            .clipShape(Circle())
        case .all, .interest, .group:
            ZStack {
                Color(.tertiarySystemFill)
                PlatformListSymbolAvatar(systemName: channel.symbolName, side: avatarSide)
            }
            .frame(width: avatarSide, height: avatarSide)
            .clipShape(Circle())
        }
    }
}

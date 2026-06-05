// Module: SparkMessages — Maps API DTOs to domain models.

import Foundation

enum MessagesDTOMapper {
    static func inbox(from dto: MessagesInboxResponseDTO) throws -> MessagesInbox {
        let actionItems = try dto.actionItems.map(actionItem)
        let matches = try dto.unmessagedMatches.map(matchPreview)
        let dm = try dto.dmConversations.map(conversationPreview)
        let groups = try dto.groupConversations.map(conversationPreview)
        let active = groups.filter { !$0.isArchived }
        let archived = groups.filter(\.isArchived)
        return MessagesInbox(
            actionItems: actionItems,
            unmessagedMatches: matches,
            dmConversations: dm,
            activeGroupChats: active,
            archivedGroupChats: archived
        )
    }

    static func conversationContext(from dto: ConversationContextResponseDTO) throws -> ConversationContext {
        ConversationContext(
            sharedActivities: try dto.sharedActivities.map(inboxActivity),
            relationshipStatus: dto.relationshipStatus
        )
    }

    static func thread(from dto: MessageThreadDTO) throws -> MessageThread {
        guard let date = parseISO8601(dto.lastActivityAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        return MessageThread(
            threadID: MessageThreadID(dto.id),
            peerDisplayName: dto.peerDisplayName,
            lastMessagePreview: dto.lastMessagePreview,
            lastActivityAt: date,
            unreadCount: dto.unreadCount
        )
    }

    static func message(from dto: ChatMessageDTO) throws -> ChatMessage {
        guard let date = parseISO8601(dto.sentAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        let kind = ChatMessageKind(rawValue: dto.kind ?? "text") ?? .text
        let systemPayload: MessagesSystemPayload?
        if let system = dto.system {
            systemPayload = MessagesSystemPayload(
                typeLabel: system.typeLabel,
                title: system.title,
                body: system.body,
                ctaTitle: system.ctaTitle,
                ctaActivityID: system.ctaActivityID
            )
        } else {
            systemPayload = nil
        }
        return ChatMessage(
            id: dto.id,
            threadID: MessageThreadID(dto.threadId),
            body: dto.body,
            sentAt: date,
            isFromCurrentUser: dto.isFromCurrentUser,
            kind: kind,
            systemPayload: systemPayload,
            activityID: dto.activityID
        )
    }

    private static func actionItem(from dto: ActionItemDTO) throws -> ActionItem {
        guard let date = parseISO8601(dto.createdAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        let kind: ActionItemKind
        switch dto.type {
        case "activity_invite":
            guard let invite = dto.invite else { throw MessagesError.underlying(.decodingFailed) }
            kind = .activityInvite(try activityInvite(from: invite))
        case "activity_changed":
            guard let change = dto.change else { throw MessagesError.underlying(.decodingFailed) }
            kind = .activityChanged(try activityChange(from: change))
        case "waitlist_promoted":
            guard let activity = dto.activity else { throw MessagesError.underlying(.decodingFailed) }
            kind = .waitlistPromoted(try inboxActivity(from: activity))
        default:
            throw MessagesError.underlying(.decodingFailed)
        }
        return ActionItem(id: dto.id, kind: kind, priority: dto.priority, createdAt: date)
    }

    private static func activityInvite(from dto: ActivityInviteDTO) throws -> ActivityInvite {
        ActivityInvite(
            id: dto.id,
            activity: try inboxActivity(from: dto.activity),
            inviter: inboxUser(from: dto.inviter)
        )
    }

    private static func activityChange(from dto: ActivityChangeDTO) throws -> ActivityChange {
        let changeKind: ActivityChange.ChangeKind = dto.kind == "cancelled" ? .cancelled : .rescheduled
        return ActivityChange(
            id: dto.id,
            kind: changeKind,
            activity: try inboxActivity(from: dto.activity),
            hostName: dto.hostName,
            previousScheduleLine: dto.previousScheduleLine
        )
    }

    private static func matchPreview(from dto: MatchPreviewDTO) throws -> MatchPreview {
        guard let date = parseISO8601(dto.matchedAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        return MatchPreview(
            id: dto.id,
            user: inboxUser(from: dto.user),
            matchedAt: date,
            threadID: dto.threadID.map(MessageThreadID.init)
        )
    }

    private static func conversationPreview(from dto: ConversationPreviewDTO) throws -> ConversationPreview {
        guard let date = parseISO8601(dto.lastMessageAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        let kind: ConversationKind = dto.kind == "group_chat" ? .groupChat : .dm
        return ConversationPreview(
            threadID: MessageThreadID(dto.id),
            kind: kind,
            displayName: dto.displayName,
            lastMessagePreview: dto.lastMessagePreview,
            lastMessageAt: date,
            unreadCount: dto.unreadCount,
            dmPartner: dto.dmPartner.map(inboxUser),
            isPartnerOnline: dto.isPartnerOnline,
            activity: try dto.activity.map(inboxActivity),
            memberCount: dto.memberCount,
            isArchived: dto.isArchived ?? false
        )
    }

    private static func inboxUser(from dto: InboxUserProfileDTO) -> InboxUserProfile {
        InboxUserProfile(
            id: dto.id,
            displayName: dto.displayName,
            avatarURL: dto.avatarURL.flatMap(URL.init(string:)),
            firstName: dto.firstName
        )
    }

    private static func inboxActivity(from dto: InboxActivitySummaryDTO) throws -> InboxActivitySummary {
        guard let date = parseISO8601(dto.startsAt) else {
            throw MessagesError.underlying(.decodingFailed)
        }
        let lifecycle = InboxActivityLifecycle(rawValue: dto.lifecycle ?? "upcoming") ?? .upcoming
        return InboxActivitySummary(
            id: dto.id,
            title: dto.title,
            coverURL: dto.coverURL.flatMap(URL.init(string:)),
            startsAt: date,
            attendeeCount: dto.attendeeCount,
            lifecycle: lifecycle
        )
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

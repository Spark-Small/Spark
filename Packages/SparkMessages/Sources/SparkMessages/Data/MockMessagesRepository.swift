// Module: SparkMessages — Preview and test double with unified inbox data.

import Foundation

/// In-memory repository for previews, tests, and mock API hosts.
public actor MockMessagesRepository: MessagesRepository {
    private var inbox: MessagesInbox
    private var messagesByThread: [String: [ChatMessage]]
    private var dismissedActionItemIDs: Set<String> = []
    public private(set) var markReadCallCount = 0
    public private(set) var markThreadReadCallCount = 0
    public private(set) var dismissActionItemCallCount = 0

    public init(unreadCount: Int = 3) {
        inbox = MockMessagesInboxCatalog.inbox(unreadCount: unreadCount)
        messagesByThread = Self.seedMessages(from: inbox)
    }

    public func fetchUnreadCount() async throws -> Int {
        inbox.actionItems.count
            + inbox.dmConversations.reduce(0) { $0 + $1.unreadCount }
            + inbox.activeGroupChats.reduce(0) { $0 + $1.unreadCount }
    }

    public func fetchInbox() async throws -> MessagesInbox {
        MessagesInbox(
            actionItems: inbox.actionItems.filter { !dismissedActionItemIDs.contains($0.id) },
            unmessagedMatches: inbox.unmessagedMatches,
            dmConversations: inbox.dmConversations,
            activeGroupChats: inbox.activeGroupChats,
            archivedGroupChats: inbox.archivedGroupChats
        )
    }

    public func fetchThreads() async throws -> [MessageThread] {
        inbox.allThreads.sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    public func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext {
        MockMessagesInboxCatalog.conversationContext(for: threadID)
    }

    public func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] {
        messagesByThread[threadID.rawValue] ?? []
    }

    public func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessagesError.underlying(.unknown(message: "Empty message"))
        }
        let message = ChatMessage(
            id: "msg_mock_\(UUID().uuidString.prefix(8))",
            threadID: threadID,
            body: trimmed,
            sentAt: Date(),
            isFromCurrentUser: true
        )
        var list = messagesByThread[threadID.rawValue] ?? []
        list.append(message)
        messagesByThread[threadID.rawValue] = list
        updatePreview(threadID: threadID, preview: trimmed, at: message.sentAt)
        return message
    }

    public func markAllRead() async throws {
        markReadCallCount += 1
        inbox = MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: inbox.unmessagedMatches,
            dmConversations: inbox.dmConversations.map(clearUnread),
            activeGroupChats: inbox.activeGroupChats.map(clearUnread),
            archivedGroupChats: inbox.archivedGroupChats.map(clearUnread)
        )
    }

    public func markThreadRead(threadID: MessageThreadID) async throws {
        markThreadReadCallCount += 1
        inbox = MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: inbox.unmessagedMatches,
            dmConversations: inbox.dmConversations.map { clearUnreadIfNeeded($0, threadID: threadID) },
            activeGroupChats: inbox.activeGroupChats.map { clearUnreadIfNeeded($0, threadID: threadID) },
            archivedGroupChats: inbox.archivedGroupChats.map { clearUnreadIfNeeded($0, threadID: threadID) }
        )
    }

    private func clearUnreadIfNeeded(
        _ conversation: ConversationPreview,
        threadID: MessageThreadID
    ) -> ConversationPreview {
        guard conversation.threadID == threadID else { return conversation }
        return clearUnread(conversation)
    }

    public func dismissInboxActionItem(id: String) async throws {
        guard inbox.actionItems.contains(where: { $0.id == id }) else {
            throw MessagesError.underlying(.server(statusCode: 404, message: "Action item not found"))
        }
        dismissedActionItemIDs.insert(id)
        dismissActionItemCallCount += 1
    }

    public func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {
        inbox = MessagesInbox(
            actionItems: inbox.actionItems.filter { item in
                if case .activityInvite(let invite) = item.kind {
                    return invite.id != invitationID && invite.activity.id != activityID
                }
                return true
            },
            unmessagedMatches: inbox.unmessagedMatches,
            dmConversations: inbox.dmConversations,
            activeGroupChats: inbox.activeGroupChats,
            archivedGroupChats: inbox.archivedGroupChats
        )
        if accept {
            // REASONING: Mock simulates invite acceptance by removing the invite action only.
        }
    }

    public func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        let threadID = MessageThreadID("th_dm_\(peerUserID)")
        let welcome = String(
            localized: "likes.dm.welcome",
            defaultValue: "你们互相喜欢，打个招呼吧",
            comment: "DM welcome"
        )
        try await ensureActivityGroupThread(
            threadID: threadID,
            displayName: peerDisplayName,
            welcomeMessage: welcome
        )
        return threadID
    }

    public func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        guard !inbox.allThreads.contains(where: { $0.threadID == threadID }) else { return }
        let now = Date()
        let preview = ConversationPreview(
            threadID: threadID,
            kind: threadID.rawValue.hasPrefix("th_dm_") ? .dm : .groupChat,
            displayName: displayName,
            lastMessagePreview: welcomeMessage,
            lastMessageAt: now,
            unreadCount: 0
        )
        if preview.kind == .dm {
            inbox = MessagesInbox(
                actionItems: inbox.actionItems,
                unmessagedMatches: inbox.unmessagedMatches,
                dmConversations: [preview] + inbox.dmConversations,
                activeGroupChats: inbox.activeGroupChats,
                archivedGroupChats: inbox.archivedGroupChats
            )
        } else {
            inbox = MessagesInbox(
                actionItems: inbox.actionItems,
                unmessagedMatches: inbox.unmessagedMatches,
                dmConversations: inbox.dmConversations,
                activeGroupChats: [preview] + inbox.activeGroupChats,
                archivedGroupChats: inbox.archivedGroupChats
            )
        }
        messagesByThread[threadID.rawValue] = [
            ChatMessage(
                id: "msg_welcome_\(threadID.rawValue)",
                threadID: threadID,
                body: welcomeMessage,
                sentAt: now,
                isFromCurrentUser: false
            )
        ]
    }

    private func updatePreview(threadID: MessageThreadID, preview: String, at date: Date) {
        inbox = MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: inbox.unmessagedMatches,
            dmConversations: inbox.dmConversations.map { update($0, threadID: threadID, preview: preview, at: date) },
            activeGroupChats: inbox.activeGroupChats.map { update($0, threadID: threadID, preview: preview, at: date) },
            archivedGroupChats: inbox.archivedGroupChats.map { update($0, threadID: threadID, preview: preview, at: date) }
        )
    }

    private func update(
        _ conversation: ConversationPreview,
        threadID: MessageThreadID,
        preview: String,
        at date: Date
    ) -> ConversationPreview {
        guard conversation.threadID == threadID else { return conversation }
        return ConversationPreview(
            threadID: conversation.threadID,
            kind: conversation.kind,
            displayName: conversation.displayName,
            lastMessagePreview: preview,
            lastMessageAt: date,
            unreadCount: conversation.unreadCount,
            dmPartner: conversation.dmPartner,
            isPartnerOnline: conversation.isPartnerOnline,
            activity: conversation.activity,
            memberCount: conversation.memberCount,
            isArchived: conversation.isArchived
        )
    }

    private func clearUnread(_ conversation: ConversationPreview) -> ConversationPreview {
        ConversationPreview(
            threadID: conversation.threadID,
            kind: conversation.kind,
            displayName: conversation.displayName,
            lastMessagePreview: conversation.lastMessagePreview,
            lastMessageAt: conversation.lastMessageAt,
            unreadCount: 0,
            dmPartner: conversation.dmPartner,
            isPartnerOnline: conversation.isPartnerOnline,
            activity: conversation.activity,
            memberCount: conversation.memberCount,
            isArchived: conversation.isArchived
        )
    }

    private static func seedMessages(from inbox: MessagesInbox) -> [String: [ChatMessage]] {
        var map: [String: [ChatMessage]] = [:]
        let now = Date()
        for conversation in inbox.dmConversations + inbox.activeGroupChats + inbox.archivedGroupChats {
            var messages: [ChatMessage] = [
                ChatMessage(
                    id: "msg_seed_\(conversation.id)",
                    threadID: conversation.threadID,
                    body: conversation.lastMessagePreview,
                    sentAt: conversation.lastMessageAt,
                    isFromCurrentUser: false
                )
            ]
            if conversation.kind == .groupChat {
                messages.insert(
                    ChatMessage(
                        id: "msg_system_\(conversation.id)",
                        threadID: conversation.threadID,
                        body: "",
                        sentAt: now.addingTimeInterval(-120),
                        isFromCurrentUser: false,
                        kind: .system,
                        systemPayload: MessagesSystemPayload(
                            typeLabel: String(
                                localized: "messages.system.reschedule",
                                defaultValue: "活动改期通知",
                                comment: "Reschedule"
                            ),
                            title: conversation.activity?.title ?? conversation.displayName,
                            body: String(
                                localized: "messages.mock.system.body",
                                defaultValue: "主办更新了活动时间，请查看最新安排。",
                                comment: "System body"
                            ),
                            ctaTitle: String(
                                localized: "messages.activity.viewDetail",
                                defaultValue: "查看详情",
                                comment: "View detail"
                            ),
                            ctaActivityID: conversation.activity?.id
                        )
                    ),
                    at: 0
                )
            }
            if conversation.kind == .dm {
                messages.append(
                    ChatMessage(
                        id: "msg_share_\(conversation.id)",
                        threadID: conversation.threadID,
                        body: "",
                        sentAt: now.addingTimeInterval(-60),
                        isFromCurrentUser: false,
                        kind: .activityShare,
                        activityID: "act_1"
                    )
                )
            }
            map[conversation.threadID.rawValue] = messages
        }
        return map
    }
}

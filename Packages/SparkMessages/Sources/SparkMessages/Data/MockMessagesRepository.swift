// Module: SparkMessages — Preview and test double with unified inbox data.

import Foundation

/// In-memory repository for previews, tests, and mock API hosts.
public actor MockMessagesRepository: MessagesRepository {
    private var inbox: MessagesInbox
    private var messagesByThread: [String: [ChatMessage]]
    private var dismissedActionItemIDs: Set<String> = []
    private var hiddenThreadIDs: Set<String> = []
    private var deletedThreadIDs: Set<String> = []
    public private(set) var markReadCallCount = 0
    public private(set) var markThreadReadCallCount = 0
    public private(set) var hideThreadCallCount = 0
    public private(set) var deleteThreadCallCount = 0
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
        let visible = visibleInbox()
        return MessagesInbox(
            actionItems: visible.actionItems.filter { !dismissedActionItemIDs.contains($0.id) },
            unmessagedMatches: visible.unmessagedMatches,
            dmConversations: visible.dmConversations,
            activeGroupChats: visible.activeGroupChats,
            archivedGroupChats: visible.archivedGroupChats
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

    public func sendMessage(threadID: MessageThreadID, body: String, kind: ChatMessageKind = .text) async throws -> ChatMessage {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessagesError.underlying(.unknown(message: "Empty message"))
        }
        let message = ChatMessage(
            id: "msg_mock_\(UUID().uuidString.prefix(8))",
            threadID: threadID,
            body: trimmed,
            sentAt: Date(),
            isFromCurrentUser: true,
            kind: kind
        )
        var list = messagesByThread[threadID.rawValue] ?? []
        list.append(message)
        messagesByThread[threadID.rawValue] = list
        let preview = kind == .image
            ? String(localized: "messages.preview.image", defaultValue: "[图片]", comment: "Image preview")
            : trimmed
        updatePreview(threadID: threadID, preview: preview, at: message.sentAt)
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

    public func hideThread(threadID: MessageThreadID) async throws {
        guard inbox.allThreads.contains(where: { $0.threadID == threadID }) else {
            throw MessagesError.underlying(.server(statusCode: 404, message: "Thread not found"))
        }
        hiddenThreadIDs.insert(threadID.rawValue)
        hideThreadCallCount += 1
    }

    public func deleteThread(threadID: MessageThreadID) async throws {
        guard inbox.allThreads.contains(where: { $0.threadID == threadID }) else {
            throw MessagesError.underlying(.server(statusCode: 404, message: "Thread not found"))
        }
        deletedThreadIDs.insert(threadID.rawValue)
        hiddenThreadIDs.remove(threadID.rawValue)
        deleteThreadCallCount += 1
        inbox = removingThread(threadID, from: inbox)
        messagesByThread.removeValue(forKey: threadID.rawValue)
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
        let partner = inbox.unmessagedMatches.first(where: { $0.user.id == peerUserID })?.user
            ?? InboxUserProfile(id: peerUserID, displayName: peerDisplayName, avatarURL: nil)
        let graduatedMatches = inbox.unmessagedMatches.filter { $0.user.id != peerUserID }
        var dmConversations = inbox.dmConversations.filter { $0.threadID != threadID }

        let preview = ConversationPreview(
            threadID: threadID,
            kind: .dm,
            displayName: peerDisplayName,
            lastMessagePreview: welcome,
            lastMessageAt: Date(),
            unreadCount: 0,
            dmPartner: partner,
            isPartnerOnline: false
        )
        dmConversations.insert(preview, at: 0)

        if messagesByThread[threadID.rawValue] == nil {
            messagesByThread[threadID.rawValue] = [
                ChatMessage(
                    id: "msg_welcome_\(threadID.rawValue)",
                    threadID: threadID,
                    body: welcome,
                    sentAt: Date(),
                    isFromCurrentUser: false
                )
            ]
        }

        inbox = MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: graduatedMatches,
            dmConversations: dmConversations,
            activeGroupChats: inbox.activeGroupChats,
            archivedGroupChats: inbox.archivedGroupChats
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

    private func visibleInbox() -> MessagesInbox {
        let dm = inbox.dmConversations.filter { isThreadVisible($0.threadID) }
        let groups = inbox.activeGroupChats.filter { isThreadVisible($0.threadID) }
        let archived = inbox.archivedGroupChats.filter { isThreadVisible($0.threadID) }
        let matches = inbox.unmessagedMatches.filter {
            isThreadVisible(MessagesInboxSorting.pendingMatchThreadID(for: $0))
        }
        return MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: matches,
            dmConversations: dm,
            activeGroupChats: groups,
            archivedGroupChats: archived
        )
    }

    private func isThreadVisible(_ threadID: MessageThreadID) -> Bool {
        !hiddenThreadIDs.contains(threadID.rawValue) && !deletedThreadIDs.contains(threadID.rawValue)
    }

    private func removingThread(_ threadID: MessageThreadID, from inbox: MessagesInbox) -> MessagesInbox {
        MessagesInbox(
            actionItems: inbox.actionItems,
            unmessagedMatches: inbox.unmessagedMatches.filter {
                MessagesInboxSorting.pendingMatchThreadID(for: $0) != threadID
            },
            dmConversations: inbox.dmConversations.filter { $0.threadID != threadID },
            activeGroupChats: inbox.activeGroupChats.filter { $0.threadID != threadID },
            archivedGroupChats: inbox.archivedGroupChats.filter { $0.threadID != threadID }
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

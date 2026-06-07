// Module: SparkMessages — Unified inbox state with three sections.

import Foundation
import Observation
import SparkCore

@MainActor
@Observable
public final class MessagesViewModel {
    private static let logger = SparkLog.logger(category: "Messages.ViewModel")

    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    public private(set) var actionItems: [ActionItem] = []
    public private(set) var unmessagedMatches: [MatchPreview] = []
    public private(set) var dmConversations: [ConversationPreview] = []
    public private(set) var activeGroupChats: [ConversationPreview] = []
    public private(set) var archivedGroupChats: [ConversationPreview] = []
    public private(set) var threads: [MessageThread] = []
    public private(set) var unreadMessageCount: Int = 0
    public private(set) var loadState: LoadState = .idle

    public var dmUnreadCount: Int {
        dmConversations.reduce(0) { $0 + $1.unreadCount }
    }

    public var groupUnreadCount: Int {
        activeGroupChats.reduce(0) { $0 + $1.unreadCount }
    }

    public var totalUnreadCount: Int {
        actionItems.count + dmUnreadCount + groupUnreadCount
    }

    /// Tab badge hides at zero per HIG.
    public var tabBadge: Int? {
        let count = totalUnreadCount
        return count > 0 ? count : nil
    }

    private let makeConversationViewModel: @MainActor (MessageThread) -> ConversationViewModel
    private let fetchInbox: any FetchInboxUseCaseProtocol
    private let markAllRead: any MarkMessagesReadUseCaseProtocol
    private let markThreadRead: any MarkThreadReadUseCaseProtocol
    private let respondToInvite: any RespondToActivityInviteUseCaseProtocol
    private let dismissActionItemUseCase: any DismissActionItemUseCaseProtocol
    private let ensureDirectMessageThreadUseCase: any EnsureDirectMessageThreadUseCaseProtocol

    public init(
        useCases: MessagesInboxUseCases,
        makeConversationViewModel: @escaping @MainActor (MessageThread) -> ConversationViewModel
    ) {
        self.makeConversationViewModel = makeConversationViewModel
        fetchInbox = useCases.fetchInbox
        markAllRead = useCases.markAllRead
        markThreadRead = useCases.markThreadRead
        respondToInvite = useCases.respondToInvite
        dismissActionItemUseCase = useCases.dismissActionItem
        ensureDirectMessageThreadUseCase = useCases.ensureDirectMessageThread
    }

    public convenience init(coordinator: MessagesCoordinator) {
        self.init(
            useCases: coordinator.makeInboxUseCases(),
            makeConversationViewModel: { thread in
                coordinator.makeConversationViewModel(thread: thread)
            }
        )
    }

    public convenience init(repository: any MessagesRepository) {
        self.init(coordinator: MessagesCoordinator(repository: repository))
    }

    public func conversationViewModel(for thread: MessageThread) -> ConversationViewModel {
        makeConversationViewModel(thread)
    }

    public func conversationViewModel(for conversation: ConversationPreview) -> ConversationViewModel {
        makeConversationViewModel(conversation.asMessageThread())
    }

    public func thread(for threadID: MessageThreadID) -> MessageThread? {
        threads.first { $0.threadID == threadID }
    }

    public func load() async {
        loadState = .loading
        do {
            let inbox = try await fetchInbox()
            apply(inbox)
            loadState = inbox.isCompletelyEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("load inbox failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            Self.logger.error("load inbox failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.localizedDescription)
        }
    }

    /// Clears unread badge for one conversation (optimistic UI, syncs via per-thread read API).
    public func markConversationRead(_ conversation: ConversationPreview) async {
        guard conversation.hasUnread else { return }
        let threadID = conversation.threadID
        let snapshot = conversationReadSnapshot()
        applyConversationRead(threadID)
        do {
            try await markThreadRead(threadID: threadID)
        } catch is CancellationError {
            return
        } catch {
            restoreConversationRead(snapshot)
            Self.logger.error(
                "markConversationRead failed for \(threadID.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    public func conversation(for threadID: MessageThreadID) -> ConversationPreview? {
        if let match = dmConversations.first(where: { $0.threadID == threadID }) {
            return match
        }
        if let match = activeGroupChats.first(where: { $0.threadID == threadID }) {
            return match
        }
        return archivedGroupChats.first { $0.threadID == threadID }
    }

    public func markMessagesRead() async {
        do {
            try await markAllRead()
            dmConversations = dmConversations.map(clearUnread)
            activeGroupChats = activeGroupChats.map(clearUnread)
            archivedGroupChats = archivedGroupChats.map(clearUnread)
            threads = threads.map { thread in
                MessageThread(
                    threadID: thread.threadID,
                    peerDisplayName: thread.peerDisplayName,
                    lastMessagePreview: thread.lastMessagePreview,
                    lastActivityAt: thread.lastActivityAt,
                    unreadCount: 0
                )
            }
            unreadMessageCount = actionItems.count
        } catch is CancellationError {
            return
        } catch {
            Self.logger.error("markMessagesRead failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.localizedDescription)
        }
    }

    public func handleInviteResponse(invite: ActivityInvite, accept: Bool) async {
        do {
            try await respondToInvite(
                activityID: invite.activity.id,
                invitationID: invite.id,
                accept: accept
            )
            actionItems = actionItems.filter { item in
                if case .activityInvite(let value) = item.kind {
                    return value.id != invite.id
                }
                return true
            }
            unreadMessageCount = totalUnreadCount
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("invite response failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            Self.logger.error("invite response failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.localizedDescription)
        }
    }

    public func dismissActionItem(id: String) async {
        do {
            try await dismissActionItemUseCase(actionItemID: id)
            actionItems = actionItems.filter { $0.id != id }
            unreadMessageCount = totalUnreadCount
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("dismiss action item failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            Self.logger.error("dismiss action item failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.localizedDescription)
        }
    }

    public func ensureDirectMessageThread(for match: MatchPreview) async throws -> MessageThreadID {
        try await ensureDirectMessageThreadUseCase(
            peerUserID: match.user.id,
            peerDisplayName: match.user.displayName
        )
    }

    private func apply(_ inbox: MessagesInbox) {
        actionItems = inbox.actionItems
        unmessagedMatches = inbox.unmessagedMatches
        dmConversations = MessagesInboxSorting.dmConversations(inbox.dmConversations)
        activeGroupChats = MessagesInboxSorting.activeGroupChats(inbox.activeGroupChats)
        archivedGroupChats = inbox.archivedGroupChats
        threads = inbox.allThreads.sorted { $0.lastActivityAt > $1.lastActivityAt }
        unreadMessageCount = totalUnreadCount
    }

    private struct ConversationReadSnapshot {
        let dmConversations: [ConversationPreview]
        let activeGroupChats: [ConversationPreview]
        let archivedGroupChats: [ConversationPreview]
        let threads: [MessageThread]
        let unreadMessageCount: Int
    }

    private func conversationReadSnapshot() -> ConversationReadSnapshot {
        ConversationReadSnapshot(
            dmConversations: dmConversations,
            activeGroupChats: activeGroupChats,
            archivedGroupChats: archivedGroupChats,
            threads: threads,
            unreadMessageCount: unreadMessageCount
        )
    }

    private func restoreConversationRead(_ snapshot: ConversationReadSnapshot) {
        dmConversations = snapshot.dmConversations
        activeGroupChats = snapshot.activeGroupChats
        archivedGroupChats = snapshot.archivedGroupChats
        threads = snapshot.threads
        unreadMessageCount = snapshot.unreadMessageCount
    }

    private func applyConversationRead(_ threadID: MessageThreadID) {
        dmConversations = dmConversations.map { $0.threadID == threadID ? clearUnread($0) : $0 }
        activeGroupChats = activeGroupChats.map { $0.threadID == threadID ? clearUnread($0) : $0 }
        archivedGroupChats = archivedGroupChats.map { $0.threadID == threadID ? clearUnread($0) : $0 }
        threads = threads.map { thread in
            guard thread.threadID == threadID else { return thread }
            return MessageThread(
                threadID: thread.threadID,
                peerDisplayName: thread.peerDisplayName,
                lastMessagePreview: thread.lastMessagePreview,
                lastActivityAt: thread.lastActivityAt,
                unreadCount: 0
            )
        }
        unreadMessageCount = totalUnreadCount
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

}

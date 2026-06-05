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

    private let repository: any MessagesRepository
    private let fetchInbox: FetchInboxUseCase
    private let markAllRead: MarkMessagesReadUseCase
    private let respondToInvite: RespondToActivityInviteUseCase
    private let dismissActionItemUseCase: DismissActionItemUseCase
    private let ensureDirectMessageThreadUseCase: EnsureDirectMessageThreadUseCase

    public init(repository: any MessagesRepository) {
        self.repository = repository
        fetchInbox = FetchInboxUseCase(repository: repository)
        markAllRead = MarkMessagesReadUseCase(repository: repository)
        respondToInvite = RespondToActivityInviteUseCase(repository: repository)
        dismissActionItemUseCase = DismissActionItemUseCase(repository: repository)
        ensureDirectMessageThreadUseCase = EnsureDirectMessageThreadUseCase(repository: repository)
    }

    public func conversationViewModel(for thread: MessageThread) -> ConversationViewModel {
        ConversationViewModel(repository: repository, thread: thread)
    }

    public func conversationViewModel(for conversation: ConversationPreview) -> ConversationViewModel {
        ConversationViewModel(repository: repository, thread: conversation.asMessageThread())
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

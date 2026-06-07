// Module: SparkMessages — Unified inbox state (DM + group chats; action items on Activity tab).

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
        dmUnreadCount + groupUnreadCount
    }

    /// Tab badge hides at zero per HIG.
    public var tabBadge: Int? {
        let count = totalUnreadCount
        return count > 0 ? count : nil
    }

    private let peerDisplayNameStore: PeerDisplayNameStore
    private let makeConversationViewModel: @MainActor (
        MessageThread,
        InboxUserProfile?,
        InboxActivitySummary?
    ) -> ConversationViewModel
    private let fetchInbox: any FetchInboxUseCaseProtocol
    private let markAllRead: any MarkMessagesReadUseCaseProtocol
    private let markThreadRead: any MarkThreadReadUseCaseProtocol
    private let hideThread: any HideThreadUseCaseProtocol
    private let deleteThread: any DeleteThreadUseCaseProtocol
    private let respondToInvite: any RespondToActivityInviteUseCaseProtocol
    private let dismissActionItemUseCase: any DismissActionItemUseCaseProtocol
    private let ensureDirectMessageThreadUseCase: any EnsureDirectMessageThreadUseCaseProtocol

    public init(
        useCases: MessagesInboxUseCases,
        peerDisplayNameStore: PeerDisplayNameStore,
        makeConversationViewModel: @escaping @MainActor (
            MessageThread,
            InboxUserProfile?,
            InboxActivitySummary?
        ) -> ConversationViewModel
    ) {
        self.peerDisplayNameStore = peerDisplayNameStore
        self.makeConversationViewModel = makeConversationViewModel
        fetchInbox = useCases.fetchInbox
        markAllRead = useCases.markAllRead
        markThreadRead = useCases.markThreadRead
        hideThread = useCases.hideThread
        deleteThread = useCases.deleteThread
        respondToInvite = useCases.respondToInvite
        dismissActionItemUseCase = useCases.dismissActionItem
        ensureDirectMessageThreadUseCase = useCases.ensureDirectMessageThread
    }

    public convenience init(
        coordinator: MessagesCoordinator,
        peerDisplayNameStore: PeerDisplayNameStore
    ) {
        self.init(
            useCases: coordinator.makeInboxUseCases(),
            peerDisplayNameStore: peerDisplayNameStore,
            makeConversationViewModel: { thread, dmPartner, groupActivity in
                coordinator.makeConversationViewModel(
                    thread: thread,
                    dmPartner: dmPartner,
                    groupActivity: groupActivity,
                    peerDisplayNameStore: peerDisplayNameStore
                )
            }
        )
    }

    public convenience init(
        repository: any MessagesRepository,
        peerDisplayNameStore: PeerDisplayNameStore = PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
    ) {
        self.init(
            coordinator: MessagesCoordinator(repository: repository),
            peerDisplayNameStore: peerDisplayNameStore
        )
    }

    public func conversationViewModel(for thread: MessageThread) -> ConversationViewModel {
        let conversation = conversation(for: thread.threadID)
        return makeConversationViewModel(
            thread,
            conversation?.dmPartner,
            conversation?.activity
        )
    }

    public func conversationViewModel(for conversation: ConversationPreview) -> ConversationViewModel {
        makeConversationViewModel(
            conversation.asMessageThread(),
            conversation.dmPartner,
            conversation.activity
        )
    }

    /// Re-applies local peer remarks to inbox rows after alias edits.
    public func refreshDisplayNames() {
        dmConversations = dmConversations.map { applyAlias(to: $0) }
        threads = (dmConversations + activeGroupChats)
            .map { $0.asMessageThread() }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    public func thread(for threadID: MessageThreadID) -> MessageThread? {
        threads.first { $0.threadID == threadID }
    }

    public func load() async {
        loadState = .loading
        do {
            let inbox = try await fetchInbox()
            apply(inbox)
            loadState = isInboxEmpty ? .empty : .loaded
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

    /// Hides a conversation from the inbox without deleting history.
    public func hideConversation(_ conversation: ConversationPreview) async {
        let threadID = conversation.threadID
        let snapshot = inboxSnapshot()
        removeConversation(threadID)
        do {
            try await hideThread(threadID: threadID)
        } catch is CancellationError {
            return
        } catch {
            restoreInbox(snapshot)
            Self.logger.error(
                "hideConversation failed for \(threadID.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Permanently deletes a conversation thread for the current user.
    public func deleteConversation(_ conversation: ConversationPreview) async {
        let threadID = conversation.threadID
        let snapshot = inboxSnapshot()
        removeConversation(threadID)
        do {
            try await deleteThread(threadID: threadID)
        } catch is CancellationError {
            return
        } catch {
            restoreInbox(snapshot)
            Self.logger.error(
                "deleteConversation failed for \(threadID.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
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
        return nil
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
            unreadMessageCount = 0
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
        try await ensureDirectMessageThread(
            peerUserID: match.user.id,
            peerDisplayName: match.user.displayName
        )
    }

    public func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        try await ensureDirectMessageThreadUseCase(
            peerUserID: peerUserID,
            peerDisplayName: peerDisplayName
        )
    }

    /// Replaces the synthetic new-match row with a real DM thread after the first open.
    public func graduateMatch(_ match: MatchPreview, to threadID: MessageThreadID) {
        graduateMatch(peerUserID: match.user.id, partner: match.user, to: threadID)
    }

    /// Graduates a peer to a real DM thread when only the user id is known (e.g. new-chat picker).
    public func graduateMatch(peerUserID: String, to threadID: MessageThreadID) {
        let partner = unmessagedMatches.first(where: { $0.user.id == peerUserID })?.user
            ?? InboxUserProfile(id: peerUserID, displayName: "", avatarURL: nil)
        graduateMatch(peerUserID: peerUserID, partner: partner, to: threadID)
    }

    /// Peers available when starting a new chat (unmessaged matches + existing DM partners).
    public func newChatCandidates() -> [MessagesChatCandidate] {
        var seen = Set<String>()
        var results: [MessagesChatCandidate] = []

        for match in unmessagedMatches {
            guard seen.insert(match.user.id).inserted else { continue }
            results.append(
                MessagesChatCandidate(
                    id: match.user.id,
                    displayName: match.user.displayName,
                    avatarURL: match.user.avatarURL,
                    isNewMatch: true
                )
            )
        }

        for conversation in dmConversations where conversation.kind == .dm {
            if let partner = conversation.dmPartner, seen.insert(partner.id).inserted {
                results.append(
                    MessagesChatCandidate(
                        id: partner.id,
                        displayName: partner.displayName,
                        avatarURL: partner.avatarURL,
                        isNewMatch: false
                    )
                )
            }
        }

        return results.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    public func matchPreview(for conversation: ConversationPreview) -> MatchPreview? {
        unmessagedMatches.first {
            MessagesInboxSorting.pendingMatchThreadID(for: $0) == conversation.threadID
        }
    }

    private var isInboxEmpty: Bool {
        dmConversations.isEmpty && activeGroupChats.isEmpty
    }

    private func graduateMatch(peerUserID: String, partner: InboxUserProfile, to threadID: MessageThreadID) {
        unmessagedMatches.removeAll { $0.user.id == peerUserID }

        let welcomePreview = String(
            localized: "likes.dm.welcome",
            defaultValue: "你们互相喜欢，打个招呼吧",
            comment: "DM welcome"
        )
        var persistedDMs = dmConversations.filter {
            !MessagesInboxSorting.isPendingMatchThreadID($0.threadID)
        }

        let nameFallback = partner.displayName.isEmpty
            ? (persistedDMs.first(where: { $0.threadID == threadID })?.displayName ?? partner.id)
            : partner.displayName
        let resolvedName = peerDisplayNameStore.resolvedDisplayName(
            userID: partner.id,
            fallback: nameFallback
        )

        if let index = persistedDMs.firstIndex(where: { $0.threadID == threadID }) {
            let existing = persistedDMs[index]
            persistedDMs[index] = ConversationPreview(
                threadID: threadID,
                kind: .dm,
                displayName: resolvedName,
                lastMessagePreview: existing.lastMessagePreview,
                lastMessageAt: existing.lastMessageAt,
                unreadCount: existing.unreadCount,
                dmPartner: partner,
                isPartnerOnline: existing.isPartnerOnline,
                activity: existing.activity,
                memberCount: existing.memberCount,
                isArchived: existing.isArchived
            )
        } else {
            persistedDMs.insert(
                ConversationPreview(
                    threadID: threadID,
                    kind: .dm,
                    displayName: resolvedName,
                    lastMessagePreview: welcomePreview,
                    lastMessageAt: Date(),
                    unreadCount: 0,
                    dmPartner: partner,
                    isPartnerOnline: false
                ),
                at: 0
            )
        }

        dmConversations = MessagesInboxSorting.unifiedDMConversations(
            matches: unmessagedMatches,
            conversations: persistedDMs
        ).map { applyAlias(to: $0) }
        threads = (dmConversations + activeGroupChats)
            .map { $0.asMessageThread() }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
        unreadMessageCount = totalUnreadCount
    }

    private func apply(_ inbox: MessagesInbox) {
        actionItems = inbox.actionItems
        unmessagedMatches = inbox.unmessagedMatches
        dmConversations = MessagesInboxSorting.unifiedDMConversations(
            matches: inbox.unmessagedMatches,
            conversations: inbox.dmConversations
        ).map { applyAlias(to: $0) }
        activeGroupChats = MessagesInboxSorting.visibleGroupChats(
            inbox.activeGroupChats + inbox.archivedGroupChats
        )
        archivedGroupChats = []
        threads = (dmConversations + activeGroupChats)
            .map { $0.asMessageThread() }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
        unreadMessageCount = totalUnreadCount
    }

    private func applyAlias(to conversation: ConversationPreview) -> ConversationPreview {
        guard conversation.kind == .dm, let partner = conversation.dmPartner else { return conversation }
        let resolved = peerDisplayNameStore.resolvedDisplayName(
            userID: partner.id,
            fallback: partner.displayName
        )
        guard resolved != conversation.displayName else { return conversation }
        return ConversationPreview(
            threadID: conversation.threadID,
            kind: conversation.kind,
            displayName: resolved,
            lastMessagePreview: conversation.lastMessagePreview,
            lastMessageAt: conversation.lastMessageAt,
            unreadCount: conversation.unreadCount,
            dmPartner: conversation.dmPartner,
            isPartnerOnline: conversation.isPartnerOnline,
            activity: conversation.activity,
            memberCount: conversation.memberCount,
            isArchived: conversation.isArchived
        )
    }

    private struct ConversationReadSnapshot {
        let dmConversations: [ConversationPreview]
        let activeGroupChats: [ConversationPreview]
        let archivedGroupChats: [ConversationPreview]
        let threads: [MessageThread]
        let unreadMessageCount: Int
    }

    private struct InboxSnapshot {
        let actionItems: [ActionItem]
        let unmessagedMatches: [MatchPreview]
        let dmConversations: [ConversationPreview]
        let activeGroupChats: [ConversationPreview]
        let archivedGroupChats: [ConversationPreview]
        let threads: [MessageThread]
        let unreadMessageCount: Int
        let loadState: LoadState
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

    private func inboxSnapshot() -> InboxSnapshot {
        InboxSnapshot(
            actionItems: actionItems,
            unmessagedMatches: unmessagedMatches,
            dmConversations: dmConversations,
            activeGroupChats: activeGroupChats,
            archivedGroupChats: archivedGroupChats,
            threads: threads,
            unreadMessageCount: unreadMessageCount,
            loadState: loadState
        )
    }

    private func restoreInbox(_ snapshot: InboxSnapshot) {
        actionItems = snapshot.actionItems
        unmessagedMatches = snapshot.unmessagedMatches
        dmConversations = snapshot.dmConversations
        activeGroupChats = snapshot.activeGroupChats
        archivedGroupChats = snapshot.archivedGroupChats
        threads = snapshot.threads
        unreadMessageCount = snapshot.unreadMessageCount
        loadState = snapshot.loadState
    }

    private func removeConversation(_ threadID: MessageThreadID) {
        dmConversations.removeAll { $0.threadID == threadID }
        activeGroupChats.removeAll { $0.threadID == threadID }
        archivedGroupChats.removeAll { $0.threadID == threadID }
        unmessagedMatches.removeAll {
            MessagesInboxSorting.pendingMatchThreadID(for: $0) == threadID
        }
        threads.removeAll { $0.threadID == threadID }
        unreadMessageCount = totalUnreadCount
        if isInboxEmpty {
            loadState = .empty
        }
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

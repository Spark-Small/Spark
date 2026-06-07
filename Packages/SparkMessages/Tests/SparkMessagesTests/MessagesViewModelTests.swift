// Module: SparkMessagesTests

import Foundation
import SparkMessages
import Testing

@MainActor
struct MessagesViewModelTests {
    @Test func loadSetsInboxSectionsFromRepository() async {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        #expect(viewModel.actionItems.count == 3)
        #expect(viewModel.dmConversations.count == 3)
        #expect(viewModel.unmessagedMatches.count == 2)
        #expect(viewModel.activeGroupChats.count == 2)
        #expect(viewModel.archivedGroupChats.isEmpty)
        #expect(viewModel.threads.count == 5)
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.totalUnreadCount > 0)
    }

    @Test func markConversationReadClearsSingleThreadBadge() async throws {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        let conversation = try #require(viewModel.dmConversations.first)
        let unreadBefore = viewModel.dmUnreadCount
        #expect(conversation.hasUnread)
        await viewModel.markConversationRead(conversation)
        #expect(viewModel.dmUnreadCount == unreadBefore - conversation.unreadCount)
        #expect(viewModel.conversation(for: conversation.threadID)?.hasUnread == false)
        #expect(await repository.markThreadReadCallCount == 1)
    }

    @Test func markMessagesReadClearsConversationBadges() async {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        await viewModel.markMessagesRead()
        #expect(viewModel.dmUnreadCount == 0)
        #expect(viewModel.groupUnreadCount == 0)
        #expect(viewModel.unreadMessageCount == 0)
        #expect(viewModel.threads.allSatisfy { $0.unreadCount == 0 })
        #expect(await repository.markReadCallCount == 1)
        #expect(viewModel.actionItems.count == 3)
    }

    @Test func newChatCandidatesIncludesMatchesAndExistingPartners() async {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3))
        await viewModel.load()
        let candidates = viewModel.newChatCandidates()
        #expect(!candidates.isEmpty)
        #expect(candidates.contains { $0.isNewMatch })
        #expect(candidates.contains { !$0.isNewMatch })
    }

    @Test func ensureDirectMessageThreadByPeerIDReturnsThread() async throws {
        let repository = MockMessagesRepository(unreadCount: 1)
        let viewModel = MessagesViewModel(repository: repository)
        let threadID = try await viewModel.ensureDirectMessageThread(
            peerUserID: "u_like_9",
            peerDisplayName: "Nova"
        )
        #expect(threadID.rawValue == "th_dm_u_like_9")
    }

    @Test func graduateMatchRemovesPendingPreviewAfterOpeningDM() async throws {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3))
        await viewModel.load()
        let match = try #require(viewModel.unmessagedMatches.first)
        let pendingPreview = String(
            localized: "messages.match.new.preview",
            defaultValue: "新配对，打个招呼",
            comment: "New match row preview"
        )
        #expect(
            viewModel.dmConversations.contains {
                viewModel.matchPreview(for: $0)?.id == match.id
            }
        )

        let threadID = try await viewModel.ensureDirectMessageThread(for: match)
        viewModel.graduateMatch(match, to: threadID)

        #expect(viewModel.unmessagedMatches.contains { $0.id == match.id } == false)
        #expect(
            viewModel.dmConversations.contains {
                viewModel.matchPreview(for: $0) != nil
            } == false
        )
        let conversation = try #require(viewModel.conversation(for: threadID))
        #expect(conversation.lastMessagePreview != pendingPreview)
        #expect(conversation.dmPartner?.id == match.user.id)
    }

    @Test func unifiedDMListIncludesUnmessagedMatches() async {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3))
        await viewModel.load()
        guard let pendingMatch = viewModel.unmessagedMatches.first else {
            Issue.record("Expected unmessaged match in mock inbox")
            return
        }
        let pendingRow = viewModel.dmConversations.first { conversation in
            viewModel.matchPreview(for: conversation)?.id == pendingMatch.id
        }
        #expect(pendingRow != nil)
    }

    @Test func threadLookupReturnsMatchingThread() async {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository())
        await viewModel.load()
        let thread = viewModel.thread(for: MessageThreadID("th_activity_act_1"))
        #expect(thread?.peerDisplayName.contains("徒步") == true)
    }

    @Test func tabBadgeMatchesTotalUnreadCount() async {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3))
        await viewModel.load()
        #expect(viewModel.tabBadge == viewModel.totalUnreadCount)
        #expect(viewModel.tabBadge != nil)
    }

    @Test func refreshDisplayNamesAppliesPeerRemark() async throws {
        let store = PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
        let viewModel = MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3), peerDisplayNameStore: store)
        await viewModel.load()
        let conversation = try #require(viewModel.dmConversations.first { $0.dmPartner != nil })
        let partnerID = try #require(conversation.dmPartner?.id)
        store.setAlias("备注名", for: partnerID)
        viewModel.refreshDisplayNames()
        let refreshed = try #require(viewModel.dmConversations.first { $0.threadID == conversation.threadID })
        #expect(refreshed.displayName == "备注名")
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = MessagesViewModel(repository: FailingMessagesRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Inbox unavailable"))
    }

    @Test func hideConversationRemovesRowAndCallsRepository() async {
        let repository = MockMessagesRepository(unreadCount: 3)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        guard let conversation = viewModel.dmConversations.first(where: { $0.hasUnread }) else {
            Issue.record("Expected unread DM conversation")
            return
        }
        let beforeCount = viewModel.dmConversations.count
        await viewModel.hideConversation(conversation)
        #expect(viewModel.dmConversations.count == beforeCount - 1)
        #expect(await repository.hideThreadCallCount == 1)
    }

    @Test func deleteConversationRemovesRowAndCallsRepository() async {
        let repository = MockMessagesRepository(unreadCount: 3)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        guard let conversation = viewModel.dmConversations.first else {
            Issue.record("Expected DM conversation")
            return
        }
        let threadID = conversation.threadID
        await viewModel.deleteConversation(conversation)
        #expect(viewModel.conversation(for: threadID) == nil)
        #expect(await repository.deleteThreadCallCount == 1)
    }

    @Test func dismissActionItemRemovesCardAndCallsRepository() async {
        let repository = MockMessagesRepository(unreadCount: 3)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        let before = viewModel.actionItems.count
        await viewModel.dismissActionItem(id: "action_change_1")
        #expect(viewModel.actionItems.count == before - 1)
        #expect(viewModel.actionItems.contains { $0.id == "action_change_1" } == false)
        #expect(await repository.dismissActionItemCallCount == 1)
    }

    @Test func handleInviteDeclineRemovesInviteActionItem() async throws {
        let repository = MockMessagesRepository(unreadCount: 3)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        let inviteItem = try #require(viewModel.actionItems.first { item in
            if case .activityInvite = item.kind { return true }
            return false
        })
        guard case .activityInvite(let invite) = inviteItem.kind else {
            Issue.record("Expected activity invite action item")
            return
        }
        await viewModel.handleInviteResponse(invite: invite, accept: false)
        #expect(viewModel.actionItems.contains { $0.id == inviteItem.id } == false)
    }
}

private struct FailingMessagesRepository: MessagesRepository, Sendable {
    struct TestError: LocalizedError {
        var errorDescription: String? { "Inbox unavailable" }
    }

    func fetchUnreadCount() async throws -> Int { throw TestError() }
    func fetchThreads() async throws -> [MessageThread] { throw TestError() }
    func fetchInbox() async throws -> MessagesInbox { throw TestError() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { throw TestError() }
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext {
        throw TestError()
    }
    func sendMessage(threadID: MessageThreadID, body: String, kind: ChatMessageKind = .text) async throws -> ChatMessage { throw TestError() }
    func markAllRead() async throws { throw TestError() }
    func markThreadRead(threadID: MessageThreadID) async throws { throw TestError() }
    func hideThread(threadID: MessageThreadID) async throws { throw TestError() }
    func deleteThread(threadID: MessageThreadID) async throws { throw TestError() }
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {
        throw TestError()
    }
    func dismissInboxActionItem(id: String) async throws {
        throw TestError()
    }
    func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        throw TestError()
    }

    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        throw TestError()
    }
}

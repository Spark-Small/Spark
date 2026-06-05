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
        #expect(viewModel.unmessagedMatches.count == 2)
        #expect(viewModel.dmConversations.count == 1)
        #expect(viewModel.activeGroupChats.count == 2)
        #expect(viewModel.archivedGroupChats.count == 1)
        #expect(viewModel.threads.count == 4)
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

    @Test func markMessagesReadClearsConversationBadgesButKeepsActionItems() async {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        let actionCount = viewModel.actionItems.count
        await viewModel.markMessagesRead()
        #expect(viewModel.dmUnreadCount == 0)
        #expect(viewModel.groupUnreadCount == 0)
        #expect(viewModel.unreadMessageCount == actionCount)
        #expect(viewModel.threads.allSatisfy { $0.unreadCount == 0 })
        #expect(await repository.markReadCallCount == 1)
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

    @Test func loadFailureSetsFailureState() async {
        let viewModel = MessagesViewModel(repository: FailingMessagesRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Inbox unavailable"))
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
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage { throw TestError() }
    func markAllRead() async throws { throw TestError() }
    func markThreadRead(threadID: MessageThreadID) async throws { throw TestError() }
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

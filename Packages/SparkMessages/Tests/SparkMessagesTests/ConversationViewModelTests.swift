// Module: SparkMessagesTests

import Foundation
import SparkMessages
import Testing

@MainActor
struct ConversationViewModelTests {
    @Test func loadFetchesMessages() async throws {
        let repository = MockMessagesRepository(unreadCount: 2)
        let threads = try await repository.fetchThreads()
        let thread = try #require(threads.first)
        let viewModel = ConversationViewModel(repository: repository, thread: thread)
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(!viewModel.messages.isEmpty)
    }

    @Test func sendAppendsMessageAndClearsDraft() async throws {
        let repository = MockMessagesRepository(unreadCount: 1)
        let threads = try await repository.fetchThreads()
        let thread = try #require(threads.first)
        let viewModel = ConversationViewModel(repository: repository, thread: thread)
        await viewModel.load()
        let initialCount = viewModel.messages.count
        viewModel.draftText = "See you there"
        await viewModel.sendTapped()
        #expect(viewModel.messages.count == initialCount + 1)
        #expect(viewModel.draftText.isEmpty)
        #expect(viewModel.messages.last?.isFromCurrentUser == true)
    }

    @Test func sendFailureKeepsLoadedStateAndSurfacesError() async throws {
        let repository = FailingSendMessagesRepository()
        let thread = MessageThread(
            threadID: MessageThreadID("th_dm_u_like_1"),
            peerDisplayName: "Test",
            lastMessagePreview: "Hi",
            lastActivityAt: .now,
            unreadCount: 0
        )
        let viewModel = ConversationViewModel(repository: repository, thread: thread)
        await viewModel.load()
        viewModel.draftText = "Hello"
        await viewModel.sendTapped()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.sendErrorMessage == "Send failed")
        #expect(viewModel.draftText == "Hello")
    }

    @Test func sendRejectsOverlongMessageWithoutNetworkCall() async throws {
        let repository = MockMessagesRepository(unreadCount: 1)
        let threads = try await repository.fetchThreads()
        let thread = try #require(threads.first)
        let viewModel = ConversationViewModel(repository: repository, thread: thread)
        await viewModel.load()
        let initialCount = viewModel.messages.count
        viewModel.draftText = String(repeating: "a", count: 2001)
        await viewModel.sendTapped()
        #expect(viewModel.messages.count == initialCount)
        #expect(viewModel.sendErrorMessage != nil)
    }
}

private struct FailingSendMessagesRepository: MessagesRepository, Sendable {
    struct SendFailure: LocalizedError {
        var errorDescription: String? { "Send failed" }
    }

    func fetchUnreadCount() async throws -> Int { 0 }
    func fetchThreads() async throws -> [MessageThread] { [] }
    func fetchInbox() async throws -> MessagesInbox { MessagesInbox() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { [] }
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext {
        ConversationContext(sharedActivities: [], relationshipStatus: "none")
    }
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage { throw SendFailure() }
    func markAllRead() async throws {}
    func markThreadRead(threadID: MessageThreadID) async throws {}
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {}
    func dismissInboxActionItem(id: String) async throws {}
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {}
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        MessageThreadID("th_dm_test")
    }
}

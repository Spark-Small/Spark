// Module: SparkMessagesTests — Messages use case coverage.

@testable import SparkMessages
import Testing

struct MessagesUseCaseTests {
    @Test func fetchInboxUseCaseReturnsSections() async throws {
        let useCase = FetchInboxUseCase(repository: MockMessagesRepository())
        let inbox = try await useCase()
        #expect(!inbox.actionItems.isEmpty)
        #expect(!inbox.dmConversations.isEmpty)
    }

    @Test func fetchThreadMessagesUseCaseReturnsMessages() async throws {
        let repository = MockMessagesRepository()
        let threads = try await repository.fetchThreads()
        let threadID = try #require(threads.first?.threadID)
        let useCase = FetchThreadMessagesUseCase(repository: repository)
        let messages = try await useCase(threadID: threadID)
        #expect(!messages.isEmpty)
    }

    @Test func dismissActionItemUseCaseRemovesItem() async throws {
        let repository = MockMessagesRepository()
        let useCase = DismissActionItemUseCase(repository: repository)
        try await useCase(actionItemID: "action_change_1")
        let inbox = try await FetchInboxUseCase(repository: repository)()
        #expect(inbox.actionItems.contains { $0.id == "action_change_1" } == false)
    }

    @Test func sendThreadMessageUseCaseAppendsMessage() async throws {
        let repository = MockMessagesRepository()
        let threads = try await repository.fetchThreads()
        let threadID = try #require(threads.first?.threadID)
        let useCase = SendThreadMessageUseCase(repository: repository)
        let message = try await useCase(threadID: threadID, body: "Hello")
        #expect(message.body == "Hello")
    }

    @Test func fetchUnreadCountUseCaseReturnsCount() async throws {
        let useCase = FetchUnreadCountUseCase(repository: MockMessagesRepository())
        let count = try await useCase()
        #expect(count >= 0)
    }

    @Test func fetchMessageThreadsUseCaseReturnsThreads() async throws {
        let useCase = FetchMessageThreadsUseCase(repository: MockMessagesRepository())
        let threads = try await useCase()
        #expect(!threads.isEmpty)
    }

    @Test func markMessagesReadUseCaseClearsUnread() async throws {
        let repository = MockMessagesRepository()
        let useCase = MarkMessagesReadUseCase(repository: repository)
        try await useCase()
        #expect(await repository.markReadCallCount == 1)
    }

    @Test func markThreadReadUseCaseClearsThreadUnread() async throws {
        let repository = MockMessagesRepository()
        let threads = try await repository.fetchThreads()
        let threadID = try #require(threads.first?.threadID)
        try await MarkThreadReadUseCase(repository: repository)(threadID: threadID)
        #expect(await repository.markThreadReadCallCount == 1)
    }

    @Test func fetchConversationContextUseCaseReturnsContext() async throws {
        let repository = MockMessagesRepository()
        let threads = try await repository.fetchThreads()
        let threadID = try #require(threads.first?.threadID)
        let context = try await FetchConversationContextUseCase(repository: repository)(threadID: threadID)
        #expect(context.relationshipStatus.isEmpty == false)
    }

    @Test func ensureDirectMessageThreadUseCaseReturnsThreadID() async throws {
        let useCase = EnsureDirectMessageThreadUseCase(repository: MockMessagesRepository())
        let threadID = try await useCase(peerUserID: "u_like_2", peerDisplayName: "Alex")
        #expect(threadID.rawValue.isEmpty == false)
    }

    @Test func respondToActivityInviteUseCaseUpdatesInbox() async throws {
        let repository = MockMessagesRepository()
        let inbox = try await repository.fetchInbox()
        let inviteItem = try #require(inbox.actionItems.first {
            if case .activityInvite = $0.kind { return true }
            return false
        })
        guard case .activityInvite(let invite) = inviteItem.kind else {
            Issue.record("Expected activity invite action item")
            return
        }
        try await RespondToActivityInviteUseCase(repository: repository)(
            activityID: invite.activity.id,
            invitationID: invite.id,
            accept: true
        )
        let updated = try await FetchInboxUseCase(repository: repository)()
        #expect(updated.actionItems.contains { $0.id == inviteItem.id } == false)
    }
}

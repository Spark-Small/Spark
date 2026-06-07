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
}

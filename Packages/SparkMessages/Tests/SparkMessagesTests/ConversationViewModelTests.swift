// Module: SparkMessagesTests

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
}

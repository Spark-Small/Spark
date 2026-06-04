// Module: SparkMessagesTests

import Foundation
import SparkMessages
import Testing

@MainActor
struct MessagesViewModelTests {
    @Test func loadSetsThreadsAndUnreadFromRepository() async {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        #expect(viewModel.unreadMessageCount == 5)
        #expect(viewModel.threads.count == 2)
        #expect(viewModel.loadState == .loaded)
    }

    @Test func markMessagesReadClearsCountAndThreadBadges() async {
        let repository = MockMessagesRepository(unreadCount: 5)
        let viewModel = MessagesViewModel(repository: repository)
        await viewModel.load()
        await viewModel.markMessagesRead()
        #expect(viewModel.unreadMessageCount == 0)
        #expect(viewModel.threads.allSatisfy { $0.unreadCount == 0 })
        #expect(await repository.markReadCallCount == 1)
    }

    @Test func threadLookupReturnsMatchingThread() async {
        let viewModel = MessagesViewModel(repository: MockMessagesRepository())
        await viewModel.load()
        let thread = viewModel.thread(for: MessageThreadID("th_activity_act_1"))
        #expect(thread?.peerDisplayName == "周末徒步 · 群")
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = MessagesViewModel(repository: FailingMessagesRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Inbox unavailable"))
    }
}

private struct FailingMessagesRepository: MessagesRepository, Sendable {
    struct TestError: LocalizedError {
        var errorDescription: String? { "Inbox unavailable" }
    }

    func fetchUnreadCount() async throws -> Int { throw TestError() }
    func fetchThreads() async throws -> [MessageThread] { throw TestError() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { throw TestError() }
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage { throw TestError() }
    func markAllRead() async throws { throw TestError() }
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

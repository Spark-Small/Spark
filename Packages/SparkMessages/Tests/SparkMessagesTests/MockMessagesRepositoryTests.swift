// Module: SparkMessagesTests

import SparkMessages
import Testing

struct MockMessagesRepositoryTests {
    @Test func fetchThreadsReturnsSortedByActivity() async throws {
        let repository = MockMessagesRepository(unreadCount: 3)
        let threads = try await repository.fetchThreads()
        #expect(threads.count == 4)
        #expect(threads == threads.sorted { $0.lastActivityAt > $1.lastActivityAt })
    }

    @Test func sendMessageUpdatesThreadPreview() async throws {
        let repository = MockMessagesRepository(unreadCount: 0)
        let threadID = MessageThreadID("th_activity_act_1")
        _ = try await repository.sendMessage(threadID: threadID, body: "New preview text")
        let threads = try await repository.fetchThreads()
        let thread = try #require(threads.first { $0.threadID == threadID })
        #expect(thread.lastMessagePreview == "New preview text")
    }

    @Test func ensureActivityGroupThreadAddsCoffeeChatGroup() async throws {
        let repository = MockMessagesRepository(unreadCount: 0)
        let threadID = MessageThreadID("th_activity_act_2")
        try await repository.ensureActivityGroupThread(
            threadID: threadID,
            displayName: "咖啡聊天局 · 群",
            welcomeMessage: "欢迎加入"
        )
        let threads = try await repository.fetchThreads()
        #expect(threads.count == 5)
        #expect(threads.contains { $0.threadID == threadID })
        let messages = try await repository.fetchMessages(threadID: threadID)
        #expect(messages.isEmpty == false)
    }

    @Test func dismissActionItemPersistsAcrossFetchInbox() async throws {
        let repository = MockMessagesRepository(unreadCount: 0)
        let before = try await repository.fetchInbox()
        #expect(before.actionItems.contains { $0.id == "action_change_1" })
        try await repository.dismissInboxActionItem(id: "action_change_1")
        let after = try await repository.fetchInbox()
        #expect(after.actionItems.contains { $0.id == "action_change_1" } == false)
    }
}

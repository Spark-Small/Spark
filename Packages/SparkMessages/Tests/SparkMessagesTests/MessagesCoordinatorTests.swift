// Module: SparkMessagesTests — Messages coordinator coverage.

@testable import SparkMessages
import Testing

@MainActor
struct MessagesCoordinatorTests {
    @Test func coordinatorBuildsInboxAndConversationViewModels() {
        let coordinator = MessagesCoordinator(repository: MockMessagesRepository(unreadCount: 2))
        let store = PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
        let inbox = coordinator.makeInboxViewModel(peerDisplayNameStore: store)
        #expect(inbox.loadState == .idle)

        let thread = MessageThread(
            threadID: MessageThreadID("th_dm_u_like_1"),
            peerDisplayName: "Alex",
            lastMessagePreview: "Hi",
            lastActivityAt: .now,
            unreadCount: 1
        )
        let conversation = coordinator.makeConversationViewModel(
            thread: thread,
            peerDisplayNameStore: store
        )
        #expect(conversation.thread.threadID == thread.threadID)
    }
}

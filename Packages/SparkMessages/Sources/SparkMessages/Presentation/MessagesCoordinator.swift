// Module: SparkMessages — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct MessagesCoordinator: Sendable {
    private let repository: any MessagesRepository

    public init(repository: any MessagesRepository) {
        self.repository = repository
    }

    @MainActor
    public func makeInboxViewModel() -> MessagesViewModel {
        MessagesViewModel(
            useCases: makeInboxUseCases(),
            makeConversationViewModel: { [self] thread in
                makeConversationViewModel(thread: thread)
            }
        )
    }

    @MainActor
    public func makeConversationViewModel(thread: MessageThread) -> ConversationViewModel {
        ConversationViewModel(
            fetchMessages: FetchThreadMessagesUseCase(repository: repository),
            fetchContext: FetchConversationContextUseCase(repository: repository),
            sendMessage: SendThreadMessageUseCase(repository: repository),
            thread: thread
        )
    }

    @MainActor
    public func makeConversationViewModel(conversation: ConversationPreview) -> ConversationViewModel {
        makeConversationViewModel(thread: conversation.asMessageThread())
    }

    /// Cross-tab: open DM after match, optionally seeding the first message.
    public func openMatchConversation(
        peerUserID: String,
        peerDisplayName: String,
        fallbackThreadID: String,
        initialMessage: String?
    ) async -> String {
        let ensureThread = EnsureDirectMessageThreadUseCase(repository: repository)
        let sendMessage = SendThreadMessageUseCase(repository: repository)
        let resolvedThread = try? await ensureThread(
            peerUserID: peerUserID,
            peerDisplayName: peerDisplayName
        )
        let thread = (resolvedThread ?? MessageThreadID(fallbackThreadID)).rawValue
        if let initialMessage, !initialMessage.isEmpty {
            _ = try? await sendMessage(threadID: MessageThreadID(thread), body: initialMessage)
        }
        return thread
    }

    public func sendMessage(threadID: MessageThreadID, body: String) async throws {
        _ = try await SendThreadMessageUseCase(repository: repository)(threadID: threadID, body: body)
    }

    public func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        try await repository.ensureActivityGroupThread(
            threadID: threadID,
            displayName: displayName,
            welcomeMessage: welcomeMessage
        )
    }

    func makeInboxUseCases() -> MessagesInboxUseCases {
        MessagesInboxUseCases(
            fetchInbox: FetchInboxUseCase(repository: repository),
            markAllRead: MarkMessagesReadUseCase(repository: repository),
            markThreadRead: MarkThreadReadUseCase(repository: repository),
            respondToInvite: RespondToActivityInviteUseCase(repository: repository),
            dismissActionItem: DismissActionItemUseCase(repository: repository),
            ensureDirectMessageThread: EnsureDirectMessageThreadUseCase(repository: repository)
        )
    }
}

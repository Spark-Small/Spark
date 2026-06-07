// Module: SparkMessages — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchInboxUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> MessagesInbox
}

public protocol MarkMessagesReadUseCaseProtocol: Sendable {
    func callAsFunction() async throws
}

public protocol MarkThreadReadUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID) async throws
}

public protocol HideThreadUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID) async throws
}

public protocol DeleteThreadUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID) async throws
}

public protocol RespondToActivityInviteUseCaseProtocol: Sendable {
    func callAsFunction(activityID: String, invitationID: String, accept: Bool) async throws
}

public protocol DismissActionItemUseCaseProtocol: Sendable {
    func callAsFunction(actionItemID: String) async throws
}

public protocol EnsureDirectMessageThreadUseCaseProtocol: Sendable {
    func callAsFunction(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID
}

public protocol FetchThreadMessagesUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID) async throws -> [ChatMessage]
}

public protocol FetchConversationContextUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID) async throws -> ConversationContext
}

public protocol SendThreadMessageUseCaseProtocol: Sendable {
    func callAsFunction(threadID: MessageThreadID, body: String, kind: ChatMessageKind) async throws -> ChatMessage
}

extension FetchInboxUseCase: FetchInboxUseCaseProtocol {}
extension MarkMessagesReadUseCase: MarkMessagesReadUseCaseProtocol {}
extension MarkThreadReadUseCase: MarkThreadReadUseCaseProtocol {}
extension HideThreadUseCase: HideThreadUseCaseProtocol {}
extension DeleteThreadUseCase: DeleteThreadUseCaseProtocol {}
extension RespondToActivityInviteUseCase: RespondToActivityInviteUseCaseProtocol {}
extension DismissActionItemUseCase: DismissActionItemUseCaseProtocol {}
extension EnsureDirectMessageThreadUseCase: EnsureDirectMessageThreadUseCaseProtocol {}
extension FetchThreadMessagesUseCase: FetchThreadMessagesUseCaseProtocol {}
extension FetchConversationContextUseCase: FetchConversationContextUseCaseProtocol {}
extension SendThreadMessageUseCase: SendThreadMessageUseCaseProtocol {}

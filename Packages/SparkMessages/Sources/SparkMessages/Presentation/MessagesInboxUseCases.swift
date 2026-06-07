// Module: SparkMessages — Inbox UseCase bundle for MessagesViewModel injection.

import Foundation

public struct MessagesInboxUseCases: Sendable {
    public let fetchInbox: any FetchInboxUseCaseProtocol
    public let markAllRead: any MarkMessagesReadUseCaseProtocol
    public let markThreadRead: any MarkThreadReadUseCaseProtocol
    public let respondToInvite: any RespondToActivityInviteUseCaseProtocol
    public let dismissActionItem: any DismissActionItemUseCaseProtocol
    public let ensureDirectMessageThread: any EnsureDirectMessageThreadUseCaseProtocol

    public init(
        fetchInbox: any FetchInboxUseCaseProtocol,
        markAllRead: any MarkMessagesReadUseCaseProtocol,
        markThreadRead: any MarkThreadReadUseCaseProtocol,
        respondToInvite: any RespondToActivityInviteUseCaseProtocol,
        dismissActionItem: any DismissActionItemUseCaseProtocol,
        ensureDirectMessageThread: any EnsureDirectMessageThreadUseCaseProtocol
    ) {
        self.fetchInbox = fetchInbox
        self.markAllRead = markAllRead
        self.markThreadRead = markThreadRead
        self.respondToInvite = respondToInvite
        self.dismissActionItem = dismissActionItem
        self.ensureDirectMessageThread = ensureDirectMessageThread
    }
}

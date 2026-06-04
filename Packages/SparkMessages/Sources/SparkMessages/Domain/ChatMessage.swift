// Module: SparkMessages — Single message in a thread.

import Foundation

public struct ChatMessage: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let threadID: MessageThreadID
    public let body: String
    public let sentAt: Date
    public let isFromCurrentUser: Bool

    public init(
        id: String,
        threadID: MessageThreadID,
        body: String,
        sentAt: Date,
        isFromCurrentUser: Bool
    ) {
        self.id = id
        self.threadID = threadID
        self.body = body
        self.sentAt = sentAt
        self.isFromCurrentUser = isFromCurrentUser
    }
}

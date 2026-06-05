// Module: SparkMessages — Single message in a thread.

import Foundation

public struct ChatMessage: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let threadID: MessageThreadID
    public let body: String
    public let sentAt: Date
    public let isFromCurrentUser: Bool
    public let kind: ChatMessageKind
    public let systemPayload: MessagesSystemPayload?
    public let activityID: String?

    public init(
        id: String,
        threadID: MessageThreadID,
        body: String,
        sentAt: Date,
        isFromCurrentUser: Bool,
        kind: ChatMessageKind = .text,
        systemPayload: MessagesSystemPayload? = nil,
        activityID: String? = nil
    ) {
        self.id = id
        self.threadID = threadID
        self.body = body
        self.sentAt = sentAt
        self.isFromCurrentUser = isFromCurrentUser
        self.kind = kind
        self.systemPayload = systemPayload
        self.activityID = activityID
    }
}

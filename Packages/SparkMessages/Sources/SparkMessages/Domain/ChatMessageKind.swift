// Module: SparkMessages — Rich message content kinds for chat rendering.

import Foundation

public enum ChatMessageKind: String, Sendable, Equatable {
    case text
    case system
    case activityShare
}

public struct MessagesSystemPayload: Hashable, Sendable, Equatable {
    public let typeLabel: String
    public let title: String
    public let body: String
    public let ctaTitle: String?
    public let ctaActivityID: String?

    public init(
        typeLabel: String,
        title: String,
        body: String,
        ctaTitle: String? = nil,
        ctaActivityID: String? = nil
    ) {
        self.typeLabel = typeLabel
        self.title = title
        self.body = body
        self.ctaTitle = ctaTitle
        self.ctaActivityID = ctaActivityID
    }
}

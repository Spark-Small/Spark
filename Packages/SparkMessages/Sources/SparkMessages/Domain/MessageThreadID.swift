// Module: SparkMessages — Strongly typed thread identifier.

import Foundation

public enum MessageThreadIDPrefix {
    public static let directMessage = "th_dm_"
    public static let activityGroup = "th_activity_"
}

public struct MessageThreadID: Hashable, Sendable, Codable, Equatable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var isDirectMessage: Bool {
        rawValue.hasPrefix(MessageThreadIDPrefix.directMessage)
    }

    public var isGroupChat: Bool {
        rawValue.hasPrefix(MessageThreadIDPrefix.activityGroup)
    }

    /// Peer user id embedded in `th_dm_{user_id}` thread ids.
    public var directMessagePeerUserID: String? {
        guard isDirectMessage else { return nil }
        return String(rawValue.dropFirst(MessageThreadIDPrefix.directMessage.count))
    }
}

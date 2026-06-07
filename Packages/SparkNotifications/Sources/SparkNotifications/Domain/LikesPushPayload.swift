// Module: SparkNotifications — APNs userInfo → Likes tab routes.

import Foundation

public struct LikesPushPayload: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case inbound
        case match(threadID: String?)
    }

    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> LikesPushPayload? {
        guard let type = PushPayloadParsing.stringValue(userInfo["type"]), type.hasPrefix("likes.") else {
            return nil
        }
        switch type {
        case "likes.inbound":
            return LikesPushPayload(kind: .inbound)
        case "likes.match":
            return LikesPushPayload(kind: .match(threadID: PushPayloadParsing.stringValue(userInfo["thread_id"])))
        default:
            return nil
        }
    }
}

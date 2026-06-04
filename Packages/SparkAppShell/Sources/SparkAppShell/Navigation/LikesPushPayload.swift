// Module: SparkAppShell — APNs userInfo → Likes tab routes.

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
        guard let type = stringValue(userInfo["type"]), type.hasPrefix("likes.") else {
            return nil
        }
        switch type {
        case "likes.inbound":
            return LikesPushPayload(kind: .inbound)
        case "likes.match":
            return LikesPushPayload(kind: .match(threadID: stringValue(userInfo["thread_id"])))
        default:
            return nil
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

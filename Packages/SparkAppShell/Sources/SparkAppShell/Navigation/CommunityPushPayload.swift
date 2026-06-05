// Module: SparkAppShell — APNs userInfo → community post detail.

import Foundation

public struct CommunityPushPayload: Sendable, Equatable {
    public let postID: String

    public init(postID: String) {
        self.postID = postID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> CommunityPushPayload? {
        guard let type = stringValue(userInfo["type"]), type.hasPrefix("community.") else {
            return nil
        }
        guard let postID = stringValue(userInfo["post_id"]) else {
            return nil
        }
        return CommunityPushPayload(postID: postID)
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

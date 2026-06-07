// Module: SparkNotifications — APNs userInfo → community post detail.

import Foundation

public struct CommunityPushPayload: Sendable, Equatable {
    public let postID: String

    public init(postID: String) {
        self.postID = postID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> CommunityPushPayload? {
        guard let type = PushPayloadParsing.stringValue(userInfo["type"]), type.hasPrefix("community.") else {
            return nil
        }
        guard let postID = PushPayloadParsing.stringValue(userInfo["post_id"]) else {
            return nil
        }
        return CommunityPushPayload(postID: postID)
    }
}

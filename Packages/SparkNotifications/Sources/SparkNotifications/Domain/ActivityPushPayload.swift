// Module: SparkNotifications — APNs userInfo → activity detail.

import Foundation

public struct ActivityPushPayload: Sendable, Equatable {
    public let activityID: String

    public init(activityID: String) {
        self.activityID = activityID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> ActivityPushPayload? {
        if let activityID = PushPayloadParsing.stringValue(userInfo["activity_id"]) {
            return ActivityPushPayload(activityID: activityID)
        }
        if let type = PushPayloadParsing.stringValue(userInfo["type"]),
           type.hasPrefix("activity."),
           let activityID = PushPayloadParsing.stringValue(userInfo["activity_id"]) {
            return ActivityPushPayload(activityID: activityID)
        }
        return nil
    }
}

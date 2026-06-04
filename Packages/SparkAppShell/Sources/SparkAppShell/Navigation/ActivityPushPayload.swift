// Module: SparkAppShell — APNs userInfo → activity detail (Phase 16).

import Foundation

public struct ActivityPushPayload: Sendable, Equatable {
    public let activityID: String

    public init(activityID: String) {
        self.activityID = activityID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> ActivityPushPayload? {
        if let activityID = stringValue(userInfo["activity_id"]) {
            return ActivityPushPayload(activityID: activityID)
        }
        if let type = stringValue(userInfo["type"]),
           type.hasPrefix("activity."),
           let activityID = stringValue(userInfo["activity_id"]) {
            return ActivityPushPayload(activityID: activityID)
        }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

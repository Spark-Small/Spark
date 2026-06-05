// Module: SparkAppShell — APNs userInfo → conversation thread.

import Foundation

public struct MessagesPushPayload: Sendable, Equatable {
    public let threadID: String

    public init(threadID: String) {
        self.threadID = threadID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> MessagesPushPayload? {
        guard let type = stringValue(userInfo["type"]), type == "messages.new" else {
            return nil
        }
        guard let threadID = stringValue(userInfo["thread_id"]) else {
            return nil
        }
        return MessagesPushPayload(threadID: threadID)
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

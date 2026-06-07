// Module: SparkNotifications — APNs userInfo → conversation thread.

import Foundation

public struct MessagesPushPayload: Sendable, Equatable {
    public let threadID: String

    public init(threadID: String) {
        self.threadID = threadID
    }

    public static func parse(userInfo: [AnyHashable: Any]) -> MessagesPushPayload? {
        guard let type = PushPayloadParsing.stringValue(userInfo["type"]), type == "messages.new" else {
            return nil
        }
        guard let threadID = PushPayloadParsing.stringValue(userInfo["thread_id"]) else {
            return nil
        }
        return MessagesPushPayload(threadID: threadID)
    }
}

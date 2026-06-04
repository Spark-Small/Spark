// Module: SparkMessages — Live API path literals (documented in docs/API_CONTRACT.md).

import Foundation

enum MessagesAPIPath {
    static let unreadCount = "/v1/messages/unread-count"
    static let threads = "/v1/messages/threads"
    static let markRead = "/v1/messages/read"
    static let activityGroupThreads = "/v1/messages/activity-threads"

    static func threadMessages(threadID: String) -> String {
        "\(threads)/\(threadID)/messages"
    }
}

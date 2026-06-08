// Module: SparkMessages — Live API path literals (documented in docs/API_CONTRACT.md).

import Foundation

enum MessagesAPIPath {
    static let unreadCount = "/v1/messages/unread-count"
    static let inbox = "/v1/messages/inbox"
    static let threads = "/v1/messages/threads"
    static let markRead = "/v1/messages/read"
    static let activityGroupThreads = "/v1/messages/activity-threads"
    static let directThreads = "/v1/messages/direct-threads"

    static func threadMessages(threadID: String) -> String {
        "\(threads)/\(threadID)/messages"
    }

    static func markThreadRead(threadID: String) -> String {
        "\(threads)/\(threadID)/read"
    }

    static func conversationContext(threadID: String) -> String {
        "\(threads)/\(threadID)/context"
    }

    static func invitationRespond(activityID: String, invitationID: String) -> String {
        "/v1/activities/\(activityID)/invitations/\(invitationID)/respond"
    }

    static func dismissActionItem(id: String) -> String {
        "/v1/messages/inbox/action-items/\(id)/dismiss"
    }

    static func hideThread(threadID: String) -> String {
        "\(threads)/\(threadID)/hide"
    }

    static func deleteThread(threadID: String) -> String {
        "\(threads)/\(threadID)"
    }
}

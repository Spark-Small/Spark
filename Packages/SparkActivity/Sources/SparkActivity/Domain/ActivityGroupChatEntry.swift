// Module: SparkActivity — Group chat tiles on activity detail.

import Foundation

struct ActivityGroupChatEntry: Identifiable, Sendable, Equatable {
    let id: String
    let threadID: String
    let displayName: String
}

extension ActivityDetail {
    /// Group chats linked to this activity (API may return multiple; mock exposes one).
    var groupChatEntries: [ActivityGroupChatEntry] {
        guard let conversationThreadID else { return [] }
        return [
            ActivityGroupChatEntry(
                id: conversationThreadID,
                threadID: conversationThreadID,
                displayName: displayHostGroupName
            )
        ]
    }
}

// Module: SparkMessages — Client-side inbox search over loaded conversations.

import Foundation

public enum MessagesInboxSearchFiltering {
    /// Filters conversations by display name, last message preview, or linked activity title.
    public static func filter(_ conversations: [ConversationPreview], query: String) -> [ConversationPreview] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return conversations }

        return conversations.filter { conversation in
            conversation.displayName.localizedCaseInsensitiveContains(trimmed)
                || conversation.lastMessagePreview.localizedCaseInsensitiveContains(trimmed)
                || (conversation.activity?.title.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }
}

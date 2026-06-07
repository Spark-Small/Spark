// Module: SparkMessagesTests — Inbox search filtering.

import Foundation
import SparkMessages
import Testing

struct MessagesInboxSearchFilteringTests {
    @Test func emptyQueryReturnsAllConversations() {
        let conversations = [sampleConversation(displayName: "Alex", preview: "Hi")]
        let result = MessagesInboxSearchFiltering.filter(conversations, query: "   ")
        #expect(result.count == 1)
    }

    @Test func matchesDisplayNameCaseInsensitive() {
        let conversations = [
            sampleConversation(displayName: "Mia", preview: "See you"),
            sampleConversation(displayName: "Alex", preview: "Hello")
        ]
        let result = MessagesInboxSearchFiltering.filter(conversations, query: "mia")
        #expect(result.count == 1)
        #expect(result.first?.displayName == "Mia")
    }

    @Test func matchesLastMessagePreview() {
        let conversations = [
            sampleConversation(displayName: "Alex", preview: "Coffee tomorrow?"),
            sampleConversation(displayName: "Bo", preview: "Thanks")
        ]
        let result = MessagesInboxSearchFiltering.filter(conversations, query: "coffee")
        #expect(result.count == 1)
        #expect(result.first?.displayName == "Alex")
    }

    @Test func matchesLinkedActivityTitleForGroupChats() {
        let conversations = [
            ConversationPreview(
                threadID: MessageThreadID("grp_1"),
                kind: .groupChat,
                displayName: "Group",
                lastMessagePreview: "Welcome",
                lastMessageAt: .now,
                unreadCount: 0,
                activity: InboxActivitySummary(
                    id: "act_1",
                    title: "周末徒步局",
                    startsAt: .now.addingTimeInterval(86_400),
                    attendeeCount: 4
                )
            )
        ]
        let result = MessagesInboxSearchFiltering.filter(conversations, query: "徒步")
        #expect(result.count == 1)
    }

    private func sampleConversation(displayName: String, preview: String) -> ConversationPreview {
        ConversationPreview(
            threadID: MessageThreadID("th_\(displayName)"),
            kind: .dm,
            displayName: displayName,
            lastMessagePreview: preview,
            lastMessageAt: .now,
            unreadCount: 0
        )
    }
}

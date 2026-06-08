// Module: SparkMessagesTests

import Foundation
import Testing
@testable import SparkMessages

struct MessagesInboxSortingTests {
    @Test func conversationListOrderPrioritizesUnreadThenRecency() {
        let olderUnread = ConversationPreview(
            threadID: MessageThreadID("th_1"),
            kind: .dm,
            displayName: "A",
            lastMessagePreview: "Hi",
            lastMessageAt: .now.addingTimeInterval(-3_600),
            unreadCount: 2
        )
        let newerRead = ConversationPreview(
            threadID: MessageThreadID("th_2"),
            kind: .dm,
            displayName: "B",
            lastMessagePreview: "Hey",
            lastMessageAt: .now,
            unreadCount: 0
        )
        let ordered = MessagesInboxSorting.conversationListOrder([newerRead, olderUnread])
        #expect(ordered.first?.threadID == MessageThreadID("th_1"))
    }

    @Test func visibleGroupChatsExcludesArchivedAndEnded() {
        let upcoming = ConversationPreview(
            threadID: MessageThreadID("th_upcoming"),
            kind: .groupChat,
            displayName: "Upcoming",
            lastMessagePreview: "Hi",
            lastMessageAt: .now,
            unreadCount: 0,
            activity: InboxActivitySummary(
                id: "act_1",
                title: "Upcoming",
                startsAt: .now.addingTimeInterval(86_400),
                attendeeCount: 6,
                lifecycle: .upcoming
            )
        )
        let ended = ConversationPreview(
            threadID: MessageThreadID("th_ended"),
            kind: .groupChat,
            displayName: "Ended",
            lastMessagePreview: "Done",
            lastMessageAt: .now,
            unreadCount: 0,
            activity: InboxActivitySummary(
                id: "act_2",
                title: "Ended",
                startsAt: .now.addingTimeInterval(-86_400),
                attendeeCount: 4,
                lifecycle: .ended
            ),
            isArchived: true
        )
        let visible = MessagesInboxSorting.visibleGroupChats([upcoming, ended])
        #expect(visible.count == 1)
        #expect(visible.first?.threadID == MessageThreadID("th_upcoming"))
    }
}

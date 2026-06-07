// Module: SparkActivityTests

import Foundation
import SparkActivity
import Testing

struct ActivityListFilterTests {
    @Test func hostingMatchesHostItems() {
        let item = ActivityItem(
            id: "a",
            title: "T",
            summary: "S",
            category: "C",
            rsvpStatus: .host,
            lifecycleStatus: .scheduled
        )
        #expect(ActivityListFiltering.matches(item, filter: .hosting))
    }

    @Test func pendingReplyMatchesInvitedScheduled() {
        let item = ActivityItem(
            id: "a",
            title: "T",
            summary: "S",
            category: "C",
            startsAt: Date().addingTimeInterval(3600),
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        #expect(ActivityListFiltering.matches(item, filter: .pendingReply))
    }

    @Test func fullBlocksGoingForInvited() {
        let detail = ActivityDetail(
            id: "act_2",
            title: "Coffee",
            summary: "S",
            category: "C",
            description: "D",
            startsAt: Date().addingTimeInterval(3600),
            locationName: "Cafe",
            hostDisplayName: "Host",
            attendeeCount: 4,
            capacity: 4,
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        #expect(detail.canSelectGoing == false)
    }

    @Test func actionItemsVisibleOnlyForActivityRequestsSegment() {
        #expect(!ActivityListFilter.all.showsInboxActionItems)
        #expect(ActivityListFilter.pendingReply.showsInboxActionItems)
        #expect(!ActivityListFilter.upcoming.showsInboxActionItems)
        #expect(!ActivityListFilter.hosting.showsInboxActionItems)
        #expect(!ActivityListFilter.past.showsInboxActionItems)
    }

    @Test func listPresentationHidesFeedRowsCoveredByRequestCards() {
        let item = ActivityItem(
            id: "act_invite",
            title: "Hike",
            summary: "S",
            category: "Outdoor",
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        let other = ActivityItem(
            id: "act_other",
            title: "Coffee",
            summary: "S",
            category: "Social",
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        let presented = ActivityInboxListPresentation.listItems(
            from: [item, other],
            filter: .pendingReply,
            requestActivityIDs: ["act_invite"]
        )
        #expect(presented.count == 1)
        #expect(presented.first?.id == "act_other")
    }

    @Test func pastMatchesEndedParticipant() {
        let item = ActivityItem(
            id: "a",
            title: "T",
            summary: "S",
            category: "C",
            rsvpStatus: .going,
            lifecycleStatus: .ended
        )
        #expect(ActivityListFiltering.matches(item, filter: .past))
    }
}

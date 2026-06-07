// Module: SparkActivityTests — Activity thread ids and invite URL helpers.

import Foundation
import SparkActivity
import Testing

struct ActivityInviteURLTests {
    @Test func makeThreadID() {
        #expect(ActivityThreadID.make(for: "act_1") == "th_activity_act_1")
    }

    @Test func deepLinkUsesSparkScheme() {
        let url = ActivityInviteURL.deepLink(activityID: "act_1")
        #expect(url.scheme == "spark")
        #expect(url.host == "activity")
        #expect(url.path == "/act_1")
    }

    @Test func universalLinkUsesWebBase() {
        let url = ActivityInviteURL.universalLink(activityID: "act_1")
        #expect(url.absoluteString.contains("/a/act_1"))
    }

    @Test func shareLinkRespectsConfiguration() {
        let url = ActivityInviteURL.shareLink(activityID: "act_1")
        #expect(url.scheme == "https" || url.scheme == "spark")
    }

    @Test func shareMessageIncludesTitle() {
        let message = ActivityInviteURL.shareMessage(title: "Morning Run")
        #expect(message.contains("Morning Run"))
    }

    @Test func attendeeSummaryWithCapacity() {
        let activity = sampleDetail(capacity: 8, attendeeCount: 3)
        let summary = ActivityInviteURL.attendeeSummary(for: activity)
        #expect(summary.contains("3"))
        #expect(summary.contains("8"))
    }

    @Test func attendeeSummaryWithoutCapacity() {
        let activity = sampleDetail(capacity: nil, attendeeCount: 5)
        let summary = ActivityInviteURL.attendeeSummary(for: activity)
        #expect(summary.contains("5"))
    }

    @Test func inviteCopyTextIncludesScheduleAndLink() {
        let activity = sampleDetail(capacity: 8, attendeeCount: 2)
        let copy = ActivityInviteURL.inviteCopyText(activity: activity)
        #expect(copy.contains(activity.title))
        #expect(copy.contains("Park"))
        #expect(copy.contains("act_invite"))
    }

    private func sampleDetail(capacity: Int?, attendeeCount: Int) -> ActivityDetail {
        ActivityDetail(
            id: "act_invite",
            title: "Coffee Chat",
            summary: "Sat morning",
            category: "event",
            description: "Desc",
            startsAt: Date(timeIntervalSince1970: 1_718_000_000),
            locationName: "Park",
            hostDisplayName: "Alex",
            hostID: "host_1",
            hostBio: "",
            attendeeCount: attendeeCount,
            waitlistedCount: 0,
            capacity: capacity,
            rsvpStatus: .going,
            lifecycleStatus: .scheduled,
            attendees: [],
            conversationThreadID: ActivityThreadID.make(for: "act_invite")
        )
    }
}

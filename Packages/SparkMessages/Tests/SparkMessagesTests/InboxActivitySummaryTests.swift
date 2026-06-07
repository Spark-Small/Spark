// Module: SparkMessagesTests — Inbox activity summary formatting.

import Foundation
import SparkMessages
import Testing

struct InboxActivitySummaryTests {
    @Test func formattedDatesAreNonEmpty() {
        let summary = sampleSummary(startsAt: Date(timeIntervalSince1970: 1_718_000_000))
        #expect(summary.formattedDate.isEmpty == false)
        #expect(summary.formattedDateShort.isEmpty == false)
    }

    @Test func countdownTextForLifecycleStates() {
        let upcoming = sampleSummary(
            startsAt: Date().addingTimeInterval(86_400),
            lifecycle: .upcoming
        )
        #expect(upcoming.countdownText.isEmpty == false)

        let ongoing = sampleSummary(startsAt: Date(), lifecycle: .ongoing)
        #expect(ongoing.countdownText.contains("进行中") || ongoing.countdownText.contains("progress"))

        let ended = sampleSummary(startsAt: Date().addingTimeInterval(-86_400), lifecycle: .ended)
        #expect(ended.countdownText.contains("结束") || ended.countdownText.contains("ended"))
    }

    private func sampleSummary(
        startsAt: Date,
        lifecycle: InboxActivityLifecycle = .upcoming
    ) -> InboxActivitySummary {
        InboxActivitySummary(
            id: "act_1",
            title: "Coffee",
            startsAt: startsAt,
            attendeeCount: 3,
            lifecycle: lifecycle
        )
    }
}

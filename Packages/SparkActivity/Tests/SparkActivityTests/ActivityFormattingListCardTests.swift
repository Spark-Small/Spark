import Foundation
import Testing
@testable import SparkActivity

@Suite struct ActivityFormattingListCardTests {
    @Test func overlayLinesSeparateTitleScheduleAndLocationAttendees() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startsAt = calendar.date(from: DateComponents(year: 2026, month: 6, day: 19, hour: 19, minute: 30))!

        let info = ActivityListCardDisplayInfo(
            title: "周末徒步",
            startsAt: startsAt,
            locationName: "静安公园",
            hostDisplayName: "阿乐",
            attendeeCount: 5,
            capacity: 12
        )

        #expect(info.overlayPrimaryLineParts.first == "周末徒步")
        #expect(info.overlayPrimaryLineParts.count == 3)
        #expect(info.overlaySecondaryLineParts.contains("静安公园"))
        #expect(info.overlaySecondaryLineParts.contains(where: { $0.contains("5") }))
        #expect(info.overlaySecondaryLineParts.contains(where: { $0.contains("12") }))
        #expect(!info.overlaySecondaryLineParts.contains("阿乐"))
    }

    @Test func displayInfoWithoutScheduleUsesTitleOnlyInSummary() {
        let info = ActivityListCardDisplayInfo(title: "咖啡小局", startsAt: nil)
        #expect(info.accessibilitySummary == "咖啡小局")
    }

    @Test func overlaySecondaryLineIncludesAttendeeCountWithoutLocation() {
        let info = ActivityListCardDisplayInfo(
            title: "跑步打卡",
            startsAt: Date(),
            locationName: "",
            attendeeCount: 3,
            capacity: nil
        )

        #expect(info.overlaySecondaryLineParts.count == 1)
        #expect(info.overlaySecondaryLineParts.first?.contains("3") == true)
    }
}

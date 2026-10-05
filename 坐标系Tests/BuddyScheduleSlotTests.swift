//
//  BuddyScheduleSlotTests.swift
//  坐标系Tests
//
//  档期文案解析：同星期几不跳到下周；可约日汇总。
//

import XCTest
@testable import 坐标系

final class BuddyScheduleSlotTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return cal
    }

    func testWeekdayLabelUsesTodayWhenTimeStillUpcoming() throws {
        let fridayMorning = try XCTUnwrap(friday(hour: 10, minute: 0))
        let resolved = BuddyScheduleSlot.resolveDate(from: "周五 21:00", reference: fridayMorning)
        XCTAssertTrue(calendar.isDate(resolved, inSameDayAs: fridayMorning))
        XCTAssertEqual(calendar.component(.hour, from: resolved), 21)
    }

    func testWeekdayLabelRollsForwardWhenTimeAlreadyPassed() throws {
        let fridayNight = try XCTUnwrap(friday(hour: 22, minute: 0))
        let resolved = BuddyScheduleSlot.resolveDate(from: "周五 21:00", reference: fridayNight)
        XCTAssertFalse(calendar.isDate(resolved, inSameDayAs: fridayNight))
        XCTAssertGreaterThan(resolved, fridayNight)
    }

    private func friday(hour: Int, minute: Int) -> Date? {
        var day = Date(timeIntervalSince1970: 1_700_000_000) // 锚点后找最近周五
        for _ in 0..<14 {
            if calendar.component(.weekday, from: day) == 6 { break }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }
        guard calendar.component(.weekday, from: day) == 6 else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute
        comps.timeZone = calendar.timeZone
        return calendar.date(from: comps)
    }

    func testFirstBookableDaySkipsFullAndPast() {
        let now = Date()
        let map = BuddyScheduleSlot.dayAvailabilityMap(
            slots: ["今晚 20:00", "明日 已满", "周六 14:00"],
            reference: now,
            calendar: calendar
        )
        let first = BuddyScheduleSlot.firstBookableDay(
            slots: ["今晚 20:00", "明日 已满", "周六 14:00"],
            reference: now,
            calendar: calendar
        )
        XCTAssertNotNil(first)
        if let first {
            XCTAssertEqual(map[calendar.startOfDay(for: first)], .bookable)
        }
    }
}

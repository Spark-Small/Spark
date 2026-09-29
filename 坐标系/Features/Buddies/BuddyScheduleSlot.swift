//
//  BuddyScheduleSlot.swift
//  坐标系
//
//  把种子档期文案解析为可下单的开始时间（本地演示）。
//

import Foundation
import CoordinateModels

enum BuddyScheduleSlot {
    /// 日历日期下方状态
    enum DayAvailability: Equatable, Sendable {
        case bookable
        case full
        case pending
        case none

        /// 日期下短标签：可约 / 有档期感用「可约」；已满 / 待开放
        var caption: String? {
            switch self {
            case .bookable: BuddyDetailCopy.available
            case .full: ActivityCardStatus.full
            case .pending: "待开放"
            case .none: nil
            }
        }

        var isSelectable: Bool { self == .bookable }

        /// 合并同日多档：有可约优先，其次待开放，再次已满
        static func merge(_ lhs: DayAvailability, _ rhs: DayAvailability) -> DayAvailability {
            let rank: (DayAvailability) -> Int = {
                switch $0 {
                case .bookable: 3
                case .pending: 2
                case .full: 1
                case .none: 0
                }
            }
            return rank(lhs) >= rank(rhs) ? lhs : rhs
        }
    }

    struct Resolved: Identifiable, Hashable, Sendable {
        var id: String { label }
        let label: String
        let start: Date
        let bookable: Bool
        let availability: DayAvailability

        func dayStart(calendar: Calendar = .current) -> Date {
            calendar.startOfDay(for: start)
        }
    }

    /// 将「今晚 20:00」「明日 18:30」「周六下午」等解析为 Date；解析失败则回退到约 24h 后。
    static func resolveDate(from label: String, reference: Date = .now) -> Date {
        let calendar = Calendar.current
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("待开放") || trimmed.contains("已满") {
            if let date = resolveRelativeDay(trimmed, calendar: calendar, reference: reference) {
                return date
            }
            return reference.addingTimeInterval(60 * 60 * 24 * 7)
        }

        if let date = resolveRelativeDay(trimmed, calendar: calendar, reference: reference) {
            return date
        }

        return reference.addingTimeInterval(60 * 60 * 24)
    }

    static func isBookable(_ label: String) -> Bool {
        !label.contains("待开放") && !label.contains("已满")
    }

    static func availability(for label: String) -> DayAvailability {
        if label.contains("已满") { return .full }
        if label.contains("待开放") { return .pending }
        if isBookable(label) { return .bookable }
        return .none
    }

    static func resolveAll(
        _ labels: [String],
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> [Resolved] {
        labels.map { label in
            let start = resolveDate(from: label, reference: reference)
            let status = availability(for: label)
            return Resolved(
                label: label,
                start: start,
                bookable: status == .bookable,
                availability: status
            )
        }
        .sorted { $0.start < $1.start }
    }

    /// 按自然日汇总可约状态（用于月历格子下方文案）
    static func dayAvailabilityMap(
        slots: [String],
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> [Date: DayAvailability] {
        var map: [Date: DayAvailability] = [:]
        for resolved in resolveAll(slots, reference: reference, calendar: calendar) {
            let day = resolved.dayStart(calendar: calendar)
            let existing = map[day] ?? .none
            map[day] = DayAvailability.merge(existing, resolved.availability)
        }
        return map
    }

    static func slots(
        on day: Date,
        from labels: [String],
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> [Resolved] {
        let dayStart = calendar.startOfDay(for: day)
        return resolveAll(labels, reference: reference, calendar: calendar)
            .filter { calendar.isDate($0.start, inSameDayAs: dayStart) }
    }

    private static func resolveRelativeDay(
        _ label: String,
        calendar: Calendar,
        reference: Date
    ) -> Date? {
        var dayOffset = 0
        var hour = 19
        var minute = 0

        if label.contains("今晚") || label.contains("今日") {
            dayOffset = 0
        } else if label.contains("明早") {
            dayOffset = 1
            hour = 7
            minute = 30
        } else if label.contains("明日") || label.contains("明天") {
            dayOffset = 1
        } else if label.contains("周五") {
            dayOffset = daysUntil(weekday: 6, from: reference, calendar: calendar)
        } else if label.contains("周六") || label.contains("本周六") || label.contains("下周六") {
            dayOffset = daysUntil(weekday: 7, from: reference, calendar: calendar)
            if label.contains("下周六") { dayOffset += 7 }
        } else if label.contains("周日") || label.contains("本周日") || label.contains("下周日") {
            dayOffset = daysUntil(weekday: 1, from: reference, calendar: calendar)
            if label.contains("下周日") { dayOffset += 7 }
        } else if label.contains("周一") {
            dayOffset = daysUntil(weekday: 2, from: reference, calendar: calendar)
        } else if label.contains("周二") {
            dayOffset = daysUntil(weekday: 3, from: reference, calendar: calendar)
        } else if label.contains("周三") {
            dayOffset = daysUntil(weekday: 4, from: reference, calendar: calendar)
        } else if label.contains("周四") {
            dayOffset = daysUntil(weekday: 5, from: reference, calendar: calendar)
        } else if label.contains("工作日") {
            dayOffset = nextWeekday(from: reference, calendar: calendar)
        } else if label.contains("周末") {
            dayOffset = daysUntil(weekday: 7, from: reference, calendar: calendar)
        }

        if let match = label.range(of: #"(\d{1,2}):(\d{2})"#, options: .regularExpression) {
            let parts = label[match].split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                hour = h
                minute = m
            }
        } else if label.contains("上午") {
            hour = 10
            minute = 0
        } else if label.contains("下午") {
            hour = 15
            minute = 0
        } else if label.contains("全天") {
            hour = 9
            minute = 0
        }

        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: reference) else {
            return nil
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute
        guard let resolved = calendar.date(from: comps) else { return nil }
        if resolved <= reference, !label.contains("待开放"), !label.contains("已满") {
            return calendar.date(byAdding: .day, value: 1, to: resolved) ?? resolved
        }
        return resolved
    }

    private static func daysUntil(weekday: Int, from date: Date, calendar: Calendar) -> Int {
        let current = calendar.component(.weekday, from: date)
        let delta = (weekday - current + 7) % 7
        return delta == 0 ? 7 : delta
    }

    private static func nextWeekday(from date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { return 1 } // Sunday -> Monday
        if weekday == 7 { return 2 } // Saturday -> Monday
        return 0
    }
}

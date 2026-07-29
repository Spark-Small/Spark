//
//  BuddyScheduleSlot.swift
//  坐标系
//
//  把种子档期文案解析为可下单的开始时间（本地演示）。
//

import Foundation

enum BuddyScheduleSlot {
    /// 将「今晚 20:00」「明日 18:30」「周六下午」等解析为 Date；解析失败则回退到约 24h 后。
    static func resolveDate(from label: String, reference: Date = .now) -> Date {
        let calendar = Calendar.current
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("待开放") || trimmed.contains("已满") {
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
        if resolved <= reference {
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

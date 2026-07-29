//
//  Formatters.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import Foundation

enum Formatters {
    static let activityDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE HH:mm"
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// 按时段问候（本机时区日历）：早上好 / 中午好 / 下午好 / 晚上好
    static func daypartGreeting(at date: Date = .now) -> String {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11: return "早上好"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }

    /// 会话列表右侧：星期三
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// 会话列表右侧：7月20日
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    /// 列表时间：今天时刻 / 昨天 / 星期 / 日期（全中文）
    static func conversationListTime(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return shortTime.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return "昨天"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return weekday.string(from: date)
        }
        return monthDay.string(from: date)
    }

    /// 社区评论相对时间：刚刚 / 3分钟 / 2小时 / 1天 / 1周
    static func commentRelativeTime(from date: Date, relativeTo now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 60 { return "刚刚" }
        if seconds < 3600 { return "\(Int(seconds / 60))分钟" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))小时" }
        if seconds < 86_400 * 7 { return "\(Int(seconds / 86_400))天" }
        if seconds < 86_400 * 30 { return "\(max(1, Int(seconds / (86_400 * 7))))周" }
        return monthDay.string(from: date)
    }

    /// 活动举行时间：今天 12:10 / 今晚 19:30 / 明天 09:00 / 星期三 09:00
    static func activityEventTime(from date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current
        let time = shortTime.string(from: date)
        let hour = calendar.component(.hour, from: date)

        if calendar.isDateInToday(date) {
            // 全时段友好：白天用「今天」，晚间再用「今晚」
            let dayLabel = hour >= 18 ? "今晚" : "今天"
            return "\(dayLabel) \(time)"
        }
        if calendar.isDateInTomorrow(date) {
            return "明天 \(time)"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "\(weekday.string(from: date)) \(time)"
        }
        return "\(monthDay.string(from: date)) \(time)"
    }

    /// 距开始倒计时
    static func activityStartCountdown(from date: Date, relativeTo now: Date = .now) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= -7200 { return "活动已结束" }
        if seconds <= 0 { return "活动进行中" }
        let hours = Int(seconds / 3600)
        if hours < 1 {
            let minutes = max(Int(seconds / 60), 1)
            return "距开始还有 \(minutes) 分钟"
        }
        if hours < 24 {
            return "距开始还有 \(hours) 小时"
        }
        let days = hours / 24
        if days == 1 { return "明天开始" }
        if days < 7 { return "\(days) 天后开始" }
        return activityEventTime(from: date, relativeTo: now)
    }

    /// 取摘要首句作卖点，控制在约 36 字
    static func activityPitch(from summary: String, limit: Int = 36) -> String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "来坐标系遇见同频的人" }
        let delimiters = CharacterSet(charactersIn: "。！？\n")
        let first = trimmed.components(separatedBy: delimiters).first(where: { !$0.isEmpty }) ?? trimmed
        if first.count <= limit { return first }
        return String(first.prefix(limit)) + "…"
    }

    /// 正文明显长于副标题时才展示，避免与首屏 pitch 重复
    static func activityExtendedBody(from summary: String) -> String? {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let pitch = activityPitch(from: trimmed)
        if pitch.hasSuffix("…") { return trimmed }
        if trimmed.count > pitch.count + 40 { return trimmed }
        return nil
    }

    /// 互动数字：1033 → 1,033；105000 → 10.5万
    static func compactCount(_ value: Int) -> String {
        if value >= 10_000 {
            let wan = Double(value) / 10_000
            if wan == floor(wan) {
                return "\(Int(wan))万"
            }
            var text = String(format: "%.1f", wan)
            if text.hasSuffix(".0") {
                text = String(text.dropLast(2))
            }
            return "\(text)万"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Stable seeds（跨启动稳定，避免 hashValue 抖动）

extension UUID {
    /// 由 UUID 字节派生的稳定非负种子（演示数据 / 占位指标用）
    var stableSeed: Int {
        withUnsafeBytes(of: uuid) { raw in
            raw.reduce(into: 0) { partial, byte in
                partial = partial &* 31 &+ Int(byte)
            }
        }
    }
}

extension String {
    /// 由 UTF-8 字节派生的稳定非负种子
    var stableSeed: Int {
        utf8.reduce(into: 0) { partial, byte in
            partial = partial &* 31 &+ Int(byte)
        }
    }
}

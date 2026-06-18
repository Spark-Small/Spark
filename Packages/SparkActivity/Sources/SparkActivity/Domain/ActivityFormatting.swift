// Module: SparkActivity — Shared date copy for list and detail.

import Foundation

enum ActivityFormatting {
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func date(from iso8601: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: iso8601) {
            return date
        }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: iso8601)
    }

    /// Meetup-style long date for detail hero (e.g. Saturday, June 7).
    static func detailWeekdayDateLine(startsAt: Date) -> String {
        startsAt.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    /// Meetup-style time-only line for detail when/where block.
    static func detailTimeLine(startsAt: Date) -> String {
        startsAt.formatted(date: .omitted, time: .shortened)
    }

    /// Meetup-style month abbreviation for inbox date tile (e.g. JUN).
    static func listMonthAbbreviation(startsAt: Date) -> String {
        startsAt.formatted(.dateTime.month(.abbreviated)).uppercased()
    }

    /// Meetup-style day number for inbox date tile.
    static func listDayNumber(startsAt: Date) -> String {
        startsAt.formatted(.dateTime.day())
    }

    /// Discover browse scene line (category · weekday time).
    static func browseSceneLine(category: String, startsAt: Date?) -> String {
        var parts: [String] = []
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCategory.isEmpty {
            parts.append(trimmedCategory)
        }
        if let startsAt {
            let when = startsAt.formatted(
                .dateTime.weekday(.wide).hour().minute().locale(Locale.current)
            )
            parts.append(when)
        }
        if parts.isEmpty {
            return String(
                localized: "activity.browse.scene.fallback",
                defaultValue: "公开活动",
                comment: "Browse scene fallback"
            )
        }
        return parts.joined(separator: " · ")
    }

    /// Browse social proof when headcount is zero.
    static func browseSocialProofLine(attendeeCount: Int) -> String {
        if attendeeCount > 0 {
            return String(
                format: String(
                    localized: "activity.browse.going.format",
                    defaultValue: "%lld 人已报名",
                    comment: "Browse RSVP count; %lld is count"
                ),
                locale: .current,
                attendeeCount
            )
        }
        return String(
            localized: "activity.browse.earlyBird",
            defaultValue: "新开局 · 早鸟",
            comment: "Zero RSVP social proof"
        )
    }

    /// Public signup expectations for discover detail decision strip.
    static var browseDecisionRulesLine: String {
        String(
            localized: "activity.browse.decision.rules",
            defaultValue: "公开报名 · 活动群聊 · 可随时取消",
            comment: "Browse decision rules"
        )
    }

    /// Meetup browse card schedule (e.g. FRI, JUN 12 • 7:00 PM to 9:00 PM).
    static func listCardScheduleLine(startsAt: Date, endsAt: Date? = nil) -> String {
        let weekday = startsAt.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        let monthDay = startsAt.formatted(.dateTime.month(.abbreviated).day()).uppercased()
        let time = detailTimeRangeLine(startsAt: startsAt, endsAt: endsAt)
        return "\(weekday), \(monthDay) • \(time)"
    }

    /// Meetup detail schedule (e.g. Friday, Jun 26 · 7:00 PM to 9:00 PM).
    static func detailMeetupScheduleLine(startsAt: Date, endsAt: Date? = nil) -> String {
        let datePart = startsAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        let timePart = detailTimeRangeLine(startsAt: startsAt, endsAt: endsAt)
        return "\(datePart) · \(timePart)"
    }

    /// Meetup time range (e.g. 7:00 PM to 9:00 PM).
    static func detailTimeRangeLine(startsAt: Date, endsAt: Date?) -> String {
        let startTime = startsAt.formatted(date: .omitted, time: .shortened)
        guard let endsAt else { return startTime }
        let endTime = endsAt.formatted(date: .omitted, time: .shortened)
        let format = String(
            localized: "activity.schedule.timeRange.format",
            defaultValue: "%@ to %@",
            comment: "Time range; first %@ is start, second is end"
        )
        return String(format: format, locale: .current, startTime, endTime)
    }

    /// Meetup recurrence subtitle (e.g. Every week on Friday until June 6, 2027).
    static func detailRecurrenceLine(_ rule: ActivityRecurrenceRule) -> String {
        switch rule.frequency {
        case .weekly:
            let weekday = rule.weekday.localizedName()
            if let until = rule.until {
                let untilDate = until.formatted(.dateTime.month(.wide).day().year())
                let format = String(
                    localized: "activity.recurrence.weekly.until.format",
                    defaultValue: "Every week on %@ until %@",
                    comment: "Weekly recurrence with end date; first %@ weekday, second until date"
                )
                return String(format: format, locale: .current, weekday, untilDate)
            }
            let format = String(
                localized: "activity.recurrence.weekly.format",
                defaultValue: "Every week on %@",
                comment: "Weekly recurrence; %@ is weekday"
            )
            return String(format: format, locale: .current, weekday)
        }
    }

    static func scheduleLine(startsAt: Date, locationName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        let when = formatter.string(from: startsAt)
        return locationName.isEmpty ? when : "\(when) · \(locationName)"
    }

    static func attendeeLine(attendeeCount: Int, capacity: Int?) -> String {
        if let capacity {
            let format = String(
                localized: "activity.attendees.capacity.format",
                defaultValue: "%lld / %lld 人",
                comment: "Attendees; first %lld is count, second is capacity"
            )
            return String(format: format, locale: .current, attendeeCount, capacity)
        }
        let format = String(
            localized: "activity.attendees.count.format",
            defaultValue: "%lld 人已参加",
            comment: "Attendees; %lld is count"
        )
        return String(format: format, locale: .current, attendeeCount)
    }
}

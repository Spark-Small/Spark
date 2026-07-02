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

    /// Detail line 2: calendar date · weekday (e.g. 6月19日 · 周五).
    static func detailDateDotWeekdayLine(startsAt: Date) -> String {
        let datePart = startsAt.formatted(.dateTime.month(.abbreviated).day())
        let weekdayPart = startsAt.formatted(.dateTime.weekday(.wide))
        return "\(datePart) · \(weekdayPart)"
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

    /// Browse card line 1: title / time / weekday (e.g. 周末徒步 / 19:00 / 周六).
    static func listCardPrimaryInfoLine(title: String, startsAt: Date?) -> String {
        let info = ActivityListCardDisplayInfo(title: title, startsAt: startsAt)
        if info.scheduleLine.isEmpty {
            return info.title
        }
        return [info.title, info.scheduleLine]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// Browse card line 2: location / host / attendee count.
    static func listCardSecondaryInfoLine(
        locationName: String,
        hostDisplayName: String,
        attendeeCount: Int,
        capacity: Int? = nil
    ) -> String {
        let info = ActivityListCardDisplayInfo(
            title: "",
            startsAt: nil,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            attendeeCount: attendeeCount,
            capacity: capacity
        )
        return info.metadataLine
    }

    static func listCardDisplayInfo(from item: ActivityItem) -> ActivityListCardDisplayInfo {
        ActivityListCardDisplayInfo(
            title: item.title,
            startsAt: item.startsAt,
            locationName: item.locationName,
            hostDisplayName: item.hostDisplayName,
            attendeeCount: max(item.attendeeCount, 0),
            capacity: item.capacity
        )
    }

    static func listCardAttendeeCountLine(attendeeCount: Int, capacity: Int?) -> String {
        if let capacity {
            let format = String(
                localized: "activity.row.attendees.compact.capacity.format",
                defaultValue: "%lld/%lld 人",
                comment: "Compact attendee count with capacity; first %lld is count, second is capacity"
            )
            return String(format: format, locale: .current, attendeeCount, capacity)
        }
        let format = String(
            localized: "activity.row.attendees.compact.format",
            defaultValue: "%lld 人参加",
            comment: "Compact attendee count; %lld is count"
        )
        return String(format: format, locale: .current, attendeeCount)
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

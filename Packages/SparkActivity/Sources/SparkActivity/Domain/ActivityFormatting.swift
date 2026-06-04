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

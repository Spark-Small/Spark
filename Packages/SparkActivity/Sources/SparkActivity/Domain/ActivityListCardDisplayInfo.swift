// Module: SparkActivity — Structured browse list card copy (title · schedule · meta).

import Foundation

struct ActivityListCardDisplayInfo: Equatable {
    let title: String
    let timeText: String?
    let weekdayText: String?
    let locationText: String?
    let hostText: String?
    let attendeeCount: Int
    let capacity: Int?
    let attendeeText: String

    init(
        title: String,
        startsAt: Date?,
        locationName: String = "",
        hostDisplayName: String = "",
        attendeeCount: Int = 0,
        capacity: Int? = nil
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = trimmedTitle

        if let startsAt {
            timeText = startsAt.formatted(date: .omitted, time: .shortened)
            weekdayText = startsAt.formatted(.dateTime.weekday(.abbreviated))
        } else {
            timeText = nil
            weekdayText = nil
        }

        let location = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        locationText = location.isEmpty ? nil : location

        let host = hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        hostText = host.isEmpty ? nil : host

        self.attendeeCount = attendeeCount
        self.capacity = capacity
        attendeeText = ActivityFormatting.listCardAttendeeCountLine(
            attendeeCount: attendeeCount,
            capacity: capacity
        )
    }

    var scheduleParts: [String] {
        [timeText, weekdayText].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    /// Line 1: title · time · weekday.
    var overlayPrimaryLineParts: [String] {
        var parts = [title].filter { !$0.isEmpty }
        parts.append(contentsOf: scheduleParts)
        return parts
    }

    /// Line 2: location · attendee count (no host on browse cards).
    var overlaySecondaryLineParts: [String] {
        var parts = [locationText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if locationText != nil || attendeeCount > 0 || capacity != nil {
            parts.append(attendeeText)
        }

        return parts
    }

    var metadataParts: [String] {
        var parts = [locationText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        parts.append(contentsOf: hostAttendeeParts)

        return parts
    }

    var hostAttendeeParts: [String] {
        var parts = [hostText]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if locationText != nil || hostText != nil || attendeeCount > 0 || capacity != nil {
            parts.append(attendeeText)
        }

        return parts
    }

    var scheduleLine: String {
        scheduleParts.joined(separator: " · ")
    }

    var metadataLine: String {
        overlaySecondaryLineParts.joined(separator: " · ")
    }

    var overlayPrimaryLine: String {
        overlayPrimaryLineParts.joined(separator: " · ")
    }

    var overlaySecondaryLine: String {
        overlaySecondaryLineParts.joined(separator: " · ")
    }

    var accessibilitySummary: String {
        var parts: [String] = []
        if !overlayPrimaryLine.isEmpty {
            parts.append(overlayPrimaryLine)
        }
        if !overlaySecondaryLine.isEmpty {
            parts.append(overlaySecondaryLine)
        }
        return parts.joined(separator: ", ")
    }
}

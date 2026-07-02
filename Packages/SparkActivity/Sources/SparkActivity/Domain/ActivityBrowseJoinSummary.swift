// Module: SparkActivity — Join confirmation copy derived from browse list rows.

struct ActivityBrowseJoinSummary: Equatable {
    let title: String
    let category: String
    let scheduleLine: String?
    let locationLine: String?
    let hostLine: String?
    let attendeeLine: String
    let teaserLine: String?

    init(item: ActivityItem) {
        title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        category = item.category.trimmingCharacters(in: .whitespacesAndNewlines)

        if let startsAt = item.startsAt {
            scheduleLine = ActivityFormatting.detailMeetupScheduleLine(
                startsAt: startsAt,
                endsAt: item.endsAt
            )
        } else {
            scheduleLine = nil
        }

        let location = item.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        locationLine = location.isEmpty ? nil : location

        let host = item.hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if host.isEmpty {
            hostLine = nil
        } else {
            let format = String(
                localized: "activity.join.host.format",
                defaultValue: "主办 %@",
                comment: "Join sheet host line; %@ is display name"
            )
            hostLine = String(format: format, locale: .current, host)
        }

        attendeeLine = ActivityFormatting.attendeeLine(
            attendeeCount: max(item.attendeeCount, 0),
            capacity: item.capacity
        )

        let summary = item.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduleHint = item.scheduleLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if summary.isEmpty || summary == scheduleHint {
            teaserLine = nil
        } else {
            teaserLine = summary
        }
    }
}

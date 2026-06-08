// Module: SparkActivity — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum ActivityAPIPath {
    private static let activities = "/v1/activities"

    static let feed = "\(activities)/feed"
    static let browseBase = "\(activities)/browse"
    static let create = activities

    static func browse(query: ActivityBrowseQuery) -> String {
        guard var components = URLComponents(string: browseBase) else { return browseBase }
        var queryItems: [URLQueryItem] = []
        if let category = query.category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let startsAfter = query.startsAfter {
            queryItems.append(URLQueryItem(name: "starts_after", value: formatter.string(from: startsAfter)))
        }
        if let startsBefore = query.startsBefore {
            queryItems.append(URLQueryItem(name: "starts_before", value: formatter.string(from: startsBefore)))
        }
        if let cursor = query.cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.string ?? browseBase
    }

    static func activitiesByHost(hostID: String) -> String {
        guard var components = URLComponents(string: feed) else { return feed }
        components.queryItems = [URLQueryItem(name: "host_id", value: hostID)]
        return components.string ?? feed
    }

    static func activity(id: String) -> String {
        "\(activities)/\(id)"
    }

    static func rsvp(id: String) -> String {
        "\(activities)/\(id)/rsvp"
    }

    static func waitlist(id: String) -> String {
        "\(activities)/\(id)/waitlist"
    }

    static func promoteWaitlist(id: String, attendeeID: String) -> String {
        "\(activities)/\(id)/waitlist/\(attendeeID)/promote"
    }

    static func reviewAttendee(activityID: String, attendeeID: String) -> String {
        "\(activities)/\(activityID)/attendees/\(attendeeID)/review"
    }

    static func assignCohost(activityID: String, attendeeID: String) -> String {
        "\(activities)/\(activityID)/attendees/\(attendeeID)/cohost"
    }

    static func cancel(id: String) -> String {
        "\(activities)/\(id)/cancel"
    }

    static func report(id: String) -> String {
        "\(activities)/\(id)/report"
    }

    static func announce(id: String) -> String {
        "\(activities)/\(id)/announce"
    }

    static func feedback(id: String) -> String {
        "\(activities)/\(id)/feedback"
    }
}

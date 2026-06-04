// Module: SparkActivity — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum ActivityAPIPath {
    private static let activities = "/v1/activities"

    static let feed = "\(activities)/feed"
    static let create = activities

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

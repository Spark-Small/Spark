// Module: SparkLikes — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum LikesAPIPath {
    private static let likes = "/v1/likes"

    static let feed = "\(likes)/feed"
    static let inbound = "\(likes)/inbound"
    static let rewind = "\(likes)/rewind"
    static let viewerProfile = "\(likes)/viewer-profile"
    static let dailyStats = "\(likes)/daily-stats"

    static func like(userID: String) -> String {
        "\(likes)/\(userID)/like"
    }

    static func pass(userID: String) -> String {
        "\(likes)/\(userID)/pass"
    }

    static func friendRequest(userID: String) -> String {
        "\(likes)/\(userID)/friend-request"
    }

    static func report(userID: String) -> String {
        "\(likes)/\(userID)/report"
    }

    static func block(userID: String) -> String {
        "\(likes)/\(userID)/block"
    }

    static func feedQuery(query: LikesFeedQuery) -> String {
        guard var components = URLComponents(string: feed) else { return feed }
        var items: [URLQueryItem] = [
            URLQueryItem(name: "gender_pref", value: query.genderPreference.wireValue),
            URLQueryItem(name: "intent", value: query.intent.wireValue)
        ]
        if let cursor = query.cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        components.queryItems = items
        return components.string ?? feed
    }
}

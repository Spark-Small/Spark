// Module: SparkCommunity — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum CommunityAPIPath {
    static let posts = "/v1/community/posts"
    static let feed = "/v1/community/feed"
    private static let communities = "/v1/community/communities"

    static func post(id: String) -> String {
        "\(posts)/\(id)"
    }

    static func replies(postID: String) -> String {
        "\(posts)/\(postID)/replies"
    }

    static func report(postID: String) -> String {
        "\(posts)/\(postID)/report"
    }

    static func community(id: String) -> String {
        "\(communities)/\(id)"
    }

    static func communityActivities(id: String) -> String {
        "\(communities)/\(id)/activities"
    }

    static func communityMembers(id: String) -> String {
        "\(communities)/\(id)/members"
    }
}

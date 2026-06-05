// Module: SparkCommunity — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum CommunityAPIPath {
    static let posts = "/v1/community/posts"
    static let feed = "/v1/community/feed"

    static func post(id: String) -> String {
        "\(posts)/\(id)"
    }

    static func replies(postID: String) -> String {
        "\(posts)/\(postID)/replies"
    }
}

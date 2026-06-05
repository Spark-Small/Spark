// Module: SparkCommunity — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum CommunityAPIPath {
    static let posts = "/v1/community/posts"

    static func post(id: String) -> String {
        "\(posts)/\(id)"
    }

    static func replies(postID: String) -> String {
        "\(posts)/\(postID)/replies"
    }
}

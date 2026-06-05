// Module: SparkCommunity — Full community post for detail screen.

import Foundation

public struct CommunityPostDetail: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let authorDisplayName: String
    public let replyCount: Int
    public let replies: [CommunityPostReply]

    public init(
        id: String,
        title: String,
        body: String,
        authorDisplayName: String,
        replyCount: Int,
        replies: [CommunityPostReply] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.replyCount = replyCount
        self.replies = replies
    }
}

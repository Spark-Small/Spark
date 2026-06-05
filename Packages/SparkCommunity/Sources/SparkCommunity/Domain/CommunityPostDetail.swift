// Module: SparkCommunity — Full community post for detail screen.

import Foundation

public struct CommunityPostDetail: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let authorDisplayName: String
    public let authorUserID: String?
    public let replyCount: Int
    public let replies: [CommunityPostReply]
    public let linkedActivity: LinkedActivityContext?

    public init(
        id: String,
        title: String,
        body: String,
        authorDisplayName: String,
        authorUserID: String? = nil,
        replyCount: Int,
        replies: [CommunityPostReply] = [],
        linkedActivity: LinkedActivityContext? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.authorUserID = authorUserID
        self.replyCount = replyCount
        self.replies = replies
        self.linkedActivity = linkedActivity
    }
}

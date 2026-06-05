// Module: SparkCommunity — Rich post card for discover feed.

import Foundation

public struct CommunityFeedPost: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let authorDisplayName: String
    public let authorUserID: String
    public let communityName: String
    public let content: String
    public let imageURL: URL?
    public let likeCount: Int
    public let commentCount: Int
    public let tags: [String]
    public let createdAt: Date
    public let sharedActivityWithViewer: SharedActivityContext?
    public let relationshipToViewer: RelationshipContext
    public let linkedActivity: LinkedActivityContext?

    public init(
        id: String,
        authorDisplayName: String,
        authorUserID: String,
        communityName: String,
        content: String,
        imageURL: URL? = nil,
        likeCount: Int,
        commentCount: Int,
        tags: [String] = [],
        createdAt: Date,
        sharedActivityWithViewer: SharedActivityContext? = nil,
        relationshipToViewer: RelationshipContext = .none,
        linkedActivity: LinkedActivityContext? = nil
    ) {
        self.id = id
        self.authorDisplayName = authorDisplayName
        self.authorUserID = authorUserID
        self.communityName = communityName
        self.content = content
        self.imageURL = imageURL
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.tags = tags
        self.createdAt = createdAt
        self.sharedActivityWithViewer = sharedActivityWithViewer
        self.relationshipToViewer = relationshipToViewer
        self.linkedActivity = linkedActivity
    }
}

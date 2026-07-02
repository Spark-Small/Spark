// Module: SparkCommunity — Full community post for detail screen.

import Foundation
import SparkCore

public struct CommunityPostDetail: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let authorDisplayName: String
    public let authorUserID: String?
    public let replyCount: Int
    public let replies: [CommunityPostReply]
    public let linkedActivity: LinkedActivityContext?
    public let mediaItems: [SparkGalleryMedia]
    public let tags: [String]
    public let kind: CommunityPostKind
    public let likeCount: Int
    public let viewerHasLiked: Bool

    public init(
        id: String,
        title: String,
        body: String,
        authorDisplayName: String,
        authorUserID: String? = nil,
        replyCount: Int,
        replies: [CommunityPostReply] = [],
        linkedActivity: LinkedActivityContext? = nil,
        mediaItems: [SparkGalleryMedia] = [],
        tags: [String] = [],
        kind: CommunityPostKind = .discussion,
        likeCount: Int = 0,
        viewerHasLiked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.authorUserID = authorUserID
        self.replyCount = replyCount
        self.replies = replies
        self.linkedActivity = linkedActivity
        self.mediaItems = mediaItems
        self.tags = tags
        self.kind = kind
        self.likeCount = max(0, likeCount)
        self.viewerHasLiked = viewerHasLiked
    }

    public var galleryMedia: [SparkGalleryMedia] { mediaItems }
}

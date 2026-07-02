// Module: SparkCommunity — Rich post card for discover feed.

import Foundation
import SparkCore

public struct CommunityFeedPost: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let authorDisplayName: String
    public let authorUserID: String
    public let authorAvatarURL: URL?
    public let communityName: String
    public let content: String
    public let imageURL: URL?
    public let mediaItems: [SparkGalleryMedia]
    public let likeCount: Int
    public let commentCount: Int
    public let tags: [String]
    public let createdAt: Date
    public let sharedActivityWithViewer: SharedActivityContext?
    public let relationshipToViewer: RelationshipContext
    public let linkedActivity: LinkedActivityContext?
    public let kind: CommunityPostKind
    public let viewerHasLiked: Bool

    public init(
        id: String,
        authorDisplayName: String,
        authorUserID: String,
        authorAvatarURL: URL? = nil,
        communityName: String,
        content: String,
        imageURL: URL? = nil,
        mediaItems: [SparkGalleryMedia] = [],
        likeCount: Int,
        commentCount: Int,
        tags: [String] = [],
        createdAt: Date,
        sharedActivityWithViewer: SharedActivityContext? = nil,
        relationshipToViewer: RelationshipContext = .none,
        linkedActivity: LinkedActivityContext? = nil,
        kind: CommunityPostKind = .discussion,
        viewerHasLiked: Bool = false
    ) {
        self.id = id
        self.authorDisplayName = authorDisplayName
        self.authorUserID = authorUserID
        self.authorAvatarURL = authorAvatarURL
        self.communityName = communityName
        self.content = content
        self.imageURL = imageURL
        self.mediaItems = mediaItems
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.tags = tags
        self.createdAt = createdAt
        self.sharedActivityWithViewer = sharedActivityWithViewer
        self.relationshipToViewer = relationshipToViewer
        self.linkedActivity = linkedActivity
        self.kind = kind
        self.viewerHasLiked = viewerHasLiked
    }

    /// Swipeable gallery; falls back to legacy `image_url` when `media` is absent.
    public var galleryMedia: [SparkGalleryMedia] {
        if !mediaItems.isEmpty { return mediaItems }
        if let imageURL {
            return [SparkGalleryMedia(id: "\(id)-cover", url: imageURL, kind: .image)]
        }
        return []
    }

    public var hasGalleryMedia: Bool { !galleryMedia.isEmpty }
}

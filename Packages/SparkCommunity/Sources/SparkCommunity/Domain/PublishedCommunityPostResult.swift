// Module: SparkCommunity — Compose publish result with gallery payload.

import Foundation
import SparkCore

public struct PublishedCommunityPostResult: Sendable, Equatable {
    public let post: CommunityPost
    public let mediaItems: [SparkGalleryMedia]

    public init(post: CommunityPost, mediaItems: [SparkGalleryMedia]) {
        self.post = post
        self.mediaItems = mediaItems
    }
}

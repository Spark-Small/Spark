// Module: SparkCommunity — Persisted like mutation result.

import Foundation

public struct CommunityPostLikeResult: Sendable, Equatable {
    public let viewerHasLiked: Bool
    public let likeCount: Int

    public init(viewerHasLiked: Bool, likeCount: Int) {
        self.viewerHasLiked = viewerHasLiked
        self.likeCount = max(0, likeCount)
    }
}

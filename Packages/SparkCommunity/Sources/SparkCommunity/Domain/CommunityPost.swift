// Module: SparkCommunity — Community post summary.

import Foundation

public struct CommunityPost: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let excerpt: String
    public let authorDisplayName: String
    public let replyCount: Int

    public init(
        id: String,
        title: String,
        excerpt: String,
        authorDisplayName: String,
        replyCount: Int
    ) {
        self.id = id
        self.title = title
        self.excerpt = excerpt
        self.authorDisplayName = authorDisplayName
        self.replyCount = replyCount
    }
}

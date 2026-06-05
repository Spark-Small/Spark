// Module: SparkCommunity — Reply on a community post thread.

import Foundation

public struct CommunityPostReply: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let body: String
    public let authorDisplayName: String
    public let createdAt: Date?

    public init(
        id: String,
        body: String,
        authorDisplayName: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.body = body
        self.authorDisplayName = authorDisplayName
        self.createdAt = createdAt
    }
}

// Module: SparkCommunity — Community group summary for carousel and list.

import Foundation

public struct CommunitySummary: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let coverURL: URL?
    public let memberCount: Int
    public let activityCount: Int
    public let hasNewPosts: Bool
    public let bio: String

    public init(
        id: String,
        name: String,
        coverURL: URL? = nil,
        memberCount: Int,
        activityCount: Int,
        hasNewPosts: Bool = false,
        bio: String = ""
    ) {
        self.id = id
        self.name = name
        self.coverURL = coverURL
        self.memberCount = memberCount
        self.activityCount = activityCount
        self.hasNewPosts = hasNewPosts
        self.bio = bio
    }
}

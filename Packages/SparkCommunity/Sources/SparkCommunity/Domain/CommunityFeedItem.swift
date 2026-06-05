// Module: SparkCommunity — Mixed discover feed row.

import Foundation

public enum CommunityFeedItem: Identifiable, Sendable, Equatable {
    case post(CommunityFeedPost)
    case peopleDiscovery([DiscoveredPerson])

    public var id: String {
        switch self {
        case .post(let post):
            "post-\(post.id)"
        case .peopleDiscovery(let people):
            "people-\(people.map(\.id).joined(separator: "-"))"
        }
    }
}

public struct CommunityTabExperience: Sendable, Equatable {
    public let joinedCommunities: [CommunitySummary]
    public let feedItems: [CommunityFeedItem]
    public let allCommunities: [CommunitySummary]

    public init(
        joinedCommunities: [CommunitySummary],
        feedItems: [CommunityFeedItem],
        allCommunities: [CommunitySummary]
    ) {
        self.joinedCommunities = joinedCommunities
        self.feedItems = feedItems
        self.allCommunities = allCommunities
    }
}

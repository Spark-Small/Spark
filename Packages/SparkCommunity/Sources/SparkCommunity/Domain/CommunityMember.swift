// Module: SparkCommunity — Community member with relationship context.

import Foundation

public struct CommunityMember: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let bio: String
    public let relationship: RelationshipContext

    public init(
        id: String,
        displayName: String,
        avatarURL: URL? = nil,
        bio: String = "",
        relationship: RelationshipContext = .none
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.relationship = relationship
    }
}

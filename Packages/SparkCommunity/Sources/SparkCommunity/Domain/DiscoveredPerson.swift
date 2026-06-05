// Module: SparkCommunity — Suggested person from shared activity context.

import Foundation

public struct DiscoveredPerson: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let sharedTag: String
    public let relationship: RelationshipContext

    public init(
        id: String,
        displayName: String,
        avatarURL: URL? = nil,
        sharedTag: String,
        relationship: RelationshipContext = .sharedActivity("")
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.sharedTag = sharedTag
        self.relationship = relationship
    }
}

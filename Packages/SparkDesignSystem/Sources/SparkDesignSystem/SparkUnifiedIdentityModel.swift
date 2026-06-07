// Module: SparkDesignSystem — Cross-tab identity presentation model.

import Foundation

public struct SparkUnifiedIdentityModel: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let bio: String
    public let trustScore: Int?
    public let hasLiveness: Bool
    public let relationshipLabel: String?

    public init(
        id: String,
        displayName: String,
        avatarURL: URL? = nil,
        bio: String = "",
        trustScore: Int? = nil,
        hasLiveness: Bool = false,
        relationshipLabel: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.trustScore = trustScore
        self.hasLiveness = hasLiveness
        self.relationshipLabel = relationshipLabel
    }
}

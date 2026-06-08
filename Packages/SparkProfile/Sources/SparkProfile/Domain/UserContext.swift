// Module: SparkProfile — Cross-tab relationship context for a user (W8/W9).

import Foundation
import SparkDesignSystem

public struct UserContext: Sendable, Equatable {
    public let userID: String
    public let displayName: String
    public let avatarURL: URL?
    public let bio: String
    public let trustScore: Int?
    public let hasLivenessVerification: Bool
    public let relationshipStatus: String?
    public let sharedActivities: [SharedActivitySummary]
    public let timeline: [UserContextTimelineEntry]

    public init(
        userID: String,
        displayName: String,
        avatarURL: URL? = nil,
        bio: String = "",
        trustScore: Int? = nil,
        hasLivenessVerification: Bool = false,
        relationshipStatus: String? = nil,
        sharedActivities: [SharedActivitySummary] = [],
        timeline: [UserContextTimelineEntry] = []
    ) {
        self.userID = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.trustScore = trustScore
        self.hasLivenessVerification = hasLivenessVerification
        self.relationshipStatus = relationshipStatus
        self.sharedActivities = sharedActivities
        self.timeline = timeline
    }

    public func unifiedIdentityModel() -> SparkUnifiedIdentityModel {
        SparkUnifiedIdentityModel(
            id: userID,
            displayName: displayName,
            avatarURL: avatarURL,
            bio: bio,
            trustScore: trustScore,
            hasLiveness: hasLivenessVerification,
            relationshipLabel: relationshipStatus,
            timelineEntries: timeline.map(\.identityEntry)
        )
    }
}

public struct SharedActivitySummary: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct UserContextTimelineEntry: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String?

    public init(id: String, title: String, detail: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
    }

    fileprivate var identityEntry: SparkIdentityTimelineEntry {
        SparkIdentityTimelineEntry(id: id, title: title, detail: detail)
    }
}

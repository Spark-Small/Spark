// Module: SparkProfile — Mock user context for previews and Mock host.

import Foundation

public struct MockUserContextRepository: UserContextRepository, Sendable {
    public init() {}

    public func fetchContext(userID: String) async throws -> UserContext {
        UserContext(
            userID: userID,
            displayName: "Mock User \(userID.suffix(4))",
            bio: "周末徒步 · 咖啡",
            trustScore: 68,
            hasLivenessVerification: true,
            relationshipStatus: String(localized: "community.relationship.matched", defaultValue: "已配对"),
            sharedActivities: [
                SharedActivitySummary(id: "act_1", title: "周末羽毛球")
            ],
            timeline: [
                UserContextTimelineEntry(
                    id: "match",
                    title: String(localized: "identity.timeline.matched", defaultValue: "配对成功", comment: "Matched"),
                    detail: "3 天前"
                ),
                UserContextTimelineEntry(
                    id: "activity",
                    title: String(localized: "identity.timeline.sharedActivity", defaultValue: "共同活动", comment: "Shared activity"),
                    detail: "周末羽毛球"
                )
            ]
        )
    }
}

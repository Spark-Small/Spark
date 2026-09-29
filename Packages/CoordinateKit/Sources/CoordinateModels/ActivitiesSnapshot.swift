import Foundation

public struct ActivitiesSnapshot: Codable, Sendable {
    public var activities: [Activity]
    public var joinedIDs: [UUID]
    public var favoriteIDs: [UUID]
    /// 当前用户候补的活动
    public var waitlistIDs: [UUID]
    /// 已为「候补名额开放」推送过本地提醒的活动（避免重复通知）
    public var waitlistSpotNotifiedIDs: [UUID]
    /// 参加用户履约旅程进度
    public var participationProgress: [ActivityParticipationProgress]
    /// 活动体验反馈标签计数（activityID → tag → count）
    public var feedbackTagCounts: [String: [String: Int]]

    public init(
        activities: [Activity],
        joinedIDs: [UUID],
        favoriteIDs: [UUID],
        waitlistIDs: [UUID] = [],
        waitlistSpotNotifiedIDs: [UUID] = [],
        participationProgress: [ActivityParticipationProgress] = [],
        feedbackTagCounts: [String: [String: Int]] = [:]
    ) {
        self.activities = activities
        self.joinedIDs = joinedIDs
        self.favoriteIDs = favoriteIDs
        self.waitlistIDs = waitlistIDs
        self.waitlistSpotNotifiedIDs = waitlistSpotNotifiedIDs
        self.participationProgress = participationProgress
        self.feedbackTagCounts = feedbackTagCounts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activities = try container.decode([Activity].self, forKey: .activities)
        joinedIDs = try container.decode([UUID].self, forKey: .joinedIDs)
        favoriteIDs = try container.decode([UUID].self, forKey: .favoriteIDs)
        waitlistIDs = try container.decodeIfPresent([UUID].self, forKey: .waitlistIDs) ?? []
        waitlistSpotNotifiedIDs = try container.decodeIfPresent(
            [UUID].self,
            forKey: .waitlistSpotNotifiedIDs
        ) ?? []
        participationProgress = try container.decodeIfPresent(
            [ActivityParticipationProgress].self,
            forKey: .participationProgress
        ) ?? []
        feedbackTagCounts = try container.decodeIfPresent(
            [String: [String: Int]].self,
            forKey: .feedbackTagCounts
        ) ?? [:]
    }
}
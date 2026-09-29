import Foundation

/// 用户侧活动参与旅程阶段（占坑 → 赴约 → 履约 → 复盘 → 关闭）。
public enum ActivityParticipationPhase: String, Codable, CaseIterable, Sendable {
    case registered
    case preparing
    case dayOf
    case inProgress
    case awaitingFeedback
    case recapEligible
    case closed
}

/// 参与旅程本地进度（与 `joinedIDs` 配套；正式版可上云同步）。
public struct ActivityParticipationProgress: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID { activityID }
    public var activityID: UUID
    public var markedArrived: Bool
    public var arrivedAt: Date?
    public var openedActivityGroup: Bool
    public var feedbackSubmitted: Bool
    public var feedbackSkipped: Bool
    /// 轻量反馈标签（如「组织好」「想再约」）
    public var feedbackHighlight: String?
    public var recapPublished: Bool
    public var recapSkipped: Bool

    enum CodingKeys: String, CodingKey {
        case activityID
        case markedArrived
        case arrivedAt
        case openedActivityGroup
        case feedbackSubmitted
        case feedbackSkipped
        case feedbackHighlight
        case recapPublished
        case recapSkipped
    }

    public init(
        activityID: UUID,
        markedArrived: Bool = false,
        arrivedAt: Date? = nil,
        openedActivityGroup: Bool = false,
        feedbackSubmitted: Bool = false,
        feedbackSkipped: Bool = false,
        feedbackHighlight: String? = nil,
        recapPublished: Bool = false,
        recapSkipped: Bool = false
    ) {
        self.activityID = activityID
        self.markedArrived = markedArrived
        self.arrivedAt = arrivedAt
        self.openedActivityGroup = openedActivityGroup
        self.feedbackSubmitted = feedbackSubmitted
        self.feedbackSkipped = feedbackSkipped
        self.feedbackHighlight = feedbackHighlight
        self.recapPublished = recapPublished
        self.recapSkipped = recapSkipped
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityID = try container.decode(UUID.self, forKey: .activityID)
        markedArrived = try container.decodeIfPresent(Bool.self, forKey: .markedArrived) ?? false
        arrivedAt = try container.decodeIfPresent(Date.self, forKey: .arrivedAt)
        openedActivityGroup = try container.decodeIfPresent(Bool.self, forKey: .openedActivityGroup) ?? false
        feedbackSubmitted = try container.decodeIfPresent(Bool.self, forKey: .feedbackSubmitted) ?? false
        feedbackSkipped = try container.decodeIfPresent(Bool.self, forKey: .feedbackSkipped) ?? false
        feedbackHighlight = try container.decodeIfPresent(String.self, forKey: .feedbackHighlight)
        recapPublished = try container.decodeIfPresent(Bool.self, forKey: .recapPublished) ?? false
        recapSkipped = try container.decodeIfPresent(Bool.self, forKey: .recapSkipped) ?? false
    }
}

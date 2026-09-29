import Foundation

public struct ActivityEngagementSnapshot: Codable, Sendable {
    public var tagWeights: [String: Double]
    public var categoryWeights: [String: Double]
    public var lastDecayAt: Date

    public init(tagWeights: [String: Double], categoryWeights: [String: Double], lastDecayAt: Date) {
        self.tagWeights = tagWeights
        self.categoryWeights = categoryWeights
        self.lastDecayAt = lastDecayAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagWeights = try container.decodeIfPresent([String: Double].self, forKey: .tagWeights) ?? [:]
        categoryWeights = try container.decodeIfPresent([String: Double].self, forKey: .categoryWeights) ?? [:]
        lastDecayAt = try container.decodeIfPresent(Date.self, forKey: .lastDecayAt) ?? .now
    }
}

public struct ProfileRecentBrowseRecord: Codable, Identifiable, Hashable, Sendable {
    public let activityID: UUID
    public var title: String
    public var viewedAt: Date

    public var id: UUID { activityID }

    public init(activityID: UUID, title: String, viewedAt: Date) {
        self.activityID = activityID
        self.title = title
        self.viewedAt = viewedAt
    }
}

/// 仅用于从旧 JSON 一次性迁入 SwiftData。
public struct ProfileRecentBrowseSnapshot: Codable, Sendable {
    public var items: [ProfileRecentBrowseRecord]


    public init(items: [ProfileRecentBrowseRecord] = []) {
        self.items = items
    }
}

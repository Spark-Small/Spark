import Foundation

/// 本地兴趣俱乐部：名称由用户自定义；与单场活动无绑定。
public struct InterestCircle: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var topic: String
    public var city: String
    public var memberCount: Int
    public var weeklyActive: Int
    public var tags: [String]
    public var summary: String
    public var systemImage: String
    public var creatorName: String
    public var createdAt: Date

    public init(
        id: UUID,
        name: String,
        topic: String,
        city: String,
        memberCount: Int,
        weeklyActive: Int,
        tags: [String],
        summary: String,
        systemImage: String,
        creatorName: String,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.topic = topic
        self.city = city
        self.memberCount = memberCount
        self.weeklyActive = weeklyActive
        self.tags = tags
        self.summary = summary
        self.systemImage = systemImage
        self.creatorName = creatorName
        self.createdAt = createdAt
    }

    public func isCreator(_ userName: String) -> Bool {
        creatorName.caseInsensitiveCompare(
            userName.trimmingCharacters(in: .whitespacesAndNewlines)
        ) == .orderedSame
    }
}

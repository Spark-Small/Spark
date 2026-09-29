import Foundation

public enum ModerationTicketStatus: String, Codable, Hashable, CaseIterable, Sendable {
    case received = "已受理"
    case reviewing = "处理中"
    case resolved = "已处理"
    case rejected = "已驳回"

    public var nextSimulated: ModerationTicketStatus? {
        switch self {
        case .received: .reviewing
        case .reviewing: .resolved
        case .resolved, .rejected: nil
        }
    }
}

public enum ModerationTargetKind: String, Codable, Hashable, CaseIterable, Sendable {
    case communityPost = "社区动态"
    case activity = "活动"
    case conversation = "会话"
    case person = "用户"
    case circle = "兴趣俱乐部"
    case guild = "陪玩工会"
    case mediaAppeal = "内容误杀申诉"
    case identityAppeal = "形象认证申诉"

    public var systemImage: String {
        switch self {
        case .communityPost: "photo.on.rectangle"
        case .activity: "calendar"
        case .conversation: "bubble.left"
        case .person: "person.crop.circle"
        case .circle: "person.3"
        case .guild: "building.2"
        case .mediaAppeal: "exclamationmark.bubble"
        case .identityAppeal: "person.crop.circle.badge.exclamationmark"
        }
    }
}

public struct ModerationTicket: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var postID: UUID
    public var postTitle: String
    public var reason: String
    public var createdAt: Date
    public var status: ModerationTicketStatus
    public var targetKind: ModerationTargetKind
    public var updatedAt: Date?

    public init(
        id: UUID = UUID(),
        postID: UUID,
        postTitle: String,
        reason: String,
        createdAt: Date = .now,
        status: ModerationTicketStatus = .received,
        targetKind: ModerationTargetKind = .communityPost,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.postID = postID
        self.postTitle = postTitle
        self.reason = reason
        self.createdAt = createdAt
        self.status = status
        self.targetKind = targetKind
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        postID = try container.decode(UUID.self, forKey: .postID)
        postTitle = try container.decode(String.self, forKey: .postTitle)
        reason = try container.decode(String.self, forKey: .reason)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let status = try container.decodeIfPresent(ModerationTicketStatus.self, forKey: .status) {
            self.status = status
        } else if let legacy = try container.decodeIfPresent(String.self, forKey: .status),
                  let mapped = ModerationTicketStatus(rawValue: legacy) {
            self.status = mapped
        } else {
            self.status = .received
        }
        targetKind = try container.decodeIfPresent(ModerationTargetKind.self, forKey: .targetKind)
            ?? .communityPost
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

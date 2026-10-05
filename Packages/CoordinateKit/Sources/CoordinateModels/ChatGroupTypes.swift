//
//  ChatGroupTypes.swift
//  CoordinateModels
//
//  群成员、转账与通话会话类型。
//

import Foundation

public enum GroupMemberRole: String, Hashable, Codable, CaseIterable, Sendable {
    case owner = "群主"
    case admin = "管理员"
    case member = "成员"

    public var canManageMembers: Bool {
        self == .owner || self == .admin
    }
}

public struct GroupMemberRecord: Identifiable, Hashable, Codable, Sendable {
    public var id: String { nickname.lowercased() }
    public var nickname: String
    public var role: GroupMemberRole
    public var joinedAt: Date
    /// 本群昵称（与真实昵称不同时展示为 真实名（群昵称））
    public var groupAlias: String?

    public init(
        nickname: String,
        role: GroupMemberRole = .member,
        joinedAt: Date = .now,
        groupAlias: String? = nil
    ) {
        self.nickname = nickname
        self.role = role
        self.joinedAt = joinedAt
        self.groupAlias = groupAlias
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        role = try container.decode(GroupMemberRole.self, forKey: .role)
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? .now
        groupAlias = try container.decodeIfPresent(String.self, forKey: .groupAlias)
    }
}

public enum TransferStatus: String, Hashable, Codable, CaseIterable, Sendable {
    case pending = "待收款"
    case accepted = "已收款"
    case expired = "已过期"
    case cancelled = "已取消"
    case refunded = "已退回"

    public var isTerminal: Bool {
        switch self {
        case .pending: false
        case .accepted, .expired, .cancelled, .refunded: true
        }
    }
}

public struct TransferRecord: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var conversationID: UUID
    public var amount: Double
    public var senderName: String
    public var recipientName: String
    public var status: TransferStatus
    public var createdAt: Date
    public var updatedAt: Date?
    public var messageID: UUID

    public init(
        id: UUID = UUID(),
        conversationID: UUID,
        amount: Double,
        senderName: String,
        recipientName: String,
        status: TransferStatus = .pending,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        messageID: UUID
    ) {
        self.id = id
        self.conversationID = conversationID
        self.amount = amount
        self.senderName = senderName
        self.recipientName = recipientName
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageID = messageID
    }

    public var expiresAt: Date {
        createdAt.addingTimeInterval(TransferLifecycle.pendingTTL)
    }

    public var isPastExpiration: Bool {
        status == .pending && Date.now >= expiresAt
    }

    public var pendingTimeRemaining: TimeInterval? {
        guard status == .pending else { return nil }
        return max(expiresAt.timeIntervalSinceNow, 0)
    }
}

public enum CallSessionKind: String, Hashable, Codable, CaseIterable, Sendable {
    case voice = "语音通话"
    case video = "视频通话"

    public var systemImage: String {
        switch self {
        case .voice: "phone.fill"
        case .video: "video.fill"
        }
    }
}

public enum CallSessionDirection: String, Hashable, Codable, Sendable {
    case outgoing
    case incoming
}

public enum CallSessionStatus: String, Hashable, Codable, CaseIterable, Sendable {
    case ringing = "响铃中"
    case connecting = "连接中"
    case active = "通话中"
    case ended = "已结束"
    case missed = "未接听"
    case cancelled = "已取消"
    case rejected = "已拒绝"

    public var isLive: Bool {
        self == .ringing || self == .connecting || self == .active
    }
}

public struct CallSessionRecord: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var conversationID: UUID
    public var kind: CallSessionKind
    public var direction: CallSessionDirection
    public var status: CallSessionStatus
    public var startedAt: Date
    public var connectedAt: Date?
    public var endedAt: Date?

    public init(
        id: UUID = UUID(),
        conversationID: UUID,
        kind: CallSessionKind,
        direction: CallSessionDirection = .outgoing,
        status: CallSessionStatus = .ringing,
        startedAt: Date = .now,
        connectedAt: Date? = nil,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.conversationID = conversationID
        self.kind = kind
        self.direction = direction
        self.status = status
        self.startedAt = startedAt
        self.connectedAt = connectedAt
        self.endedAt = endedAt
    }

    public var historyDetail: String {
        switch status {
        case .ended:
            if let connectedAt, let endedAt {
                let duration = max(Int(endedAt.timeIntervalSince(connectedAt)), 0)
                return "\(status.rawValue) · \(String(format: "%02d:%02d", duration / 60, duration % 60))"
            }
            return status.rawValue
        case .ringing, .connecting, .active, .missed, .cancelled, .rejected:
            return status.rawValue
        }
    }
}


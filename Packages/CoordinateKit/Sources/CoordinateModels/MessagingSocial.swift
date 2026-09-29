import Foundation

public enum FriendRequestStatus: String, Hashable, Codable, Sendable {
    case pending
    case accepted
    case declined
}

/// Ins 式消息请求 / 好友申请
public struct FriendRequest: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var fromName: String
    public var message: String
    public var createdAt: Date
    public var status: FriendRequestStatus

    public init(
        id: UUID,
        fromName: String,
        message: String,
        createdAt: Date,
        status: FriendRequestStatus = .pending
    ) {
        self.id = id
        self.fromName = fromName
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
}

/// 我方向他人发出的好友申请（等待对方通过）。
public struct OutgoingFriendRequest: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var toName: String
    public var message: String
    public var createdAt: Date
    public var status: FriendRequestStatus

    public init(
        id: UUID = UUID(),
        toName: String,
        message: String,
        createdAt: Date = .now,
        status: FriendRequestStatus = .pending
    ) {
        self.id = id
        self.toName = toName
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
}

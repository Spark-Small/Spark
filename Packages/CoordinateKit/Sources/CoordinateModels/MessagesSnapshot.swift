import Foundation

public struct MessagesSnapshot: Codable, Sendable {
    public var conversations: [ChatConversation]
    /// UUID.uuidString → messages
    public var threads: [String: [ChatMessage]]
    public var friendRequests: [FriendRequest]
    public var outgoingFriendRequests: [OutgoingFriendRequest]
    /// 昵称（小写）→ 备注
    public var friendRemarks: [String: String]
    /// 昵称（小写）→ 好友分组
    public var friendGroups: [String: String]
    /// conversationID.uuidString → 群成员（含角色）
    public var groupMembers: [String: [GroupMemberRecord]]
    /// 转账流水（消息气泡引用实体）
    public var transferRecords: [TransferRecord]
    /// 本地音视频通话记录
    public var callRecords: [CallSessionRecord]

    public init(
        conversations: [ChatConversation],
        threads: [String: [ChatMessage]],
        friendRequests: [FriendRequest] = [],
        outgoingFriendRequests: [OutgoingFriendRequest] = [],
        friendRemarks: [String: String] = [:],
        friendGroups: [String: String] = [:],
        groupMembers: [String: [GroupMemberRecord]] = [:],
        transferRecords: [TransferRecord] = [],
        callRecords: [CallSessionRecord] = []
    ) {
        self.conversations = conversations
        self.threads = threads
        self.friendRequests = friendRequests
        self.outgoingFriendRequests = outgoingFriendRequests
        self.friendRemarks = friendRemarks
        self.friendGroups = friendGroups
        self.groupMembers = groupMembers
        self.transferRecords = transferRecords
        self.callRecords = callRecords
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversations = try container.decode([ChatConversation].self, forKey: .conversations)
        threads = try container.decode([String: [ChatMessage]].self, forKey: .threads)
        friendRequests = try container.decodeIfPresent([FriendRequest].self, forKey: .friendRequests) ?? []
        outgoingFriendRequests = try container.decodeIfPresent(
            [OutgoingFriendRequest].self,
            forKey: .outgoingFriendRequests
        ) ?? []
        friendRemarks = try container.decodeIfPresent([String: String].self, forKey: .friendRemarks) ?? [:]
        friendGroups = try container.decodeIfPresent([String: String].self, forKey: .friendGroups) ?? [:]
        groupMembers = try container.decodeIfPresent([String: [GroupMemberRecord]].self, forKey: .groupMembers) ?? [:]
        transferRecords = try container.decodeIfPresent([TransferRecord].self, forKey: .transferRecords) ?? []
        callRecords = try container.decodeIfPresent([CallSessionRecord].self, forKey: .callRecords) ?? []
    }
}
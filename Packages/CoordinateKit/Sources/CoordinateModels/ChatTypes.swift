import Foundation

public struct ChatConversation: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var subtitle: String
    public var lastMessage: String
    public var updatedAt: Date
    public var unreadCount: Int
    public var kind: ChatKind
    public var isPinned: Bool
    public var isMuted: Bool
    /// 活动群的举行时间；私聊 / 官方为空
    public var eventAt: Date?
    /// 关联活动；旧会话可能为 nil，去重时 fallback 标题
    public var relatedActivityID: UUID?
    /// 关联兴趣俱乐部（俱乐部群）
    public var relatedCircleID: UUID?
    /// 收件箱预览是否来自自己（微信「我：」）
    public var lastMessageIsMe: Bool
    /// 活动群群主（活动发起人昵称）
    public var ownerName: String?
    /// 群成员昵称（本地演示）
    public var memberNames: [String]
    /// 群公告
    public var announcement: String?
    /// Ins 式消息请求（未接受前单独列表）
    public var isMessageRequest: Bool
    /// 请求来源：好友申请 / 陌生人消息 / 群邀请
    public var requestSource: MessageRequestSource?
    /// 请求列表预览文案（为空时回退 inboxPreview）
    public var requestPreviewText: String?
    /// Ins Active now（本地演示）
    public var peerIsActive: Bool
    /// 双向好友关系（接受申请 / UID 添加后为 true；临时会话为 false）
    public var isFriend: Bool

    public init(
        id: UUID,
        title: String,
        subtitle: String,
        lastMessage: String,
        updatedAt: Date,
        unreadCount: Int,
        kind: ChatKind,
        isPinned: Bool = false,
        isMuted: Bool = false,
        eventAt: Date? = nil,
        relatedActivityID: UUID? = nil,
        relatedCircleID: UUID? = nil,
        lastMessageIsMe: Bool = false,
        ownerName: String? = nil,
        memberNames: [String] = [],
        announcement: String? = nil,
        isMessageRequest: Bool = false,
        requestSource: MessageRequestSource? = nil,
        requestPreviewText: String? = nil,
        peerIsActive: Bool = false,
        isFriend: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        self.kind = kind
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.eventAt = eventAt
        self.relatedActivityID = relatedActivityID
        self.relatedCircleID = relatedCircleID
        self.lastMessageIsMe = lastMessageIsMe
        self.ownerName = ownerName
        self.memberNames = memberNames
        self.announcement = announcement
        self.isMessageRequest = isMessageRequest
        self.requestSource = requestSource
        self.requestPreviewText = requestPreviewText
        self.peerIsActive = peerIsActive
        self.isFriend = isFriend
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        kind = try container.decode(ChatKind.self, forKey: .kind)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false
        eventAt = try container.decodeIfPresent(Date.self, forKey: .eventAt)
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
        relatedCircleID = try container.decodeIfPresent(UUID.self, forKey: .relatedCircleID)
        lastMessageIsMe = try container.decodeIfPresent(Bool.self, forKey: .lastMessageIsMe) ?? false
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
        memberNames = try container.decodeIfPresent([String].self, forKey: .memberNames) ?? []
        announcement = try container.decodeIfPresent(String.self, forKey: .announcement)
        isMessageRequest = try container.decodeIfPresent(Bool.self, forKey: .isMessageRequest) ?? false
        requestSource = try container.decodeIfPresent(MessageRequestSource.self, forKey: .requestSource)
        requestPreviewText = try container.decodeIfPresent(String.self, forKey: .requestPreviewText)
        peerIsActive = try container.decodeIfPresent(Bool.self, forKey: .peerIsActive) ?? false
        if let decodedFriend = try container.decodeIfPresent(Bool.self, forKey: .isFriend) {
            isFriend = decodedFriend
        } else {
            isFriend = kind == .direct && !isMessageRequest && subtitle == "好友"
        }
    }

    public var isGroup: Bool { kind == .activity || kind == .circle || kind == .group }

    public var kindLabel: String {
        switch kind {
        case .activity, .group: "群聊"
        case .circle: "俱乐部"
        case .direct: "好友"
        case .notice: "通知"
        }
    }

    public var systemImage: String {
        switch kind {
        case .activity: "person.crop.rectangle.stack.fill"
        case .circle, .group: "person.3.fill"
        case .direct: "message.fill"
        case .notice: "megaphone.fill"
        }
    }

    public var isFriendChat: Bool { kind == .direct }
    public var isActivityGroup: Bool { kind == .activity }
    public var isCircleGroup: Bool { kind == .circle }
    public var isPeerGroup: Bool { kind == .group }
    public var isSocialGroup: Bool { isActivityGroup || isCircleGroup || isPeerGroup }

    public func isOwned(by userName: String) -> Bool {
        guard let ownerName, !ownerName.isEmpty else { return false }
        return ownerName.caseInsensitiveCompare(userName) == .orderedSame
    }

    public var inboxPreview: String {
        if lastMessageIsMe {
            if lastMessage.hasPrefix("我：") || lastMessage.hasPrefix("我:") {
                return lastMessage
            }
            return "我：\(lastMessage)"
        }
        return lastMessage
    }

    public var requestPreview: String {
        if let requestPreviewText, !requestPreviewText.isEmpty {
            return requestPreviewText
        }
        return inboxPreview
    }
}

public enum ChatKind: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// 活动群聊（一场局一个群）
    case activity = "活动群"
    /// 兴趣俱乐部群（加入俱乐部进入）
    case circle = "俱乐部群"
    /// 选多人发起的好友群
    case group = "群聊"
    /// 好友私聊（搭子 / 陪玩 / 主办等均落此类型，不做临时会话）
    case direct = "私聊"
    /// 平台通知（只读，非社交）
    case notice = "官方"

    public var id: String { rawValue }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case Self.activity.rawValue: self = .activity
        case Self.circle.rawValue, "组织群", "圈子群": self = .circle
        case Self.group.rawValue: self = .group
        case Self.direct.rawValue: self = .direct
        case Self.notice.rawValue: self = .notice
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown ChatKind \(raw)")
            )
        }
    }
}

public struct ChatMessage: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var sender: String
    public var text: String
    public var sentAt: Date
    public var isMe: Bool
    public var messageKind: ChatMessageKind
    /// Ins 式点心 / 表情回应
    public var isLiked: Bool
    public var reaction: String?
    /// 微信式引用回复
    public var replyToSender: String?
    public var replyToText: String?
    /// 微信式进群/退群等系统小字
    public var isSystem: Bool
    public var systemAudience: ChatSystemAudience
    /// 图片：CommunityPhotoStore 文件名
    public var mediaLocalName: String?
    /// 语音秒数
    public var voiceDuration: Double?
    /// 位置
    public var locationName: String?
    public var latitude: Double?
    public var longitude: Double?
    /// 链接 / 社区分享卡
    public var linkTitle: String?
    public var linkSubtitle: String?
    public var linkURLString: String?
    /// 活动卡
    public var cardActivityID: UUID?
    /// 转账金额（演示）
    public var transferAmount: Double?
    /// 转账实体 id（新链路；旧快照仍兼容 transferAmount）
    public var transferID: UUID?
    /// 送达 / 已读（本地模拟）
    public var deliveryStatus: ChatDeliveryStatus

    public init(
        id: UUID,
        sender: String,
        text: String,
        sentAt: Date,
        isMe: Bool,
        messageKind: ChatMessageKind = .text,
        isLiked: Bool = false,
        reaction: String? = nil,
        replyToSender: String? = nil,
        replyToText: String? = nil,
        isSystem: Bool = false,
        systemAudience: ChatSystemAudience = .everyone,
        mediaLocalName: String? = nil,
        voiceDuration: Double? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        linkTitle: String? = nil,
        linkSubtitle: String? = nil,
        linkURLString: String? = nil,
        cardActivityID: UUID? = nil,
        transferAmount: Double? = nil,
        transferID: UUID? = nil,
        deliveryStatus: ChatDeliveryStatus = .sent
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.sentAt = sentAt
        self.isMe = isMe
        self.messageKind = messageKind
        self.isLiked = isLiked
        self.reaction = reaction
        self.replyToSender = replyToSender
        self.replyToText = replyToText
        self.isSystem = isSystem
        self.systemAudience = systemAudience
        self.mediaLocalName = mediaLocalName
        self.voiceDuration = voiceDuration
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.linkTitle = linkTitle
        self.linkSubtitle = linkSubtitle
        self.linkURLString = linkURLString
        self.cardActivityID = cardActivityID
        self.transferAmount = transferAmount
        self.transferID = transferID
        self.deliveryStatus = deliveryStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sender = try container.decode(String.self, forKey: .sender)
        text = try container.decode(String.self, forKey: .text)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        isMe = try container.decode(Bool.self, forKey: .isMe)
        messageKind = try container.decodeIfPresent(ChatMessageKind.self, forKey: .messageKind) ?? .text
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        reaction = try container.decodeIfPresent(String.self, forKey: .reaction)
        replyToSender = try container.decodeIfPresent(String.self, forKey: .replyToSender)
        replyToText = try container.decodeIfPresent(String.self, forKey: .replyToText)
        isSystem = try container.decodeIfPresent(Bool.self, forKey: .isSystem) ?? false
        systemAudience = try container.decodeIfPresent(ChatSystemAudience.self, forKey: .systemAudience) ?? .everyone
        mediaLocalName = try container.decodeIfPresent(String.self, forKey: .mediaLocalName)
        voiceDuration = try container.decodeIfPresent(Double.self, forKey: .voiceDuration)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        linkTitle = try container.decodeIfPresent(String.self, forKey: .linkTitle)
        linkSubtitle = try container.decodeIfPresent(String.self, forKey: .linkSubtitle)
        linkURLString = try container.decodeIfPresent(String.self, forKey: .linkURLString)
        cardActivityID = try container.decodeIfPresent(UUID.self, forKey: .cardActivityID)
        transferAmount = try container.decodeIfPresent(Double.self, forKey: .transferAmount)
        transferID = try container.decodeIfPresent(UUID.self, forKey: .transferID)
        deliveryStatus = try container.decodeIfPresent(ChatDeliveryStatus.self, forKey: .deliveryStatus) ?? .sent
    }

    public var previewText: String {
        if isSystem { return text }
        switch messageKind {
        case .text, .sticker: return text
        case .image: return "[图片]"
        case .voice: return "[语音]"
        case .location: return "[位置] \(locationName ?? "")"
        case .link: return "[链接] \(linkTitle ?? text)"
        case .activity: return "[活动] \(text)"
        case .transfer: return "[转账] ¥\(String(format: "%.2f", transferAmount ?? 0))"
        }
    }

    public static func systemTip(
        _ text: String,
        audience: ChatSystemAudience = .everyone,
        at date: Date = .now
    ) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            sender: "",
            text: text,
            sentAt: date,
            isMe: false,
            messageKind: .text,
            isSystem: true,
            systemAudience: audience
        )
    }
}

public enum ChatMessageKind: String, Hashable, Codable, CaseIterable, Sendable {
    case text
    case image
    case voice
    case location
    case link
    case activity
    case transfer
    case sticker
}

public enum ChatDeliveryStatus: String, Hashable, Codable, Sendable {
    case sent
    case delivered
    case read
    case failed
}

public enum ChatSystemAudience: String, Hashable, Codable, Sendable {
    case everyone
    case hostOnly
}

public enum MessageRequestSource: String, Hashable, Codable, CaseIterable, Sendable {
    case friend = "好友申请"
    case directMessage = "陌生人消息"
    case groupInvite = "群聊邀请"
}

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


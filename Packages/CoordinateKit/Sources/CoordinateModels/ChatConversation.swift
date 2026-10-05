//
//  ChatConversation.swift
//  CoordinateModels
//
//  会话与会话类型。
//

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
        isFriend: Bool? = nil
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
        // 与 Codable 回退一致：副标题「好友」的私聊视为已是好友（种子数据常只写 subtitle）
        self.isFriend = isFriend ?? (kind == .direct && !isMessageRequest && subtitle == "好友")
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


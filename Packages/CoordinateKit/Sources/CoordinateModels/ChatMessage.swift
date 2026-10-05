//
//  ChatMessage.swift
//  CoordinateModels
//
//  消息体与投递 / 请求来源。
//

import Foundation

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
    /// 编辑时间（本机）；`nil` 表示未编辑
    public var editedAt: Date?
    /// 已撤回（本机展示为系统小字）
    public var isRecalled: Bool

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
        deliveryStatus: ChatDeliveryStatus = .sent,
        editedAt: Date? = nil,
        isRecalled: Bool = false
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
        self.editedAt = editedAt
        self.isRecalled = isRecalled
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
        editedAt = try container.decodeIfPresent(Date.self, forKey: .editedAt)
        isRecalled = try container.decodeIfPresent(Bool.self, forKey: .isRecalled) ?? false
    }

    public var previewText: String {
        if isRecalled { return "[已撤回]" }
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


import Foundation

/// 加入圈子 / 关注工会后的本地成员设置
public struct OrgMembershipPrefs: Codable, Hashable, Sendable {
    public var muteNotifications: Bool
    public var isPinned: Bool
    public var showMemberNicknames: Bool
    /// 我在本群的昵称；为空表示与账号昵称一致
    public var myGroupNickname: String
    public var joinedAt: Date
    /// 允许二维码进群
    public var allowJoinViaQR: Bool
    /// 进群需群主 / 管理员确认
    public var joinRequiresApproval: Bool
    /// 仅群主 / 管理员可改群名
    public var onlyAdminCanRename: Bool
    /// 免打扰时仍通知 @我
    public var notifyWhenMutedAtMe: Bool
    /// 免打扰时仍通知 @所有人
    public var notifyWhenMutedAtAll: Bool
    /// 免打扰时仍通知群公告
    public var notifyWhenMutedAnnouncement: Bool

    public static func fresh(at date: Date = .now) -> OrgMembershipPrefs {
        OrgMembershipPrefs(
            muteNotifications: false,
            isPinned: false,
            showMemberNicknames: true,
            myGroupNickname: "",
            joinedAt: date
        )
    }

    public init(
        muteNotifications: Bool = false,
        isPinned: Bool = false,
        showMemberNicknames: Bool = true,
        myGroupNickname: String = "",
        joinedAt: Date = .now,
        allowJoinViaQR: Bool = true,
        joinRequiresApproval: Bool = false,
        onlyAdminCanRename: Bool = true,
        notifyWhenMutedAtMe: Bool = true,
        notifyWhenMutedAtAll: Bool = true,
        notifyWhenMutedAnnouncement: Bool = true
    ) {
        self.muteNotifications = muteNotifications
        self.isPinned = isPinned
        self.showMemberNicknames = showMemberNicknames
        self.myGroupNickname = myGroupNickname
        self.joinedAt = joinedAt
        self.allowJoinViaQR = allowJoinViaQR
        self.joinRequiresApproval = joinRequiresApproval
        self.onlyAdminCanRename = onlyAdminCanRename
        self.notifyWhenMutedAtMe = notifyWhenMutedAtMe
        self.notifyWhenMutedAtAll = notifyWhenMutedAtAll
        self.notifyWhenMutedAnnouncement = notifyWhenMutedAnnouncement
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        muteNotifications = try container.decodeIfPresent(Bool.self, forKey: .muteNotifications) ?? false
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        showMemberNicknames = try container.decodeIfPresent(Bool.self, forKey: .showMemberNicknames) ?? true
        myGroupNickname = try container.decodeIfPresent(String.self, forKey: .myGroupNickname) ?? ""
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? .now
        allowJoinViaQR = try container.decodeIfPresent(Bool.self, forKey: .allowJoinViaQR) ?? true
        joinRequiresApproval = try container.decodeIfPresent(Bool.self, forKey: .joinRequiresApproval) ?? false
        onlyAdminCanRename = try container.decodeIfPresent(Bool.self, forKey: .onlyAdminCanRename) ?? true
        notifyWhenMutedAtMe = try container.decodeIfPresent(Bool.self, forKey: .notifyWhenMutedAtMe) ?? true
        notifyWhenMutedAtAll = try container.decodeIfPresent(Bool.self, forKey: .notifyWhenMutedAtAll) ?? true
        notifyWhenMutedAnnouncement = try container.decodeIfPresent(Bool.self, forKey: .notifyWhenMutedAnnouncement) ?? true
        _ = try container.decodeIfPresent(String.self, forKey: .remark)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(muteNotifications, forKey: .muteNotifications)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(showMemberNicknames, forKey: .showMemberNicknames)
        try container.encode(myGroupNickname, forKey: .myGroupNickname)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(allowJoinViaQR, forKey: .allowJoinViaQR)
        try container.encode(joinRequiresApproval, forKey: .joinRequiresApproval)
        try container.encode(onlyAdminCanRename, forKey: .onlyAdminCanRename)
        try container.encode(notifyWhenMutedAtMe, forKey: .notifyWhenMutedAtMe)
        try container.encode(notifyWhenMutedAtAll, forKey: .notifyWhenMutedAtAll)
        try container.encode(notifyWhenMutedAnnouncement, forKey: .notifyWhenMutedAnnouncement)
    }

    private enum CodingKeys: String, CodingKey {
        case muteNotifications, isPinned, showMemberNicknames, myGroupNickname, joinedAt, remark
        case allowJoinViaQR, joinRequiresApproval, onlyAdminCanRename
        case notifyWhenMutedAtMe, notifyWhenMutedAtAll, notifyWhenMutedAnnouncement
    }
}

public enum OrgMembershipKind: String, Hashable, Sendable {
    case circle
    case guild

    public func prefsKey(name: String) -> String { "\(rawValue):\(name)" }
}

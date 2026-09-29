import Foundation

public struct BuddiesSnapshot: Codable, Sendable {
    public var inviteRecords: [BuddyInviteRecord]
    public var bookingRecords: [BuddyBookingRecord]
    /// 用户创建的俱乐部（持久化）
    public var clubs: [InterestCircle]
    /// 已加入俱乐部 ID（主键）
    public var joinedCircleIDs: [UUID]
    /// 兼容旧版按名称记录；新写入由 `joinedCircleIDs` 派生
    public var joinedCircleNames: [String]
    public var joinedGuildNames: [String]
    /// 俱乐部 / 工会成员偏好（免打扰、置顶、备注等），key 如 `circle:黄浦夜骑群`
    public var membershipPrefs: [String: OrgMembershipPrefs]

    public init(
        inviteRecords: [BuddyInviteRecord],
        bookingRecords: [BuddyBookingRecord],
        clubs: [InterestCircle] = [],
        joinedCircleIDs: [UUID] = [],
        joinedCircleNames: [String] = [],
        joinedGuildNames: [String] = [],
        membershipPrefs: [String: OrgMembershipPrefs] = [:]
    ) {
        self.inviteRecords = inviteRecords
        self.bookingRecords = bookingRecords
        self.clubs = clubs
        self.joinedCircleIDs = joinedCircleIDs
        self.joinedCircleNames = joinedCircleNames
        self.joinedGuildNames = joinedGuildNames
        self.membershipPrefs = membershipPrefs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inviteRecords = try container.decode([BuddyInviteRecord].self, forKey: .inviteRecords)
        bookingRecords = try container.decode([BuddyBookingRecord].self, forKey: .bookingRecords)
        clubs = try container.decodeIfPresent([InterestCircle].self, forKey: .clubs) ?? []
        joinedCircleIDs = try container.decodeIfPresent([UUID].self, forKey: .joinedCircleIDs) ?? []
        joinedCircleNames = try container.decodeIfPresent([String].self, forKey: .joinedCircleNames)
            ?? []
        joinedGuildNames = try container.decodeIfPresent([String].self, forKey: .joinedGuildNames)
            ?? []
        membershipPrefs = try container.decodeIfPresent([String: OrgMembershipPrefs].self, forKey: .membershipPrefs)
            ?? [:]
    }
}

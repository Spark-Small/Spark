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
    /// 远程发现目录（可选）；缺省表示服务端未下发，客户端不得用 Sample 冒充
    public var discoverCatalog: BuddiesDiscoverCatalog?

    public init(
        inviteRecords: [BuddyInviteRecord],
        bookingRecords: [BuddyBookingRecord],
        clubs: [InterestCircle] = [],
        joinedCircleIDs: [UUID] = [],
        joinedCircleNames: [String] = [],
        joinedGuildNames: [String] = [],
        membershipPrefs: [String: OrgMembershipPrefs] = [:],
        discoverCatalog: BuddiesDiscoverCatalog? = nil
    ) {
        self.inviteRecords = inviteRecords
        self.bookingRecords = bookingRecords
        self.clubs = clubs
        self.joinedCircleIDs = joinedCircleIDs
        self.joinedCircleNames = joinedCircleNames
        self.joinedGuildNames = joinedGuildNames
        self.membershipPrefs = membershipPrefs
        self.discoverCatalog = discoverCatalog
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
        discoverCatalog = try container.decodeIfPresent(BuddiesDiscoverCatalog.self, forKey: .discoverCatalog)
    }
}

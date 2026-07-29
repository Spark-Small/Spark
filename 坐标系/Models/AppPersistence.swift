//
//  AppPersistence.swift
//  坐标系
//

import Foundation

struct ActivitiesSnapshot: Codable {
    var activities: [Activity]
    var joinedIDs: [UUID]
    var favoriteIDs: [UUID]
    /// 当前用户候补的活动
    var waitlistIDs: [UUID]
    /// 已为「候补名额开放」推送过本地提醒的活动（避免重复通知）
    var waitlistSpotNotifiedIDs: [UUID]

    static var seed: ActivitiesSnapshot {
        ActivitiesSnapshot(
            activities: SampleData.activities,
            joinedIDs: [SampleData.activities[1].id, SampleData.activities[6].id],
            favoriteIDs: [SampleData.activities[3].id],
            waitlistIDs: [SampleData.activities[10].id],
            waitlistSpotNotifiedIDs: []
        )
    }

    init(
        activities: [Activity],
        joinedIDs: [UUID],
        favoriteIDs: [UUID],
        waitlistIDs: [UUID] = [],
        waitlistSpotNotifiedIDs: [UUID] = []
    ) {
        self.activities = activities
        self.joinedIDs = joinedIDs
        self.favoriteIDs = favoriteIDs
        self.waitlistIDs = waitlistIDs
        self.waitlistSpotNotifiedIDs = waitlistSpotNotifiedIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activities = try container.decode([Activity].self, forKey: .activities)
        joinedIDs = try container.decode([UUID].self, forKey: .joinedIDs)
        favoriteIDs = try container.decode([UUID].self, forKey: .favoriteIDs)
        waitlistIDs = try container.decodeIfPresent([UUID].self, forKey: .waitlistIDs) ?? []
        waitlistSpotNotifiedIDs = try container.decodeIfPresent(
            [UUID].self,
            forKey: .waitlistSpotNotifiedIDs
        ) ?? []
    }
}

struct MessagesSnapshot: Codable {
    var conversations: [ChatConversation]
    /// UUID.uuidString → messages
    var threads: [String: [ChatMessage]]
    var friendRequests: [FriendRequest]
    /// 昵称（小写）→ 备注
    var friendRemarks: [String: String]
    /// 昵称（小写）→ 好友分组
    var friendGroups: [String: String]
    /// conversationID.uuidString → 群成员（含角色）
    var groupMembers: [String: [GroupMemberRecord]]
    /// 转账流水（消息气泡引用实体）
    var transferRecords: [TransferRecord]
    /// 本地音视频通话记录
    var callRecords: [CallSessionRecord]

    static var seed: MessagesSnapshot {
        let conversations = SampleData.conversations
        var threads: [String: [ChatMessage]] = [:]
        for conversation in conversations {
            threads[conversation.id.uuidString] = SampleData.messages(for: conversation.id)
        }
        return MessagesSnapshot(
            conversations: conversations,
            threads: threads,
            friendRequests: SampleData.friendRequests
        )
    }

    init(
        conversations: [ChatConversation],
        threads: [String: [ChatMessage]],
        friendRequests: [FriendRequest] = [],
        friendRemarks: [String: String] = [:],
        friendGroups: [String: String] = [:],
        groupMembers: [String: [GroupMemberRecord]] = [:],
        transferRecords: [TransferRecord] = [],
        callRecords: [CallSessionRecord] = []
    ) {
        self.conversations = conversations
        self.threads = threads
        self.friendRequests = friendRequests
        self.friendRemarks = friendRemarks
        self.friendGroups = friendGroups
        self.groupMembers = groupMembers
        self.transferRecords = transferRecords
        self.callRecords = callRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversations = try container.decode([ChatConversation].self, forKey: .conversations)
        threads = try container.decode([String: [ChatMessage]].self, forKey: .threads)
        friendRequests = try container.decodeIfPresent([FriendRequest].self, forKey: .friendRequests) ?? []
        friendRemarks = try container.decodeIfPresent([String: String].self, forKey: .friendRemarks) ?? [:]
        friendGroups = try container.decodeIfPresent([String: String].self, forKey: .friendGroups) ?? [:]
        groupMembers = try container.decodeIfPresent([String: [GroupMemberRecord]].self, forKey: .groupMembers) ?? [:]
        transferRecords = try container.decodeIfPresent([TransferRecord].self, forKey: .transferRecords) ?? []
        callRecords = try container.decodeIfPresent([CallSessionRecord].self, forKey: .callRecords) ?? []
    }
}

struct ProfileSnapshot: Codable {
    var user: AppUser
    var hasCompletedOnboarding: Bool
    var blockedUserNames: [String]
    var moderationTickets: [ModerationTicket]

    static var seed: ProfileSnapshot {
        ProfileSnapshot(
            user: SampleData.currentUser,
            hasCompletedOnboarding: false,
            blockedUserNames: [],
            moderationTickets: []
        )
    }

    init(
        user: AppUser,
        hasCompletedOnboarding: Bool,
        blockedUserNames: [String] = [],
        moderationTickets: [ModerationTicket] = []
    ) {
        self.user = user
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.blockedUserNames = blockedUserNames
        self.moderationTickets = moderationTickets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(AppUser.self, forKey: .user)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        blockedUserNames = try container.decodeIfPresent([String].self, forKey: .blockedUserNames) ?? []
        moderationTickets = try container.decodeIfPresent([ModerationTicket].self, forKey: .moderationTickets) ?? []
    }
}

enum ModerationTicketStatus: String, Codable, Hashable, CaseIterable {
    case received = "已受理"
    case reviewing = "处理中"
    case resolved = "已处理"
    case rejected = "已驳回"

    var nextSimulated: ModerationTicketStatus? {
        switch self {
        case .received: .reviewing
        case .reviewing: .resolved
        case .resolved, .rejected: nil
        }
    }
}

enum ModerationTargetKind: String, Codable, Hashable, CaseIterable {
    case communityPost = "社区动态"
    case activity = "活动"
    case conversation = "会话"
    case person = "用户"

    var systemImage: String {
        switch self {
        case .communityPost: "photo.on.rectangle"
        case .activity: "calendar"
        case .conversation: "bubble.left"
        case .person: "person.crop.circle"
        }
    }
}

struct ModerationTicket: Identifiable, Codable, Hashable {
    let id: UUID
    var postID: UUID
    var postTitle: String
    var reason: String
    var createdAt: Date
    var status: ModerationTicketStatus
    var targetKind: ModerationTargetKind
    var updatedAt: Date?

    init(
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

    init(from decoder: Decoder) throws {
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

enum BookingOrderStatus: String, Codable, Hashable, CaseIterable {
    /// 已下单，等待陪玩确认接单
    case pendingConfirm = "待确认"
    /// 对方已接单，等待用户支付
    case awaitingPayment = "待支付"
    case paid = "已支付"
    case inProgress = "进行中"
    case completed = "已完成"
    case refunded = "已退款"
    case cancelled = "已取消"
}

enum BuddyInviteStatus: String, Codable, Hashable, CaseIterable {
    case pending = "待回执"
    case accepted = "已接受"
    case declined = "已婉拒"
}

struct BuddyInviteRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var nickname: String
    var activityTitle: String
    var sentAt: Date
    var status: BuddyInviteStatus
    /// 绑活动 id，接受后进群用
    var relatedActivityID: UUID?

    init(
        id: UUID,
        nickname: String,
        activityTitle: String,
        sentAt: Date,
        status: BuddyInviteStatus = .pending,
        relatedActivityID: UUID? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.activityTitle = activityTitle
        self.sentAt = sentAt
        self.status = status
        self.relatedActivityID = relatedActivityID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        activityTitle = try container.decode(String.self, forKey: .activityTitle)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        status = try container.decodeIfPresent(BuddyInviteStatus.self, forKey: .status) ?? .accepted
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
    }
}

struct BuddyBookingRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var companionNickname: String
    var hours: Int
    var scheduledAt: Date
    var bookedAt: Date
    var priceText: String
    var status: BookingOrderStatus
    var paymentMethod: String
    var paidAt: Date?
    var completedAt: Date?
    /// 用户点选的档期文案（演示）
    var selectedSlotLabel: String?

    init(
        id: UUID,
        companionNickname: String,
        hours: Int,
        scheduledAt: Date,
        bookedAt: Date,
        priceText: String,
        status: BookingOrderStatus = .pendingConfirm,
        paymentMethod: String = "simulated",
        paidAt: Date? = nil,
        completedAt: Date? = nil,
        selectedSlotLabel: String? = nil
    ) {
        self.id = id
        self.companionNickname = companionNickname
        self.hours = hours
        self.scheduledAt = scheduledAt
        self.bookedAt = bookedAt
        self.priceText = priceText
        self.status = status
        self.paymentMethod = paymentMethod
        self.paidAt = paidAt
        self.completedAt = completedAt
        self.selectedSlotLabel = selectedSlotLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        companionNickname = try container.decode(String.self, forKey: .companionNickname)
        hours = try container.decode(Int.self, forKey: .hours)
        scheduledAt = try container.decode(Date.self, forKey: .scheduledAt)
        bookedAt = try container.decode(Date.self, forKey: .bookedAt)
        priceText = try container.decode(String.self, forKey: .priceText)
        status = try container.decodeIfPresent(BookingOrderStatus.self, forKey: .status) ?? .paid
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod) ?? "simulated"
        paidAt = try container.decodeIfPresent(Date.self, forKey: .paidAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        selectedSlotLabel = try container.decodeIfPresent(String.self, forKey: .selectedSlotLabel)
    }

    var endAt: Date {
        scheduledAt.addingTimeInterval(TimeInterval(hours * 3600))
    }

    var statusLabel: String { status.rawValue }

    var canPay: Bool { status == .awaitingPayment }

    var canSimulateCounterpart: Bool { status == .pendingConfirm }

    var canMarkInProgress: Bool { status == .paid }

    var canComplete: Bool { status == .paid || status == .inProgress }

    var canRefund: Bool { status == .paid || status == .inProgress }

    var canReschedule: Bool {
        switch status {
        case .pendingConfirm, .awaitingPayment, .paid, .inProgress: true
        case .completed, .refunded, .cancelled: false
        }
    }

    var canWithdraw: Bool {
        status == .pendingConfirm || status == .awaitingPayment
    }
}

struct BuddiesSnapshot: Codable {
    var inviteRecords: [BuddyInviteRecord]
    var bookingRecords: [BuddyBookingRecord]
    var joinedCircleNames: [String]
    var joinedGuildNames: [String]
    /// 组织 / 工会成员偏好（免打扰、置顶、备注等），key 如 `circle:黄浦夜骑群`
    var membershipPrefs: [String: OrgMembershipPrefs]

    static var seed: BuddiesSnapshot {
        BuddiesSnapshot(
            inviteRecords: SampleData.seedInviteRecords,
            bookingRecords: SampleData.seedBookingRecords,
            joinedCircleNames: SampleData.interestCircles.filter(\.isJoined).map(\.name),
            joinedGuildNames: SampleData.companionGuilds.filter(\.isJoined).map(\.name),
            membershipPrefs: [:]
        )
    }

    init(
        inviteRecords: [BuddyInviteRecord],
        bookingRecords: [BuddyBookingRecord],
        joinedCircleNames: [String],
        joinedGuildNames: [String] = [],
        membershipPrefs: [String: OrgMembershipPrefs] = [:]
    ) {
        self.inviteRecords = inviteRecords
        self.bookingRecords = bookingRecords
        self.joinedCircleNames = joinedCircleNames
        self.joinedGuildNames = joinedGuildNames
        self.membershipPrefs = membershipPrefs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inviteRecords = try container.decode([BuddyInviteRecord].self, forKey: .inviteRecords)
        bookingRecords = try container.decode([BuddyBookingRecord].self, forKey: .bookingRecords)
        joinedCircleNames = try container.decodeIfPresent([String].self, forKey: .joinedCircleNames)
            ?? Self.seed.joinedCircleNames
        joinedGuildNames = try container.decodeIfPresent([String].self, forKey: .joinedGuildNames)
            ?? Self.seed.joinedGuildNames
        membershipPrefs = try container.decodeIfPresent([String: OrgMembershipPrefs].self, forKey: .membershipPrefs)
            ?? [:]
    }
}

/// 加入组织 / 关注工会后的本地成员设置
struct OrgMembershipPrefs: Codable, Hashable {
    var muteNotifications: Bool
    var isPinned: Bool
    var showMemberNicknames: Bool
    var remark: String
    var joinedAt: Date

    static func fresh(at date: Date = .now) -> OrgMembershipPrefs {
        OrgMembershipPrefs(
            muteNotifications: false,
            isPinned: false,
            showMemberNicknames: true,
            remark: "",
            joinedAt: date
        )
    }

    init(
        muteNotifications: Bool = false,
        isPinned: Bool = false,
        showMemberNicknames: Bool = true,
        remark: String = "",
        joinedAt: Date = .now
    ) {
        self.muteNotifications = muteNotifications
        self.isPinned = isPinned
        self.showMemberNicknames = showMemberNicknames
        self.remark = remark
        self.joinedAt = joinedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        muteNotifications = try container.decodeIfPresent(Bool.self, forKey: .muteNotifications) ?? false
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        showMemberNicknames = try container.decodeIfPresent(Bool.self, forKey: .showMemberNicknames) ?? true
        remark = try container.decodeIfPresent(String.self, forKey: .remark) ?? ""
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? .now
    }
}

enum OrgMembershipKind: String, Hashable {
    case circle
    case guild

    func prefsKey(name: String) -> String { "\(rawValue):\(name)" }
}

/// 隐式反馈快照：按标签 / 品类累积真实行为权重（浏览 / 收藏 / 报名）。
/// 用于让推荐分随「真实点击转化」自适应调整，而不是只认引导页选的静态兴趣。
struct ActivityEngagementSnapshot: Codable {
    var tagWeights: [String: Double]
    var categoryWeights: [String: Double]
    var lastDecayAt: Date

    static let seed = ActivityEngagementSnapshot(
        tagWeights: [:],
        categoryWeights: [:],
        lastDecayAt: .now
    )

    init(tagWeights: [String: Double], categoryWeights: [String: Double], lastDecayAt: Date) {
        self.tagWeights = tagWeights
        self.categoryWeights = categoryWeights
        self.lastDecayAt = lastDecayAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagWeights = try container.decodeIfPresent([String: Double].self, forKey: .tagWeights) ?? [:]
        categoryWeights = try container.decodeIfPresent([String: Double].self, forKey: .categoryWeights) ?? [:]
        lastDecayAt = try container.decodeIfPresent(Date.self, forKey: .lastDecayAt) ?? .now
    }
}

enum AppPersistence {
    private static func fileURL(_ name: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(name)
    }

    static func loadActivities() -> ActivitiesSnapshot {
        let snapshot: ActivitiesSnapshot = load("activities_snapshot.json", fallback: .seed)
        guard snapshot.activities.contains(where: { !$0.isPast }) else {
            let repaired = repairedActivitiesSnapshot(from: snapshot)
            saveActivities(repaired)
            return repaired
        }
        return snapshot
    }

    static func saveActivities(_ snapshot: ActivitiesSnapshot) {
        save(snapshot, to: "activities_snapshot.json")
    }

    static func loadMessages() -> MessagesSnapshot {
        let snapshot: MessagesSnapshot = load("messages_snapshot.json", fallback: .seed)
        let repaired = repairedMessagesSnapshot(from: snapshot)
        if !codableContentsEqual(snapshot, repaired) {
            saveMessages(repaired)
        }
        return repaired
    }

    static func saveMessages(_ snapshot: MessagesSnapshot) {
        save(snapshot, to: "messages_snapshot.json")
    }

    static func loadProfile() -> ProfileSnapshot {
        load("profile_snapshot.json", fallback: .seed)
    }

    static func saveProfile(_ snapshot: ProfileSnapshot) {
        save(snapshot, to: "profile_snapshot.json")
    }

    static func loadBuddies() -> BuddiesSnapshot {
        load("buddies_snapshot.json", fallback: .seed)
    }

    static func saveBuddies(_ snapshot: BuddiesSnapshot) {
        save(snapshot, to: "buddies_snapshot.json")
    }

    static func loadEngagement() -> ActivityEngagementSnapshot {
        load("activity_engagement_snapshot.json", fallback: .seed)
    }

    static func saveEngagement(_ snapshot: ActivityEngagementSnapshot) {
        save(snapshot, to: "activity_engagement_snapshot.json")
    }

    @MainActor
    static func resetLocalDemoData() {
        saveActivities(.seed)
        saveMessages(.seed)
        saveBuddies(.seed)
        saveProfile(.seed)
        saveEngagement(.seed)
        CommunityPersistence.resetToSeed()
        CommunityPhotoStore.resetAll()
        ActivityPaymentStore.resetAll()
        ActivityCommentsStore.resetAll()
        ActivityDetailContentStore.resetAll()
        UserDefaults.standard.removeObject(forKey: catalogVersionKey)
        UserDefaults.standard.removeObject(forKey: "reco.nearbyKM")
        UserDefaults.standard.removeObject(forKey: "reco.startingSoonHours")
        UserDefaults.standard.removeObject(forKey: "match.sharedHobby")
        UserDefaults.standard.removeObject(forKey: "match.availableBonus")
        UserDefaults.standard.removeObject(forKey: "match.onlineBonus")
        UserDefaults.standard.removeObject(forKey: NotificationService.PreferenceKey.activity)
        UserDefaults.standard.removeObject(forKey: NotificationService.PreferenceKey.buddy)
        UserDefaults.standard.removeObject(forKey: NotificationService.PreferenceKey.message)
        UserDefaults.standard.removeObject(forKey: NotificationService.PreferenceKey.community)
    }

    private static func load<T: Codable>(_ fileName: String, fallback: T) -> T {
        let url = fileURL(fileName)
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            save(fallback, to: fileName) 
            return fallback
        }
        return value
    }

    private static func save<T: Encodable>(_ value: T, to fileName: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(fileName), options: .atomic)
    }

    /// 内容目录版本：升级后合并新种子，保留用户活动与报名状态
    private static let catalogVersionKey = "app.catalog.version"
    static let catalogVersion = 7

    static func refreshCatalogIfNeeded() {
        let current = UserDefaults.standard.integer(forKey: catalogVersionKey)
        guard current < catalogVersion else { return }

        mergeActivitiesCatalog()
        mergeMessagesCatalog()
        mergeBuddiesCatalogIfNeeded()

        // 社区：仅在空库时写入种子，避免覆盖用户帖子
        let community = CommunityPersistence.load()
        if community.posts.isEmpty {
            CommunityPersistence.save(.emptySeed)
        }

        // 保留 onboarding / 拉黑等个人状态，仅刷新用户展示统计
        var profile = loadProfile()
        profile.user.joinedCount = SampleData.currentUser.joinedCount
        profile.user.hostedCount = SampleData.currentUser.hostedCount
        profile.user.buddyCount = SampleData.currentUser.buddyCount
        if profile.user.interests.isEmpty {
            profile.user.interests = SampleData.currentUserInterests
        }
        saveProfile(profile)

        UserDefaults.standard.set(catalogVersion, forKey: catalogVersionKey)
    }

    /// 种子按 ID 更新；用户自建活动与报名 / 收藏 / 候补集合一律保留
    private static func mergeActivitiesCatalog() {
        saveActivities(repairedActivitiesSnapshot(from: loadActivities()))
    }

    private static func repairedActivitiesSnapshot(from previous: ActivitiesSnapshot) -> ActivitiesSnapshot {
        let seed = ActivitiesSnapshot.seed
        let seedIDs = Set(seed.activities.map(\.id))
        let userCreated = previous.activities.filter { !seedIDs.contains($0.id) }

        var catalog = seed.activities
        catalog.append(contentsOf: userCreated)

        let validIDs = Set(catalog.map(\.id))
        return ActivitiesSnapshot(
            activities: catalog,
            joinedIDs: previous.joinedIDs.filter(validIDs.contains),
            favoriteIDs: previous.favoriteIDs.filter(validIDs.contains),
            waitlistIDs: previous.waitlistIDs.filter(validIDs.contains),
            waitlistSpotNotifiedIDs: previous.waitlistSpotNotifiedIDs.filter(validIDs.contains)
        )
    }

    /// 保留已有会话线程，仅补齐缺失的种子会话
    private static func mergeMessagesCatalog() {
        saveMessages(repairedMessagesSnapshot(from: loadMessages()))
    }

    private static func mergeBuddiesCatalogIfNeeded() {
        let previous = loadBuddies()
        // 已有邀约/预约数据则保留；空库才写入种子
        if previous.inviteRecords.isEmpty && previous.bookingRecords.isEmpty {
            saveBuddies(.seed)
        }
    }

    static func repairedMessagesSnapshot(from previous: MessagesSnapshot) -> MessagesSnapshot {
        let seed = MessagesSnapshot.seed

        var seenConversationIDs = Set<UUID>()
        var conversations: [ChatConversation] = []
        for conversation in previous.conversations where seenConversationIDs.insert(conversation.id).inserted {
            conversations.append(conversation)
        }

        let existingConversationIDs = Set(conversations.map(\.id))
        for conversation in seed.conversations where !existingConversationIDs.contains(conversation.id) {
            conversations.append(conversation)
        }

        let conversationKinds = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0.kind) })
        let validConversationIDs = Set(conversations.map(\.id))

        var threads: [String: [ChatMessage]] = [:]
        for conversation in conversations {
            let key = conversation.id.uuidString
            if let existing = previous.threads[key] {
                threads[key] = existing
            } else if let seeded = seed.threads[key] {
                threads[key] = seeded
            } else {
                threads[key] = []
            }
        }

        let groupMembers: [String: [GroupMemberRecord]] = Dictionary(
            uniqueKeysWithValues: previous.groupMembers.compactMap { key, members in
                guard let id = UUID(uuidString: key),
                      validConversationIDs.contains(id),
                      conversationKinds[id] == .group
                else { return nil }
                return (key, members)
            }
        )

        var seenRequestIDs = Set<UUID>()
        let repairedRequests = previous.friendRequests
            .sorted { $0.createdAt > $1.createdAt }
            .filter { seenRequestIDs.insert($0.id).inserted }

        let repairedRemarks = normalizedFriendMetadata(previous.friendRemarks)
        let repairedGroups = normalizedFriendMetadata(previous.friendGroups)
        let repairedTransfers = previous.transferRecords.filter { validConversationIDs.contains($0.conversationID) }
        let repairedCalls = previous.callRecords.filter { validConversationIDs.contains($0.conversationID) }

        return MessagesSnapshot(
            conversations: conversations,
            threads: threads,
            friendRequests: repairedRequests,
            friendRemarks: repairedRemarks,
            friendGroups: repairedGroups,
            groupMembers: groupMembers,
            transferRecords: repairedTransfers,
            callRecords: repairedCalls
        )
    }

    private static func normalizedFriendMetadata(_ source: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (rawKey, rawValue) in source {
            let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { continue }
            normalized[key] = value
        }
        return normalized
    }

    private static func codableContentsEqual<T: Codable>(_ lhs: T, _ rhs: T) -> Bool {
        guard let lhsData = try? JSONEncoder().encode(lhs),
              let rhsData = try? JSONEncoder().encode(rhs)
        else { return false }
        return lhsData == rhsData
    }
}

//
//  BuddiesModel.swift
//  坐标系
//

import Foundation
import Observation

@MainActor
@Observable
final class BuddiesModel {
    var filter = BuddyFilter()
    var inviteTarget: BuddyInviteTarget?
    var bookingPresentation: BuddyBookingPresentation?
    var pendingBookingAcknowledgementID: BuddyBookingRecord.ID?
    var pendingBookingSuccessID: BuddyBookingRecord.ID?
    var pendingInviteSuccessID: BuddyInviteRecord.ID?
    var pendingPaymentBookingID: BuddyBookingRecord.ID?
    var pendingSafetyCheckInBookingID: BuddyBookingRecord.ID?
    var toastMessage: String?
    var onRecordsChanged: (() -> Void)?
    var onMembershipChanged: (() -> Void)?
    private(set) var inviteRecords: [BuddyInviteRecord]
    private(set) var bookingRecords: [BuddyBookingRecord]
    private(set) var joinedCircleNames: Set<String>
    private(set) var joinedGuildNames: Set<String>
    private(set) var membershipPrefs: [String: OrgMembershipPrefs]
    private let repository: BuddiesRepository
    private let inviteService: any BuddyInviteService
    private let bookingService: any BuddyBookingService
    @ObservationIgnored private var persistenceGeneration: Int
    @ObservationIgnored private var persistTask: Task<Void, Never>?
    @ObservationIgnored private var inviteSimulationTasks: [BuddyInviteRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var bookingSimulationTasks: [BuddyBookingRecord.ID: Task<Void, Never>] = [:]
    var blockedUserNames: Set<String> = []
    /// 详情「不感兴趣」本地隐藏（演示会话内生效）
    var hiddenBuddyNames: Set<String> = []
    /// 默认跟系统定位；手动选省市后为 false
    var usesSystemLocation = true
    /// 系统定位反查到的地名（如「上海」）
    var locatedPlaceName: String?
    /// 手动选中的城市（关闭「当前定位」时生效）
    var selectedCityID = BuddyCityCatalog.default.id
    /// 货架 / 详情加入确认
    var pendingOrgJoin: BuddyOrgJoinTarget?
    /// 加入成功页
    var pendingOrgJoinSuccess: BuddyOrgJoinSuccess?
    /// 加入圈子后待打开的圈子群会话
    var pendingOpenConversationID: UUID?
    /// 邀请成员进圈子
    var pendingOrgInvite: BuddyOrgInviteTarget?

    @ObservationIgnored private var freeItemsCacheKey = ""
    @ObservationIgnored private var freeItemsCache: [DiscoverBuddyItem] = []
    @ObservationIgnored private var paidItemsCacheKey = ""
    @ObservationIgnored private var paidItemsCache: [DiscoverBuddyItem] = []

    init(
        snapshot: BuddiesSnapshot? = nil,
        repository: BuddiesRepository? = nil,
        inviteService: (any BuddyInviteService)? = nil,
        bookingService: (any BuddyBookingService)? = nil
    ) {
        let resolvedRepository = repository ?? LocalBuddiesRepository()
        self.repository = resolvedRepository
        self.inviteService = inviteService ?? LocalBuddyInviteService()
        self.bookingService = bookingService ?? LocalBuddyBookingService()
        let resolved = snapshot ?? resolvedRepository.load()
        inviteRecords = resolved.inviteRecords.sorted { $0.sentAt > $1.sentAt }
        bookingRecords = resolved.bookingRecords.sorted { $0.bookedAt > $1.bookedAt }
        joinedCircleNames = Set(resolved.joinedCircleNames)
        joinedGuildNames = Set(resolved.joinedGuildNames)
        membershipPrefs = resolved.membershipPrefs
        persistenceGeneration = resolvedRepository.currentPersistenceGeneration()
        for name in joinedCircleNames {
            ensurePrefs(kind: .circle, name: name)
        }
        for name in joinedGuildNames {
            ensurePrefs(kind: .guild, name: name)
        }
    }

    var selectedCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: selectedCityID) ?? BuddyCityCatalog.default
    }

    /// 筛选是否相对默认收紧（含手动省市）
    var hasActiveBrowseFilters: Bool {
        !filter.isDefault || !usesSystemLocation
    }

    /// 完整地区文案（无障碍）
    var browseRegionAccessibilityLabel: String {
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                return "当前定位 \(locatedPlaceName)"
            }
            return "正在定位"
        }
        return selectedCity.menuTitle
    }

    /// 列表筛选用的地区匹配
    func matchesBrowseLocation(_ locationText: String) -> Bool {
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                if let resolved = BuddyCityCatalog.all.first(where: {
                    $0.matches(locationText: locatedPlaceName)
                }) {
                    return resolved.matches(locationText: locationText)
                }
                return locationText.localizedCaseInsensitiveContains(locatedPlaceName)
            }
            // 定位未就绪：先按默认城市（上海）展示，避免整页空白
            return BuddyCityCatalog.default.matches(locationText: locationText)
        }
        return selectedCity.matches(locationText: locationText)
    }

    func syncLocatedPlaceName(_ placeName: String?) {
        locatedPlaceName = placeName
        if usesSystemLocation,
           let placeName,
           let match = BuddyCityCatalog.all.first(where: { $0.matches(locationText: placeName) }) {
            selectedCityID = match.id
        }
    }

    func useSystemLocationMode() {
        usesSystemLocation = true
    }

    func selectManualCity(id: String) {
        usesSystemLocation = false
        selectedCityID = id
    }

    var joinedCircles: [InterestCircle] {
        SampleData.interestCircles.filter { joinedCircleNames.contains($0.name) }
    }

    var joinedGuilds: [CompanionGuild] {
        SampleData.companionGuilds.filter { joinedGuildNames.contains($0.name) }
    }

    /// 同好页货架 / 发现列表：只推未加入的圈子
    var allCircles: [InterestCircle] {
        SampleData.interestCircles.filter {
            matchesBrowseLocation($0.city) && !joinedCircleNames.contains($0.name)
        }
    }

    var allGuilds: [CompanionGuild] {
        SampleData.companionGuilds.filter { matchesBrowseLocation($0.city) }
    }

    /// 陪玩页第二幕：语音厅（按浏览城市筛）
    var allVoiceHalls: [VoiceHall] {
        SampleData.voiceHalls.filter { matchesBrowseLocation($0.city) }
    }

    /// 同好舞台 / 细筛结果（不受 kind 限制）
    var freeItems: [DiscoverBuddyItem] {
        let key = freeDiscoveryKey
        if key == freeItemsCacheKey { return freeItemsCache }
        let sorted = SampleData.circleBuddies
            .filter {
                var base = filter
                base.availableOnly = false
                return !blockedUserNames.contains($0.profile.nickname)
                    && !isHidden(nickname: $0.profile.nickname)
                    && $0.profile.matches(base)
                    && matchesBrowseLocation($0.profile.city)
            }
            .map(DiscoverBuddyItem.free)
            .sorted { $0.matchScore > $1.matchScore }
        freeItemsCacheKey = key
        freeItemsCache = sorted
        return sorted
    }

    /// 预约列表（服务类型 / 可约开关生效）
    var paidItems: [DiscoverBuddyItem] {
        let key = paidDiscoveryKey
        if key == paidItemsCacheKey { return paidItemsCache }
        let sorted = SampleData.paidCompanions
            .filter { companion in
                guard !blockedUserNames.contains(companion.profile.nickname),
                      !isHidden(nickname: companion.profile.nickname),
                      matchesBrowseLocation(companion.profile.city),
                      filter.serviceType == nil || companion.serviceType == filter.serviceType,
                      !filter.availableOnly || companion.isAvailable
                else { return false }

                var base = filter
                let query = base.query
                base.query = ""
                guard companion.profile.matches(base) else { return false }

                let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if q.isEmpty { return true }
                return companion.profile.matchesQuery(q)
                    || companion.specialty.localizedCaseInsensitiveContains(q)
            }
            .map(DiscoverBuddyItem.paid)
            .sorted { lhs, rhs in
                switch (lhs, rhs) {
                case (.paid(let a), .paid(let b)):
                    if a.isVerified != b.isVerified { return a.isVerified && !b.isVerified }
                    if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                    if lhs.matchScore != rhs.matchScore { return lhs.matchScore > rhs.matchScore }
                    return a.hourlyPrice < b.hourlyPrice
                default:
                    return lhs.matchScore > rhs.matchScore
                }
            }
        paidItemsCacheKey = key
        paidItemsCache = sorted
        return sorted
    }

    /// 当前页舞台：同好页 / 陪玩页
    var stageItems: [DiscoverBuddyItem] {
        isPaidPage ? paidItems : freeItems
    }

    var isPaidPage: Bool { filter.kind == .paid }

    /// 人列表排序（推荐：有搜索词时优先意图重合）
    func sortedPeople(_ items: [DiscoverBuddyItem], by sort: BuddyPeopleSort) -> [DiscoverBuddyItem] {
        switch sort {
        case .recommended:
            let looking = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !looking.isEmpty else { return items }
            return items.sorted { lhs, rhs in
                let lm = lhs.profile.matchesQuery(looking)
                let rm = rhs.profile.matchesQuery(looking)
                if lm != rm { return lm && !rm }
                return lhs.matchScore > rhs.matchScore
            }
        case .active:
            return items.sorted { activeRank($0) > activeRank($1) }
        }
    }

    /// 预约列表排序（推荐沿用默认；价格 / 最早可约服务比价）
    func sortedBookings(_ items: [DiscoverBuddyItem], by sort: BuddyBookingSort) -> [DiscoverBuddyItem] {
        switch sort {
        case .recommended:
            return items
        case .price:
            return items.sorted { lhs, rhs in
                guard case .paid(let a) = lhs, case .paid(let b) = rhs else {
                    return lhs.matchScore > rhs.matchScore
                }
                if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                if a.hourlyPrice != b.hourlyPrice { return a.hourlyPrice < b.hourlyPrice }
                return lhs.matchScore > rhs.matchScore
            }
        case .earliest:
            return items.sorted { lhs, rhs in
                guard case .paid(let a) = lhs, case .paid(let b) = rhs else {
                    return lhs.matchScore > rhs.matchScore
                }
                if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                let ra = earliestSlotRank(a)
                let rb = earliestSlotRank(b)
                if ra != rb { return ra < rb }
                return a.hourlyPrice < b.hourlyPrice
            }
        }
    }

    private func activeRank(_ item: DiscoverBuddyItem) -> Int {
        if case .free(let buddy) = item, buddy.isOnline { return 300 }
        let text = item.profile.lastActiveText
        if text.contains("刚刚") || text.contains(BuddyDetailCopy.online) { return 200 }
        if text.contains("分钟") { return 150 }
        if text.contains("小时") || text.contains("今天") { return 100 }
        if text.contains("昨天") { return 50 }
        return 0
    }

    private func earliestSlotRank(_ companion: PaidCompanion) -> Int {
        if !companion.isAvailable { return 10_000 }
        let text = (
            companion.scheduleSlots.first
                ?? companion.profile.availability
        ).lowercased()
        if text.isEmpty { return 800 }
        if text.contains("今晚") || text.contains("今天") { return 0 }
        if text.contains("小时") || text.contains("分钟") { return 20 }
        if text.contains("明天") { return 40 }
        if text.contains("周末") { return 120 }
        return 200
    }

    /// 需跟进的预约单（待确认 / 待支付 / 已支付 / 履约中）
    var actionableBookingCount: Int {
        bookingRecords.filter {
            switch $0.status {
            case .pendingConfirm, .awaitingPayment, .paid, .inProgress:
                return true
            default:
                return false
            }
        }.count
    }

    /// 已签发或履约中的预约凭证（不含待支付 / 待确认；后者走「我的订单」）
    var bookingCredentialCount: Int {
        bookingRecords.filter {
            switch $0.status {
            case .paid, .inProgress:
                return true
            default:
                return false
            }
        }.count
    }

    private var freeDiscoveryKey: String {
        "free|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.query)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))"
    }

    private var paidDiscoveryKey: String {
        "paid|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.query)|\(filter.serviceType?.rawValue ?? "")|\(filter.availableOnly)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))"
    }

    func showSocialPage() {
        filter.kind = .free
    }

    func showPaidPage() {
        filter.kind = .paid
    }

    var pendingPaymentBooking: BuddyBookingRecord? {
        guard let id = pendingPaymentBookingID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    func item(for nickname: String) -> DiscoverBuddyItem? {
        freeItems.first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
            ?? paidItems.first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
            ?? SampleData.circleBuddies
                .first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
                .map(DiscoverBuddyItem.free)
            ?? SampleData.paidCompanions
                .first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
                .map(DiscoverBuddyItem.paid)
    }

    /// 圈子成员昵称 → 发现项；无完整资料时用 SampleData.author + 圈子上下文合成占位。
    func discoverItem(
        for nickname: String,
        fallbackCircleName: String,
        fallbackTopic: String = ""
    ) -> DiscoverBuddyItem {
        if let item = item(for: nickname) {
            return item
        }
        let author = SampleData.author(named: nickname)
        return .free(
            CircleBuddy(
                profile: BuddyProfile(
                    id: UUID(),
                    nickname: author.name,
                    gender: .male,
                    age: 26,
                    heightCM: 170,
                    weightKG: 62,
                    distanceKM: 1.2,
                    photoSeeds: [abs(author.name.hashValue) % 9000 + 100],
                    city: author.city,
                    bio: author.bio,
                    tags: author.tags,
                    availability: BuddyDetailCopy.available,
                    lastActiveText: "今天活跃",
                    lookingFor: "同城约局"
                ),
                circleName: fallbackCircleName,
                topic: fallbackTopic,
                isOnline: false,
                scheduleSlots: [],
                relatedActivityTitles: []
            )
        )
    }

    func isJoined(_ circle: InterestCircle) -> Bool {
        joinedCircleNames.contains(circle.name)
    }

    func isJoined(_ guild: CompanionGuild) -> Bool {
        joinedGuildNames.contains(guild.name)
    }

    /// 货架点「加入」或详情未加入时：弹出确认
    func beginJoin(_ target: BuddyOrgJoinTarget) {
        switch target {
        case .circle(let circle) where isJoined(circle):
            return
        case .guild(let guild) where isJoined(guild):
            return
        default:
            pendingOrgJoin = target
        }
    }

    @discardableResult
    func confirmJoin() -> BuddyOrgJoinSuccess? {
        guard let pending = pendingOrgJoin else { return nil }
        switch pending {
        case .circle(let circle):
            joinedCircleNames.insert(circle.name)
            ensurePrefs(kind: .circle, name: circle.name)
            pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .circle, name: circle.name, systemImage: circle.systemImage)
            pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash("已加入「\(circle.name)」")
            return success
        case .guild(let guild):
            joinedGuildNames.insert(guild.name)
            ensurePrefs(kind: .guild, name: guild.name)
            pendingOrgJoin = nil
            let success = BuddyOrgJoinSuccess(kind: .guild, name: guild.name, systemImage: guild.systemImage)
            pendingOrgJoinSuccess = success
            persist()
            onMembershipChanged?()
            flash("已关注「\(guild.name)」")
            return success
        }
    }

    func cancelJoin() {
        pendingOrgJoin = nil
    }

    func dismissJoinSuccess() {
        pendingOrgJoinSuccess = nil
        pendingOpenConversationID = nil
    }

    func attachJoinConversation(_ conversationID: UUID) {
        pendingOpenConversationID = conversationID
    }

    func leaveCircle(_ circle: InterestCircle) {
        joinedCircleNames.remove(circle.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.circle.prefsKey(name: circle.name))
        persist()
        onMembershipChanged?()
        flash("已退出「\(circle.name)」")
    }

    func leaveGuild(_ guild: CompanionGuild) {
        joinedGuildNames.remove(guild.name)
        membershipPrefs.removeValue(forKey: OrgMembershipKind.guild.prefsKey(name: guild.name))
        persist()
        onMembershipChanged?()
        flash("已取消关注「\(guild.name)」")
    }

    func prefs(kind: OrgMembershipKind, name: String) -> OrgMembershipPrefs {
        membershipPrefs[kind.prefsKey(name: name)] ?? .fresh()
    }

    func updatePrefs(kind: OrgMembershipKind, name: String, _ mutate: (inout OrgMembershipPrefs) -> Void) {
        let key = kind.prefsKey(name: name)
        var value = membershipPrefs[key] ?? .fresh()
        mutate(&value)
        membershipPrefs[key] = value
        persist()
    }

    func beginInvite(to target: BuddyOrgInviteTarget) {
        pendingOrgInvite = target
    }

    func sendOrgInvites(nicknames: [String]) {
        guard let target = pendingOrgInvite, !nicknames.isEmpty else {
            pendingOrgInvite = nil
            return
        }
        pendingOrgInvite = nil
        let label: String
        switch target {
        case .circle(let circle): label = circle.name
        case .guild(let guild): label = guild.name
        }
        flash("已邀请 \(nicknames.count) 人加入「\(label)」")
    }

    private func ensurePrefs(kind: OrgMembershipKind, name: String) {
        let key = kind.prefsKey(name: name)
        if membershipPrefs[key] == nil {
            membershipPrefs[key] = .fresh()
        }
    }

    /// 重置选人条件并回到系统定位
    func resetBrowseFilters() {
        filter.reset()
        usesSystemLocation = true
    }

    func invite(_ nickname: String) {
        inviteTarget = BuddyInviteTarget(nickname: nickname)
    }
    func book(
        _ companion: PaidCompanion,
        initialDay: Date? = nil,
        serviceSKU: BuddyCompanionServiceSKU? = nil
    ) {
        if YouthModePreference.isEnabled {
            flash(GuestAccessGate.youthCommerceReason)
            return
        }
        bookingPresentation = BuddyBookingPresentation(
            companion: companion,
            initialDay: initialDay,
            serviceSKU: serviceSKU,
            token: UUID()
        )
    }

    func dismissBookingPresentation() {
        bookingPresentation = nil
    }

    @discardableResult
    func recordInvite(
        nickname: String,
        activity: Activity,
        note: String? = nil
    ) -> BuddyInviteRecord {
        let record = inviteService.createInvite(nickname: nickname, activity: activity)
        inviteRecords.insert(record, at: 0)
        inviteTarget = nil
        pendingInviteSuccessID = record.id
        TrustService.shared.record(
            .inviteSent,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: nickname,
            note: note
        )
        persist()
        onRecordsChanged?()
        scheduleInviteReplySimulation(for: record.id)
        return record
    }

    func dismissInviteSuccess() {
        pendingInviteSuccessID = nil
    }

    func acceptInvite(_ id: BuddyInviteRecord.ID) {
        guard let index = inviteRecords.firstIndex(where: { $0.id == id }) else { return }
        guard inviteRecords[index].status == .pending else { return }
        inviteRecords[index] = inviteService.advanceInvite(inviteRecords[index], to: .accepted)
        TrustService.shared.record(
            .inviteAccepted,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: inviteRecords[index].nickname
        )
        persist()
        onRecordsChanged?()
        flash("\(inviteRecords[index].nickname) 已接受邀约")
    }

    func declineInvite(_ id: BuddyInviteRecord.ID) {
        guard let index = inviteRecords.firstIndex(where: { $0.id == id }) else { return }
        guard inviteRecords[index].status == .pending else { return }
        inviteRecords[index] = inviteService.advanceInvite(inviteRecords[index], to: .declined)
        TrustService.shared.record(
            .inviteDeclined,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: inviteRecords[index].nickname
        )
        persist()
        onRecordsChanged?()
        flash("\(inviteRecords[index].nickname) 婉拒了邀约")
    }

    /// 创建待确认订单；冲突时返回 nil。不再立刻弹出支付。
    @discardableResult
    func recordBooking(
        companion: PaidCompanion,
        scheduledAt: Date,
        hours: Int,
        slotLabel: String? = nil
    ) -> BuddyBookingRecord? {
        let candidate = bookingService.createBooking(
            companion: companion,
            scheduledAt: scheduledAt,
            hours: hours,
            slotLabel: slotLabel
        )
        if hasScheduleConflict(candidate) {
            flash(BuddyBookingFlowCopy.conflictHint)
            return nil
        }
        bookingRecords.insert(candidate, at: 0)
        bookingPresentation = nil
        pendingBookingAcknowledgementID = candidate.id
        persist()
        onRecordsChanged?()
        scheduleCompanionAcceptSimulation(for: candidate.id)
        return candidate
    }

    var pendingBookingAcknowledgement: BuddyBookingRecord? {
        guard let id = pendingBookingAcknowledgementID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    func dismissBookingAcknowledgement() {
        pendingBookingAcknowledgementID = nil
    }

    func dismissBookingSuccess() {
        pendingBookingSuccessID = nil
    }

    /// 打开预约记录时推进「刚下单」的演示接单
    func simulateCompanionAcceptsIfNeeded() {
        for record in bookingRecords where record.status == .pendingConfirm {
            let age = Date.now.timeIntervalSince(record.bookedAt)
            if age > 4, age < 180 {
                acceptBooking(record.id)
            }
        }
    }

    func acceptBooking(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].status == .pendingConfirm else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .awaitingPayment)
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        persist()
        onRecordsChanged?()
        beginPayment(id)
    }

    func declineBooking(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].status == .pendingConfirm else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .cancelled)
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        persist()
        onRecordsChanged?()
        flash("对方已拒单")
    }

    func beginPayment(_ id: BuddyBookingRecord.ID) {
        guard let record = bookingRecords.first(where: { $0.id == id }), record.canPay else {
            flash("订单尚未可支付")
            return
        }
        pendingPaymentBookingID = id
    }

    @discardableResult
    func confirmPayment(
        _ id: BuddyBookingRecord.ID,
        method: PaymentMethod = .wallet
    ) -> PaymentOutcome {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else {
            return .failed("订单不存在")
        }
        guard bookingRecords[index].status == .awaitingPayment
            || bookingRecords[index].status == .pendingConfirm
        else {
            return .failed("订单尚未可支付")
        }
        let record = bookingRecords[index]
        let amountCents = WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800
        let outcome = WalletStore.shared.charge(
            amountCents: amountCents,
            method: method,
            kind: .bookingPayment,
            title: "陪玩 · \(record.companionNickname)",
            subtitle: record.priceText,
            relatedID: record.id
        )
        guard outcome == .success else { return outcome }

        var paid = bookingService.advanceBooking(record, to: .paid)
        paid.paymentMethod = method.displayName
        bookingRecords[index] = paid
        pendingPaymentBookingID = nil
        pendingBookingSuccessID = id
        TrustService.shared.record(
            .bookingPaid,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: paid.companionNickname
        )
        NotificationService.scheduleBookingReminder(
            bookingID: id,
            companion: paid.companionNickname,
            at: paid.scheduledAt
        )
        persist()
        onRecordsChanged?()
        WalletPassStore.shared.issueBookingTicket(for: paid)
        return .success
    }

    func cancelPendingPayment() {
        pendingPaymentBookingID = nil
    }

    /// 取消仍处「待确认」的订单（用户主动撤销）
    func withdrawPendingBooking(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].status == .pendingConfirm
            || bookingRecords[index].status == .awaitingPayment else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .cancelled)
        if pendingPaymentBookingID == id {
            pendingPaymentBookingID = nil
        }
        if pendingBookingAcknowledgementID == id {
            pendingBookingAcknowledgementID = nil
        }
        persist()
        onRecordsChanged?()
        flash("已取消预约")
    }

    /// 不感兴趣：本地隐藏，不进拉黑通讯录
    func hidePerson(nickname: String) {
        hiddenBuddyNames.insert(nickname)
        flash("已减少类似推荐")
    }

    func isHidden(nickname: String) -> Bool {
        hiddenBuddyNames.contains {
            $0.caseInsensitiveCompare(nickname) == .orderedSame
        }
    }

    /// 工会名录：同城优先，再按标签 / 专长重合；无重合时回退同城全部
    func companions(in guild: CompanionGuild) -> [PaidCompanion] {
        let metro = guild.city
            .split(separator: "·")
            .first
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            ?? guild.city
        let specialtyKey = guild.specialty
            .replacingOccurrences(of: "陪玩", with: "")
            .trimmingCharacters(in: .whitespaces)

        let inMetro = SampleData.paidCompanions.filter {
            $0.profile.city.localizedCaseInsensitiveContains(metro)
                && !isHidden(nickname: $0.profile.nickname)
                && !blockedUserNames.contains($0.profile.nickname)
        }

        let matched = inMetro.filter { companion in
            companion.specialty.localizedCaseInsensitiveContains(specialtyKey)
                || guild.tags.contains { tag in
                    companion.profile.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
                        || companion.specialty.localizedCaseInsensitiveContains(tag)
                }
        }

        let list = matched.isEmpty ? inMetro : matched
        return list.sorted { lhs, rhs in
            if lhs.isVerified != rhs.isVerified { return lhs.isVerified && !rhs.isVerified }
            return lhs.orderCount > rhs.orderCount
        }
    }

    private func scheduleInviteReplySimulation(for id: BuddyInviteRecord.ID) {
        inviteSimulationTasks[id]?.cancel()
        inviteSimulationTasks[id] = Task { @MainActor in
            defer { inviteSimulationTasks[id] = nil }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            if inviteRecords.contains(where: { $0.id == id && $0.status == .pending }) {
                if abs(id.uuidString.hashValue) % 5 == 0 {
                    declineInvite(id)
                } else {
                    acceptInvite(id)
                }
            }
        }
    }

    private func scheduleCompanionAcceptSimulation(for id: BuddyBookingRecord.ID) {
        bookingSimulationTasks[id]?.cancel()
        bookingSimulationTasks[id] = Task { @MainActor in
            defer { bookingSimulationTasks[id] = nil }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            if bookingRecords.contains(where: { $0.id == id && $0.status == .pendingConfirm }) {
                if abs(id.uuidString.hashValue) % 7 == 0 {
                    declineBooking(id)
                } else {
                    acceptBooking(id)
                }
            }
        }
    }

    func markInProgress(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].status == .paid else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .inProgress)
        persist()
        onRecordsChanged?()
        flash("预约已开始")
    }

    func completeBooking(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].canComplete else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .completed)
        NotificationService.cancelBookingReminder(bookingID: id)
        TrustService.shared.record(
            .bookingCompleted,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: bookingRecords[index].companionNickname
        )
        persist()
        onRecordsChanged?()
        if !TrustService.shared.hasCheckedIn(bookingID: id) {
            pendingSafetyCheckInBookingID = id
            flash("订单已完成，可确认履约情况")
        } else {
            flash("订单已完成")
        }
    }

    func cancelPendingSafetyCheckIn() {
        pendingSafetyCheckInBookingID = nil
    }

    var pendingSafetyCheckInBooking: BuddyBookingRecord? {
        guard let id = pendingSafetyCheckInBookingID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    /// 拉黑后清理未完成邀约 / 待支付预约
    func purgeSocialLinks(with nickname: String) {
        inviteRecords = inviteRecords.map { record in
            guard record.nickname.caseInsensitiveCompare(nickname) == .orderedSame,
                  record.status == .pending
            else { return record }
            return inviteService.advanceInvite(record, to: .declined)
        }
        let cancellable = bookingRecords.filter {
            $0.companionNickname.caseInsensitiveCompare(nickname) == .orderedSame
                && ($0.status == .pendingConfirm || $0.status == .awaitingPayment)
        }
        for record in cancellable {
            cancelBooking(record.id)
        }
        persist()
        onRecordsChanged?()
    }

    @discardableResult
    func refundBooking(_ id: BuddyBookingRecord.ID, reason: String, detail: String) -> UUID? {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return nil }
        guard bookingRecords[index].canRefund else { return nil }
        let record = bookingRecords[index]
        let result = RefundFlowService.shared.submitBookingRefund(
            record: record,
            reason: reason,
            detail: detail,
            onFinalize: { [weak self] bookingID in
                self?.completeBookingRefund(bookingID)
            }
        )
        switch result {
        case .success(let refundRecord):
            persist()
            onRecordsChanged?()
            flash("退款申请已提交")
            return refundRecord.id
        case .failure(let error):
            flash(error.localizedDescription)
            return nil
        }
    }

    private func completeBookingRefund(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .refunded)
        persist()
        onRecordsChanged?()
        flash("退款已完成")
    }

    func cancelBooking(_ id: BuddyBookingRecord.ID) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        guard bookingRecords[index].canWithdraw
            || bookingRecords[index].status == .paid
            || bookingRecords[index].status == .inProgress
        else { return }
        let companion = bookingRecords[index].companionNickname
        bookingRecords[index] = bookingService.advanceBooking(bookingRecords[index], to: .cancelled)
        if pendingPaymentBookingID == id {
            pendingPaymentBookingID = nil
        }
        NotificationService.cancelBookingReminder(bookingID: id)
        WalletPassStore.shared.void(relatedID: id)
        TrustService.shared.record(
            .bookingCancelled,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: companion
        )
        persist()
        onRecordsChanged?()
        flash("已取消预约")
    }

    func deleteBooking(_ id: BuddyBookingRecord.ID) {
        NotificationService.cancelBookingReminder(bookingID: id)
        WalletPassStore.shared.revoke(relatedID: id)
        bookingRecords.removeAll { $0.id == id }
        persist()
        onRecordsChanged?()
    }

    func deleteInvite(_ id: BuddyInviteRecord.ID) {
        inviteRecords.removeAll { $0.id == id }
        persist()
        onRecordsChanged?()
    }

    func rescheduleBooking(_ id: BuddyBookingRecord.ID, scheduledAt: Date, hours: Int) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == id }) else { return }
        let hourlyPrice = SampleData.paidCompanions.first(where: {
            $0.profile.nickname == bookingRecords[index].companionNickname
        })?.hourlyPrice
        let draft = bookingService.rescheduleBooking(
            bookingRecords[index],
            scheduledAt: scheduledAt,
            hours: hours,
            hourlyPrice: hourlyPrice
        )
        if hasScheduleConflict(draft, excluding: id) {
            flash("改期时间与其他预约冲突")
            return
        }
        bookingRecords[index] = draft
        if bookingRecords[index].status == .paid
            || bookingRecords[index].status == .inProgress
            || bookingRecords[index].status == .completed {
            NotificationService.scheduleBookingReminder(
                bookingID: id,
                companion: bookingRecords[index].companionNickname,
                at: scheduledAt
            )
            _ = WalletPassStore.shared.issueBookingTicket(for: bookingRecords[index])
        }
        persist()
        onRecordsChanged?()
    }

    private func hasScheduleConflict(_ candidate: BuddyBookingRecord, excluding: UUID? = nil) -> Bool {
        let range = candidate.scheduledAt..<candidate.endAt
        return bookingRecords.contains { other in
            guard other.id != excluding,
                  other.companionNickname == candidate.companionNickname,
                  ![BookingOrderStatus.cancelled, .refunded].contains(other.status)
            else { return false }
            let otherRange = other.scheduledAt..<other.endAt
            return range.overlaps(otherRange)
        }
    }

    func flash(_ message: String) {
        toastMessage = message
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
        persistenceGeneration = repository.currentPersistenceGeneration()
        inviteRecords = snapshot.inviteRecords.sorted { $0.sentAt > $1.sentAt }
        bookingRecords = snapshot.bookingRecords.sorted { $0.bookedAt > $1.bookedAt }
        joinedCircleNames = Set(snapshot.joinedCircleNames)
        joinedGuildNames = Set(snapshot.joinedGuildNames)
        membershipPrefs = snapshot.membershipPrefs
        for name in joinedCircleNames {
            ensurePrefs(kind: .circle, name: name)
        }
        for name in joinedGuildNames {
            ensurePrefs(kind: .guild, name: name)
        }
    }

    func discardPendingPersistence() async {
        for task in inviteSimulationTasks.values {
            task.cancel()
        }
        inviteSimulationTasks.removeAll()
        for task in bookingSimulationTasks.values {
            task.cancel()
        }
        bookingSimulationTasks.removeAll()
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    private func persist() {
        let snapshot = BuddiesSnapshot(
            inviteRecords: inviteRecords,
            bookingRecords: bookingRecords,
            joinedCircleNames: Array(joinedCircleNames),
            joinedGuildNames: Array(joinedGuildNames),
            membershipPrefs: membershipPrefs
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled else { return }
            try? await repository.replaceAsync(with: snapshot, generation: generation)
        }
    }

    private func trustActorKey() -> String {
        AppPersistence.loadProfile().user.name
    }
}

struct BuddyInviteTarget: Identifiable, Hashable {
    let nickname: String
    var id: String { nickname }
}

struct BuddyBookingPresentation: Identifiable, Hashable {
    let companion: PaidCompanion
    var initialDay: Date?
    var serviceSKU: BuddyCompanionServiceSKU?
    let token: UUID
    var id: UUID { token }
}

enum BuddyOrgJoinTarget: Identifiable, Hashable {
    case circle(InterestCircle)
    case guild(CompanionGuild)

    var id: String {
        switch self {
        case .circle(let c): "circle:\(c.id.uuidString)"
        case .guild(let g): "guild:\(g.id.uuidString)"
        }
    }
}

struct BuddyOrgJoinSuccess: Identifiable, Hashable {
    let kind: OrgMembershipKind
    let name: String
    let systemImage: String
    var id: String { "\(kind.rawValue):\(name)" }
}

enum BuddyOrgInviteTarget: Identifiable, Hashable {
    case circle(InterestCircle)
    case guild(CompanionGuild)

    var id: String {
        switch self {
        case .circle(let c): "invite-circle:\(c.id.uuidString)"
        case .guild(let g): "invite-guild:\(g.id.uuidString)"
        }
    }
}

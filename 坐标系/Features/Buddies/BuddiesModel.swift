//
//  BuddiesModel.swift
//  坐标系
//
//  搭子域 Model：状态容器 + 持久化；浏览 / 圈子 / 邀约 / 预约见扩展文件。
//

import CoordinateDomain
import CoordinateModels
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
    /// 接单后待用户主动确认的「待支付」详情 Sheet（不自动打开支付 Sheet）。
    var pendingAwaitingPaymentReviewID: BuddyBookingRecord.ID?
    var pendingSafetyCheckInBookingID: BuddyBookingRecord.ID?
    var toastMessage: String?
    var onRecordsChanged: (() -> Void)?
    var onMembershipChanged: (() -> Void)?
    var inviteRecords: [BuddyInviteRecord]
    var bookingRecords: [BuddyBookingRecord]
    /// 用户创建的俱乐部
    var userClubs: [InterestCircle]
    var joinedCircleIDs: Set<UUID>
    var joinedCircleNames: Set<String>
    var joinedGuildNames: Set<String>
    var membershipPrefs: [String: OrgMembershipPrefs]
    var isComposingClub = false
    let repository: any BuddiesRepository
    let inviteService: any BuddyInviteService
    let bookingService: any BuddyBookingService
    @ObservationIgnored let booking: BuddiesBookingUseCases
    @ObservationIgnored var persistenceGeneration: Int
    @ObservationIgnored var persistTask: Task<Void, Never>?
    @ObservationIgnored var inviteSimulationTasks: [BuddyInviteRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var bookingSimulationTasks: [BuddyBookingRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var bookingPaymentExpiryTasks: [BuddyBookingRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var bookingRemotePollTasks: [BuddyBookingRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var bookingConfirmationExpiryTasks: [BuddyBookingRecord.ID: Task<Void, Never>] = [:]
    var blockedUserNames: Set<String> = []
    var currentUserName: String
    var hiddenBuddyNames: Set<String> = []
    var usesSystemLocation = true
    var locatedPlaceName: String?
    var selectedCityID = BuddyCityCatalog.default.id
    var pendingOrgJoin: BuddyOrgJoinTarget?
    var pendingOrgJoinSuccess: BuddyOrgJoinSuccess?
    var pendingOpenConversationID: UUID?
    /// 欢迎引导等深链：落地免费同好页并打开俱乐部发现。
    var pendingShowCircleDiscover = false
    var pendingOrgInvite: BuddyOrgInviteTarget?

    @ObservationIgnored var freeItemsCacheKey = ""
    @ObservationIgnored var freeItemsCache: [DiscoverBuddyItem] = []
    @ObservationIgnored var paidItemsCacheKey = ""
    @ObservationIgnored var paidItemsCache: [DiscoverBuddyItem] = []
    @ObservationIgnored let walletStore: WalletStore
    @ObservationIgnored let walletPassStore: WalletPassStore
    @ObservationIgnored let refundFlowService: RefundFlowService
    @ObservationIgnored let trustService: TrustService
    @ObservationIgnored let remoteBookingSync: any RemoteBookingSyncing

    init(
        repository: any BuddiesRepository,
        booking: BuddiesBookingUseCases,
        walletStore: WalletStore,
        walletPassStore: WalletPassStore,
        refundFlowService: RefundFlowService,
        trustService: TrustService,
        remoteBookingSync: (any RemoteBookingSyncing)? = nil,
        snapshot: BuddiesSnapshot? = nil,
        currentUserName: String? = nil,
        inviteService: (any BuddyInviteService)? = nil,
        bookingService: (any BuddyBookingService)? = nil
    ) {
        self.repository = repository
        self.walletStore = walletStore
        self.walletPassStore = walletPassStore
        self.refundFlowService = refundFlowService
        self.trustService = trustService
        self.remoteBookingSync = remoteBookingSync ?? DisabledRemoteBookingSync()
        self.currentUserName = currentUserName ?? SampleData.currentUser.name
        self.inviteService = inviteService ?? LocalBuddyInviteService()
        self.bookingService = bookingService ?? LocalBuddyBookingService()
        self.booking = booking
        let resolved = snapshot ?? repository.load()
        inviteRecords = resolved.inviteRecords.sorted { $0.sentAt > $1.sentAt }
        bookingRecords = resolved.bookingRecords.sorted { $0.bookedAt > $1.bookedAt }
        userClubs = resolved.clubs
        joinedCircleIDs = Set(resolved.joinedCircleIDs)
        joinedCircleNames = Set(resolved.joinedCircleNames)
        joinedGuildNames = Set(resolved.joinedGuildNames)
        membershipPrefs = resolved.membershipPrefs
        persistenceGeneration = repository.currentPersistenceGeneration()
        migrateJoinedCircleMembershipIfNeeded()
        syncJoinedCircleNamesFromIDs()
        for name in joinedCircleNames {
            ensurePrefs(kind: .circle, name: name)
        }
        for name in joinedGuildNames {
            ensurePrefs(kind: .guild, name: name)
        }
        expireOverduePaymentsIfNeeded()
        expireOverdueConfirmationsIfNeeded()
        rehydrateBookingLifecycleIfNeeded()
    }

    var actionableBookingCount: Int {
        bookingRecords.filter {
            switch $0.status {
            case .pendingConfirm, .awaitingPayment, .paid, .inProgress, .refunding:
                return true
            default:
                return false
            }
        }.count
    }

    var pendingBookingAttentionCount: Int {
        bookingRecords.filter {
            $0.status == .pendingConfirm || $0.status == .awaitingPayment
        }.count
    }

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

    var pendingPaymentBooking: BuddyBookingRecord? {
        guard let id = pendingPaymentBookingID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    var pendingAwaitingPaymentReview: BuddyBookingRecord? {
        guard let id = pendingAwaitingPaymentReviewID else { return nil }
        return bookingRecords.first { $0.id == id }
    }

    func dismissAwaitingPaymentReview() {
        pendingAwaitingPaymentReviewID = nil
    }

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

    func flash(_ message: String) {
        toastMessage = message
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
        persistenceGeneration = repository.currentPersistenceGeneration()
        inviteRecords = snapshot.inviteRecords.sorted { $0.sentAt > $1.sentAt }
        bookingRecords = snapshot.bookingRecords.sorted { $0.bookedAt > $1.bookedAt }
        userClubs = snapshot.clubs
        joinedCircleIDs = Set(snapshot.joinedCircleIDs)
        joinedCircleNames = Set(snapshot.joinedCircleNames)
        joinedGuildNames = Set(snapshot.joinedGuildNames)
        membershipPrefs = snapshot.membershipPrefs
        migrateJoinedCircleMembershipIfNeeded()
        syncJoinedCircleNamesFromIDs()
        for name in joinedCircleNames {
            ensurePrefs(kind: .circle, name: name)
        }
        for name in joinedGuildNames {
            ensurePrefs(kind: .guild, name: name)
        }
        expireOverduePaymentsIfNeeded()
        expireOverdueConfirmationsIfNeeded()
        rehydrateBookingLifecycleIfNeeded()
        await syncRemoteBookingStatusesIfNeeded()
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
        for task in bookingPaymentExpiryTasks.values {
            task.cancel()
        }
        bookingPaymentExpiryTasks.removeAll()
        for task in bookingRemotePollTasks.values {
            task.cancel()
        }
        bookingRemotePollTasks.removeAll()
        for task in bookingConfirmationExpiryTasks.values {
            task.cancel()
        }
        bookingConfirmationExpiryTasks.removeAll()
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    func persist() {
        let snapshot = BuddiesSnapshot(
            inviteRecords: inviteRecords,
            bookingRecords: bookingRecords,
            clubs: userClubs,
            joinedCircleIDs: Array(joinedCircleIDs),
            joinedCircleNames: Array(joinedCircleNames),
            joinedGuildNames: Array(joinedGuildNames),
            membershipPrefs: membershipPrefs
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = MainActorPersistence.chained(after: previousTask) {
            do {
                try await self.repository.replaceAsync(with: snapshot, generation: generation)
            } catch {
                assertionFailure("Buddies persist failed: \(error)")
                PersistenceWriteFailureReporter.record(domainKey: "buddies", error: error)
                self.flash("保存失败，请稍后重试")
            }
        }
    }

    func trustActorKey() -> String {
        currentUserName
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

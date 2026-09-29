//
//  AppModel.swift
//  坐标系
//
//  应用枢纽：协调五域 Model、路由与资料持久化；业务编排委托 AppSyncOrchestrator。
//

import CoordinateDomain
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .activities
    /// 活动 Tab 根页是否应展示 `tabViewBottomAccessory`（由 `ActivitiesView` 同步）。
    var activitiesTabNowPlayingBarVisible = false
    /// 底栏附件发起的地图导航（`ActivitiesView` 呈现 Sheet 后清空）。
    var mapNavigationActivity: Activity?
    let router = AppRouter()
    let welcomeGuide = WelcomeGuideStore()
    var activities: ActivitiesModel
    var messages: MessagesModel
    var community: CommunityModel
    var buddies: BuddiesModel
    var user: AppUser
    var hasCompletedOnboarding: Bool
    /// 欢迎引导后资料 bootstrap 完成（持久化键名 `hasCompletedOnboarding` 保留兼容）。
    var hasCompletedWelcomeBootstrap: Bool {
        get { hasCompletedOnboarding }
        set { hasCompletedOnboarding = newValue }
    }
    var auth: LocalAuthSession
    var blockedUserNames: Set<String>
    var followedUserNames: Set<String>
    var moderationTickets: [ModerationTicket]

    var pendingConversationID: ChatConversation.ID? {
        get { router.pendingConversationID }
        set { router.pendingConversationID = newValue }
    }
    var pendingFocusMessageID: ChatMessage.ID? {
        get { router.pendingFocusMessageID }
        set { router.pendingFocusMessageID = newValue }
    }
    var pendingCallID: CallSessionRecord.ID? {
        get { router.pendingCallID }
        set { router.pendingCallID = newValue }
    }
    var pendingActivityID: Activity.ID? {
        get { router.pendingActivityID }
        set { router.pendingActivityID = newValue }
    }
    var pendingActivityFollowUp: ActivityNotificationFollowUp {
        get { router.pendingActivityFollowUp }
        set { router.pendingActivityFollowUp = newValue }
    }
    var pendingActivityJourneyFollowUp: ActivityNotificationFollowUp {
        get { router.pendingActivityJourneyFollowUp }
        set { router.pendingActivityJourneyFollowUp = newValue }
    }
    var pendingBookingID: BuddyBookingRecord.ID? {
        get { router.pendingBookingID }
        set { router.pendingBookingID = newValue }
    }
    var pendingProfileRoute: ProfileRoute? {
        get { router.pendingProfileRoute }
        set { router.pendingProfileRoute = newValue }
    }
    var pendingBuddiesRoute: BuddiesRoute? {
        get { router.pendingBuddiesRoute }
        set { router.pendingBuddiesRoute = newValue }
    }

    /// 认证照基准变更后，或门禁拦截后，提示完成摄像头人脸核验。
    var pendingIdentityVerification = false
    /// 门禁拦截：缺少认证照时打开资料编辑。
    var pendingIdentityEditProfile = false

    /// 身份门禁：未满足则置 pending 并返回 false（由根视图呈现 Sheet）。
    @discardableResult
    func requireIdentityAccess() -> Bool {
        switch IdentityAccessGate.requirement(
            user: user,
            auth: auth,
            photoVerification: photoVerificationStore
        ) {
        case .satisfied:
            return true
        case .photosMissing:
            pendingIdentityEditProfile = true
            return false
        case .verificationMissing:
            pendingIdentityVerification = true
            return false
        }
    }

    let dependencies: AppDependencies
    let repositories: AppRepositories
    let profileRepository: any ProfileRepository
    let activitiesRepository: any ActivitiesRepository
    let activityEngagementStore: ActivityEngagementStore
    let profileRecentBrowseStore: ProfileRecentBrowseStore
    let walletStore: WalletStore
    let walletPassStore: WalletPassStore
    let refundFlowService: RefundFlowService
    let trustService: TrustService
    let productLifecycleStore: ProductLifecycleStore
    let membershipStore: MembershipStore
    let notificationPreferencesStore: NotificationPreferencesStore
    let privacyPreferencesStore: PrivacyPreferencesStore
    let youthModeStore: YouthModeStore
    let legalConsentStore: LegalConsentStore
    let membershipAdImpressionStore: MembershipAdImpressionStore
    let photoVerificationStore: PhotoVerificationStore
    let opsContentStore: OpsContentStore
    @ObservationIgnored var profilePersistenceGeneration: Int
    @ObservationIgnored var profilePersistTask: Task<Void, Never>?
    @ObservationIgnored let derivedStateService = AppDerivedStateService()
    @ObservationIgnored lazy var syncOrchestrator = AppSyncOrchestrator(app: self)

    init(
        auth: LocalAuthSession? = nil,
        dependencies: AppDependencies = .live
    ) {
        self.dependencies = dependencies
        repositories = dependencies.repositories
        activityEngagementStore = dependencies.activityEngagementStore
        profileRecentBrowseStore = dependencies.profileRecentBrowseStore
        walletStore = dependencies.walletStore
        walletPassStore = dependencies.walletPassStore
        refundFlowService = dependencies.refundFlowService
        trustService = dependencies.trustService
        productLifecycleStore = dependencies.productLifecycleStore
        membershipStore = dependencies.membershipStore
        notificationPreferencesStore = dependencies.notificationPreferencesStore
        privacyPreferencesStore = dependencies.privacyPreferencesStore
        youthModeStore = dependencies.youthModeStore
        legalConsentStore = dependencies.legalConsentStore
        membershipAdImpressionStore = dependencies.membershipAdImpressionStore
        photoVerificationStore = dependencies.photoVerificationStore
        opsContentStore = dependencies.opsContentStore
        self.auth = auth ?? LocalAuthSession()
        let resolvedProfileRepository = repositories.profile
        profileRepository = resolvedProfileRepository
        activitiesRepository = repositories.activities
        profilePersistenceGeneration = resolvedProfileRepository.currentPersistenceGeneration()
        LocalUserIdentity.ensure()
        var profileSnapshot = resolvedProfileRepository.load()
        if profileSnapshot.user.id != LocalUserIdentity.current {
            profileSnapshot.user.id = LocalUserIdentity.current
        }
        user = profileSnapshot.user
        hasCompletedOnboarding = profileSnapshot.hasCompletedOnboarding
        blockedUserNames = Set(profileSnapshot.blockedUserNames)
        followedUserNames = Set(profileSnapshot.followedUserNames)
        moderationTickets = profileSnapshot.moderationTickets.sorted { $0.createdAt > $1.createdAt }
        BuddyMatchScorer.myInterests = profileSnapshot.user.interests.isEmpty
            ? SampleData.currentUserInterests
            : profileSnapshot.user.interests

        activities = dependencies.makeActivitiesModel(currentUserName: profileSnapshot.user.name)
        messages = dependencies.makeMessagesModel()
        community = dependencies.makeCommunityModel(currentUserName: profileSnapshot.user.name)
        buddies = dependencies.makeBuddiesModel(currentUserName: profileSnapshot.user.name)
        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        syncRecommendationContext()
        welcomeGuide.migrateLegacyOnboardingIfNeeded(app: self)
    }

    static var preview: AppModel {
        AppDependencies.preview().makeAppModel()
    }

    func bootstrapAsync() async {
        await quiesceAllPersistence()
        await AppComposition.syncRemoteSnapshotsIfEnabled(
            repositories: repositories,
            profile: profileRepository
        )
        guard let profileSnapshot = try? await profileRepository.loadAsync() else { return }
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
        syncOrchestrator.handle(.localDataReloaded(profileSnapshot))

        await activities.reloadFromRepository()
        await messages.reloadFromRepository()
        await community.reloadFromRepository()
        await buddies.reloadFromRepository()

        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        derivedStateService.refreshAll(app: self)
        #if DEBUG
        PassDemoBootstrap.installScriptMurderJourneyDemoIfNeeded(app: self)
        #endif
        syncOrchestrator.handle(.recommendationRefreshRequested)
    }

    /// D2：按当前旗标重新拉取活动 / 广场 / 资料快照并刷新 UI。
    func resyncRemoteReadPath() async {
        await AppComposition.syncRemoteSnapshotsIfEnabled(
            repositories: repositories,
            profile: profileRepository
        )
        if let profileSnapshot = try? await profileRepository.loadAsync() {
            profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
            syncOrchestrator.handle(.localDataReloaded(profileSnapshot))
        }
        await activities.reloadFromRepository()
        await community.reloadFromRepository()
        refreshInterestContext(user.interests)
        syncOrchestrator.handle(.recommendationRefreshRequested)
        syncOrchestrator.handle(.statsRefreshRequested)
    }

    func handle(_ event: AppDomainEvent) {
        syncOrchestrator.handle(event)
    }

    func syncRecommendationContext() {
        derivedStateService.refreshRecommendations(app: self)
    }

    func refreshInterestContext(_ interests: [String]) {
        BuddyMatchScorer.myInterests = interests.isEmpty
            ? SampleData.currentUserInterests
            : interests
    }

    func persistProfile() {
        let snapshot = ProfileSnapshot(
            user: user,
            hasCompletedOnboarding: hasCompletedOnboarding,
            blockedUserNames: Array(blockedUserNames),
            followedUserNames: Array(followedUserNames),
            moderationTickets: moderationTickets
        )
        let previousTask = profilePersistTask
        let generation = profilePersistenceGeneration
        profilePersistTask = MainActorPersistence.chained(after: previousTask) {
            do {
                try await self.profileRepository.replaceAsync(with: snapshot, generation: generation)
            } catch {
                assertionFailure("Profile persist failed: \(error)")
            }
        }
    }

    func reloadFromLocalState(keepSignedIn: Bool) {
        let profileSnapshot = profileRepository.load()
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
        var reloadedProfile = profileSnapshot
        if !keepSignedIn {
            reloadedProfile.hasCompletedOnboarding = false
            welcomeGuide.reset()
        }
        syncOrchestrator.handle(.localDataReloaded(reloadedProfile))

        activities = dependencies.makeActivitiesModel(currentUserName: reloadedProfile.user.name)
        messages = dependencies.makeMessagesModel()
        community = dependencies.makeCommunityModel(currentUserName: reloadedProfile.user.name)
        buddies = dependencies.makeBuddiesModel(currentUserName: reloadedProfile.user.name)
        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        selectedTab = .activities
        router.clearPendingIntents()
        refreshInterestContext(reloadedProfile.user.interests)
        syncOrchestrator.handle(.recommendationRefreshRequested)
        syncOrchestrator.handle(.statsRefreshRequested)
    }

    func quiesceAllPersistence() async {
        profilePersistTask?.cancel()
        await activities.discardPendingPersistence()
        await messages.discardPendingPersistence()
        await community.discardPendingPersistence()
        await buddies.discardPendingPersistence()
        _ = await profilePersistTask?.result
        profilePersistTask = nil
        profileRepository.invalidatePendingWrites()
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
    }

    /// 进入后台时冲刷各域落盘（Apple：`scenePhase == .background`）。
    func flushPersistenceForBackground() {
        persistProfile()
        activities.persist()
        messages.persist()
        community.persist()
        buddies.persist()
        Task { @MainActor in
            await flushPendingPersistence()
        }
    }

    func flushPendingPersistence() async {
        _ = await activities.persistTask?.result
        _ = await messages.persistTask?.result
        _ = await community.persistTask?.result
        _ = await buddies.persistTask?.result
        _ = await profilePersistTask?.result
        await SwiftDataSnapshotRegistry.awaitAllPendingSaves()
    }

    func wireFeatureCallbacks() {
        messages.onConversationsChanged = { [weak self] in
            self?.syncOrchestrator.handle(.conversationsChanged)
        }
        buddies.onRecordsChanged = { [weak self] in
            self?.syncOrchestrator.handle(.buddyRecordsChanged)
        }
        buddies.onMembershipChanged = { [weak self] in
            self?.syncOrchestrator.handle(.membershipChanged)
        }
    }
}

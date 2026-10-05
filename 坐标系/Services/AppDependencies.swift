//
//  AppDependencies.swift
//  坐标系
//
//  组合根门面：Features 只依赖此处注入的类型，不直接引用 AppComposition。
//

import CoordinateData
import CoordinateDomain
import Foundation

/// 应用级依赖容器（Apple 推荐 composition root 模式）。
@MainActor
struct AppDependencies {
    let repositories: AppRepositories

    let activitiesParticipation: ActivitiesParticipationUseCases
    let activitiesHosting: ActivitiesHostingUseCases
    let activitiesBrowse: ActivitiesBrowseUseCases
    let buddiesBooking: BuddiesBookingUseCases

    let activityEngagementStore: ActivityEngagementStore
    let profileRecentBrowseStore: ProfileRecentBrowseStore
    let locationService: LocationService
    let greetingWeatherStore: GreetingWeatherStore

    let walletStore: WalletStore
    let walletPassStore: WalletPassStore
    let refundFlowService: RefundFlowService
    let trustService: TrustService
    let productLifecycleStore: ProductLifecycleStore

    let membershipStore: MembershipStore
    let notificationPreferencesStore: NotificationPreferencesStore
    let inAppNotificationStore: InAppNotificationStore
    let privacyPreferencesStore: PrivacyPreferencesStore
    let youthModeStore: YouthModeStore
    let legalConsentStore: LegalConsentStore
    let photoVerificationStore: PhotoVerificationStore
    let opsContentStore: OpsContentStore
    let remoteBookingSync: any RemoteBookingSyncing
    let remoteInviteSync: any RemoteInviteSyncing
    let remoteClubSync: any RemoteClubSyncing

    static var live: AppDependencies {
        AppDependencies(
            repositories: .live,
            activitiesParticipation: AppComposition.activitiesParticipation,
            activitiesHosting: AppComposition.activitiesHosting,
            activitiesBrowse: AppComposition.activitiesBrowse,
            buddiesBooking: AppComposition.buddiesBooking,
            activityEngagementStore: AppComposition.activityEngagementStore,
            profileRecentBrowseStore: AppComposition.profileRecentBrowseStore,
            locationService: AppComposition.locationService,
            greetingWeatherStore: AppComposition.greetingWeatherStore,
            walletStore: AppComposition.walletStore,
            walletPassStore: AppComposition.walletPassStore,
            refundFlowService: AppComposition.refundFlowService,
            trustService: AppComposition.trustService,
            productLifecycleStore: AppComposition.productLifecycleStore,
            membershipStore: AppComposition.membershipStore,
            notificationPreferencesStore: AppComposition.notificationPreferencesStore,
            inAppNotificationStore: AppComposition.inAppNotificationStore,
            privacyPreferencesStore: AppComposition.privacyPreferencesStore,
            youthModeStore: AppComposition.youthModeStore,
            legalConsentStore: AppComposition.legalConsentStore,
            photoVerificationStore: AppComposition.photoVerificationStore,
            opsContentStore: AppComposition.opsContentStore,
            remoteBookingSync: RemoteBookingSyncService(client: .shared),
            remoteInviteSync: RemoteInviteSyncService(client: .shared),
            remoteClubSync: RemoteClubSyncService(client: .shared)
        )
    }

  /// Preview / 轻量测试：内存 Repository + 独立 Store 实例，避免污染正式数据。
    static func preview(
        repositories: AppRepositories = .inMemoryForTests()
    ) -> AppDependencies {
        let wallet = WalletStore()
        let passes: WalletPassStore = PassStore()
        let trust = TrustService(ledger: TrustBehaviorLedger())
        let location = LocationService()
        return AppDependencies(
            repositories: repositories,
            activitiesParticipation: ActivitiesParticipationUseCases(),
            activitiesHosting: ActivitiesHostingUseCases(),
            activitiesBrowse: ActivitiesBrowseUseCases(),
            buddiesBooking: BuddiesBookingUseCases(),
            activityEngagementStore: ActivityEngagementStore(
                repository: InMemoryEngagementRepository(snapshot: .seed)
            ),
            profileRecentBrowseStore: ProfileRecentBrowseStore(),
            locationService: location,
            greetingWeatherStore: GreetingWeatherStore(locationService: location),
            walletStore: wallet,
            walletPassStore: passes,
            refundFlowService: RefundFlowService(
                walletStore: wallet,
                walletPassStore: passes,
                trustService: trust
            ),
            trustService: trust,
            productLifecycleStore: ProductLifecycleStore(),
            membershipStore: MembershipStore(),
            notificationPreferencesStore: NotificationPreferencesStore(),
            inAppNotificationStore: InAppNotificationStore(),
            privacyPreferencesStore: PrivacyPreferencesStore(),
            youthModeStore: YouthModeStore(),
            legalConsentStore: LegalConsentStore(),
            photoVerificationStore: PhotoVerificationStore(trustService: trust),
            opsContentStore: OpsContentStore(),
            remoteBookingSync: DisabledRemoteBookingSync(),
            remoteInviteSync: DisabledRemoteInviteSync(),
            remoteClubSync: DisabledRemoteClubSync()
        )
    }

    static func inMemoryForTests(
        repositories: AppRepositories = .inMemoryForTests()
    ) -> AppDependencies {
        preview(repositories: repositories)
    }
}

// MARK: - Feature Model factories

extension AppDependencies {
    func makeActivitiesModel(
        currentUserName: String? = nil,
        repository: (any ActivitiesRepository)? = nil
    ) -> ActivitiesModel {
        ActivitiesModel(
            repository: repository ?? repositories.activities,
            engagementStore: activityEngagementStore,
            participation: activitiesParticipation,
            hosting: activitiesHosting,
            browse: activitiesBrowse,
            recentBrowseStore: profileRecentBrowseStore,
            walletPassStore: walletPassStore,
            locationService: locationService,
            currentUserName: currentUserName,
            currentUserID: LocalUserIdentity.current
        )
    }

    func makeMessagesModel(
        snapshot: MessagesSnapshot? = nil,
        repository: (any MessagesRepository)? = nil
    ) -> MessagesModel {
        MessagesModel(
            snapshot: snapshot,
            repository: repository ?? repositories.messages,
            walletStore: walletStore
        )
    }

    func makeCommunityModel(currentUserName: String? = nil) -> CommunityModel {
        CommunityModel(
            currentUserName: currentUserName,
            repository: repositories.community,
            engagement: CommunityEngagementUseCases(),
            moderation: CommunityModerationUseCases(),
            notificationInbox: inAppNotificationStore
        )
    }

    func makeBuddiesModel(
        snapshot: BuddiesSnapshot? = nil,
        repository: (any BuddiesRepository)? = nil,
        currentUserName: String? = nil
    ) -> BuddiesModel {
        BuddiesModel(
            repository: repository ?? repositories.buddies,
            booking: buddiesBooking,
            walletStore: walletStore,
            walletPassStore: walletPassStore,
            refundFlowService: refundFlowService,
            trustService: trustService,
            remoteBookingSync: remoteBookingSync,
            remoteInviteSync: remoteInviteSync,
            remoteClubSync: remoteClubSync,
            notificationInbox: inAppNotificationStore,
            snapshot: snapshot,
            currentUserName: currentUserName,
            currentUserID: LocalUserIdentity.current
        )
    }

    func makeAppModel(auth: LocalAuthSession? = nil) -> AppModel {
        AppModel(auth: auth, dependencies: self)
    }
}

//
//  AppComposition.swift
//  坐标系
//
//  应用组合根：Repository 与远程同步装配入口。
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import Foundation

enum AppComposition {
    static let activitiesParticipation = ActivitiesParticipationUseCases()
    static let activitiesBrowse = ActivitiesBrowseUseCases()
    static let buddiesBooking = BuddiesBookingUseCases()

    @MainActor static let activityEngagementStore = ActivityEngagementStore(
        repository: resolvedLocalEngagementRepository()
    )
    @MainActor static let profileRecentBrowseStore = ProfileRecentBrowseStore()

    @MainActor static let locationService = LocationService()
    @MainActor static let greetingWeatherStore = GreetingWeatherStore(locationService: locationService)

    @MainActor static let walletStore = WalletStore()
    @MainActor static let walletPassStore: WalletPassStore = PassStore()
    @MainActor static let trustBehaviorLedger = TrustBehaviorLedger()
    @MainActor static let trustService = TrustService(ledger: trustBehaviorLedger)
    @MainActor static let refundFlowService = RefundFlowService(
        walletStore: walletStore,
        walletPassStore: walletPassStore,
        trustService: trustService
    )
    @MainActor static let productLifecycleStore = ProductLifecycleStore()

    @MainActor static let membershipStore = MembershipStore()
    @MainActor static let notificationPreferencesStore = NotificationPreferencesStore()
    @MainActor static let privacyPreferencesStore = PrivacyPreferencesStore()
    @MainActor static let youthModeStore = YouthModeStore()
    @MainActor static let legalConsentStore = LegalConsentStore()
    @MainActor static let membershipAdImpressionStore = MembershipAdImpressionStore()
    @MainActor static let photoVerificationStore = PhotoVerificationStore(trustService: trustService)
    @MainActor static let opsContentStore = OpsContentStore()

    /// SwiftData `@ModelActor` 预热与旧 JSON 迁移；须在 `AppModel` 构造前完成。
    @MainActor
    static func bootstrapPersistence() async {
        await SwiftDataSnapshotRegistry.bootstrap()
        await profileRecentBrowseStore.bootstrap()
    }

    private static let activitiesPolicy = AppActivitiesSnapshotPolicy()
    private static let messagesPolicy = AppMessagesSnapshotPolicy()
    private static let buddiesPolicy = AppBuddiesSnapshotPolicy()
    private static let communityPolicy = AppCommunitySnapshotPolicy()
    private static let profilePolicy = AppProfileSnapshotPolicy()
    private static let engagementPolicy = AppEngagementSnapshotPolicy()

    @MainActor
    static func resolvedLocalActivitiesRepository() -> any ActivitiesRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataActivitiesRepository(gateway: SwiftDataSnapshotRegistry.activities)
        }
        return LocalActivitiesRepository(policy: activitiesPolicy)
    }

    @MainActor
    static func resolvedLocalMessagesRepository() -> any MessagesRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataMessagesRepository(gateway: SwiftDataSnapshotRegistry.messages)
        }
        return LocalMessagesRepository(policy: messagesPolicy)
    }

    @MainActor
    static func resolvedLocalBuddiesRepository() -> any BuddiesRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataBuddiesRepository(gateway: SwiftDataSnapshotRegistry.buddies)
        }
        return LocalBuddiesRepository(policy: buddiesPolicy)
    }

    @MainActor
    static func resolvedLocalCommunityRepository() -> any CommunityRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataCommunityRepository(gateway: SwiftDataSnapshotRegistry.community)
        }
        return LocalCommunityRepository(policy: communityPolicy)
    }

    @MainActor
    static func resolvedLocalProfileRepository() -> any ProfileRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataProfileRepository(gateway: SwiftDataSnapshotRegistry.profile)
        }
        return LocalProfileRepository(policy: profilePolicy)
    }

    @MainActor
    static func resolvedLocalEngagementRepository() -> any EngagementRepository {
        if FeatureFlags.useSwiftDataSnapshots {
            return SwiftDataEngagementRepository(gateway: SwiftDataSnapshotRegistry.engagement)
        }
        return LocalEngagementRepository(policy: engagementPolicy)
    }

    @MainActor
    static func makeActivitiesRepository() -> any ActivitiesRepository {
        // 始终包一层 Remote：开关只控制 sync，DEBUG 联调改旗标后无需重建 AppModel。
        RemoteActivitiesRepository(local: resolvedLocalActivitiesRepository())
    }

    @MainActor
    static func makeProfileRepository() -> any ProfileRepository {
        RemoteProfileRepository(local: resolvedLocalProfileRepository())
    }

    @MainActor
    static func makeMessagesRepository() -> any MessagesRepository {
        let local = resolvedLocalMessagesRepository()
        if FeatureFlags.useRemoteMessages {
            return RemoteMessagesRepository(local: local)
        }
        return local
    }

    @MainActor
    static func makeCommunityRepository() -> any CommunityRepository {
        RemoteCommunityRepository(local: resolvedLocalCommunityRepository())
    }

    @MainActor
    static func makeBuddiesRepository() -> any BuddiesRepository {
        let local = resolvedLocalBuddiesRepository()
        if FeatureFlags.useRemoteBuddies {
            return RemoteBuddiesRepository(local: local)
        }
        return local
    }

    /// bootstrap 阶段：按开关拉取远程快照，失败保留本地。
    static func syncRemoteSnapshotsIfEnabled(
        repositories: AppRepositories,
        profile: any ProfileRepository
    ) async {
        if let remote = repositories.activities as? RemoteActivitiesRepository {
            await remote.syncRemoteCatalogIfEnabled()
        }
        if let remote = profile as? RemoteProfileRepository {
            await remote.syncRemoteProfileIfEnabled()
        }
        if let remote = repositories.messages as? RemoteMessagesRepository {
            await remote.syncRemoteMessagesIfEnabled()
        }
        if let remote = repositories.community as? RemoteCommunityRepository {
            await remote.syncRemoteCommunityIfEnabled()
        }
        if let remote = repositories.buddies as? RemoteBuddiesRepository {
            await remote.syncRemoteBuddiesIfEnabled()
        }
    }
}

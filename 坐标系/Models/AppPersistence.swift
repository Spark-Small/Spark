//
//  AppPersistence.swift
//  坐标系
//

import CoordinateData
import CoordinateDomain
import Foundation
import CoordinateModels

enum AppPersistence {
    /// 内容目录版本：升级后合并新种子，保留用户活动与报名状态
    private static let catalogVersionKey = "app.catalog.version"
    static let catalogVersion = 8

    @MainActor
    static func resetLocalDemoData() async {
        AppComposition.resolvedLocalActivitiesRepository().save(.seed)
        AppComposition.resolvedLocalMessagesRepository().save(.seed)
        AppComposition.resolvedLocalBuddiesRepository().save(.seed)
        AppComposition.resolvedLocalProfileRepository().save(.seed)
        AppComposition.resolvedLocalCommunityRepository().save(.emptySeed)
        AppComposition.resolvedLocalEngagementRepository().save(.seed)
        await clearRecentBrowseData()
        LocalMediaLibrary.resetAll()
        ActivityPaymentStore.resetAll()
        AppComposition.refundFlowService.resetAll()
        ActivityCommentsStore.resetAll()
        ActivityDetailContentStore.resetAll()
        AppComposition.walletStore.resetAll()
        AppComposition.walletPassStore.resetAll()
        AppComposition.trustService.resetAll()
        AppComposition.photoVerificationStore.resetAll()
        AppComposition.productLifecycleStore.resetAll()
        AppComposition.opsContentStore.resetAll()
        AppComposition.youthModeStore.reset()
        AppComposition.legalConsentStore.reset()
        AppComposition.membershipAdImpressionStore.reset()
        UserDefaults.standard.removeObject(forKey: "profile.wallet.balanceCents")
        UserDefaults.standard.removeObject(forKey: "profile.membership.active")
        UserDefaults.standard.removeObject(forKey: PrivacyPreferenceKey.showDistance)
        UserDefaults.standard.removeObject(forKey: PrivacyPreferenceKey.showOnline)
        UserDefaults.standard.removeObject(forKey: PrivacyPreferenceKey.allowInvite)
        PermissionLaunchPrompts.reset()
        ActivityCalendarStore.reset()
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

    @MainActor
    static func clearRecentBrowseData() async {
        PersistenceMigration.removeLegacyFile("profile_recent_browse.json")
        try? await AppComposition.profileRecentBrowseStore.clearSynchronously()
    }

    @MainActor
    static func refreshCatalogIfNeeded() {
        let current = UserDefaults.standard.integer(forKey: catalogVersionKey)
        guard current < catalogVersion else { return }

        mergeActivitiesCatalog()
        mergeMessagesCatalog()
        mergeBuddiesCatalogIfNeeded()

        let communityRepository = AppComposition.resolvedLocalCommunityRepository()
        let community = communityRepository.load()
        if community.posts.isEmpty {
            communityRepository.save(.emptySeed)
        }

        let profileRepository = AppComposition.resolvedLocalProfileRepository()
        var profile = profileRepository.load()
        profile.user.id = LocalUserIdentity.current
        profile.user.joinedCount = SampleData.currentUser.joinedCount
        profile.user.hostedCount = SampleData.currentUser.hostedCount
        profile.user.buddyCount = SampleData.currentUser.buddyCount
        if profile.user.interests.isEmpty {
            profile.user.interests = SampleData.currentUserInterests
        }
        profileRepository.save(profile)

        UserDefaults.standard.set(catalogVersion, forKey: catalogVersionKey)
    }

    @MainActor
    private static func mergeActivitiesCatalog() {
        let repository = AppComposition.resolvedLocalActivitiesRepository()
        let repaired = ActivitiesSnapshotCatalog.repair(from: repository.load())
        repository.save(repaired)
    }

    @MainActor
    private static func mergeMessagesCatalog() {
        let repository = AppComposition.resolvedLocalMessagesRepository()
        let repaired = MessagesSnapshotCatalog.repair(from: repository.load())
        repository.save(repaired)
    }

    @MainActor
    private static func mergeBuddiesCatalogIfNeeded() {
        let repository = AppComposition.resolvedLocalBuddiesRepository()
        guard let merged = BuddiesSnapshotCatalog.mergeCatalog(into: repository.load()) else { return }
        repository.save(merged)
    }
}

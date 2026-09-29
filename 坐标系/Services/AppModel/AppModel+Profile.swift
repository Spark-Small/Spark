//
//  AppModel+Profile.swift
//  坐标系
//

import Foundation
import CoordinateModels

extension AppModel {
    func updateProfile(_ updated: AppUser) {
        let previousName = user.name
        var next = updated
        next.id = LocalUserIdentity.current
        syncOrchestrator.handle(.profileUpdated(previousName: previousName, user: next))
    }

    func updateLookingFor(_ text: String) {
        var updated = user
        updated.lookingFor = text
        updateProfile(updated)
    }

    func syncProfileStats() {
        derivedStateService.refreshProfileStats(app: self)
    }

    func bootstrapProfileAfterWelcomeGuide(interests: [String]) {
        syncOrchestrator.handle(.onboardingCompleted(interests: interests))
    }

    /// 保留旧名，指向欢迎引导 bootstrap。
    func completeOnboarding(interests: [String]) {
        bootstrapProfileAfterWelcomeGuide(interests: interests)
    }

    func isFollowing(_ name: String) -> Bool {
        followedUserNames.contains(name)
    }

    func toggleFollow(_ name: String) {
        if followedUserNames.contains(name) {
            followedUserNames.remove(name)
        } else {
            followedUserNames.insert(name)
        }
        persistProfile()
    }

    func blockUser(_ name: String) {
        syncOrchestrator.handle(.userBlocked(name))
    }

    func unblockUser(_ name: String) {
        syncOrchestrator.handle(.userUnblocked(name))
    }

    func signOutLocally(clearOnboarding: Bool = true) async {
        await quiesceAllPersistence()
        auth.signOut()
        // 与删号对齐：清掉钱包 / 凭证 / 订单等旁路商业态，避免下一账号看到上一账号余额。
        clearCommerceSideStateOnSignOut()
        if clearOnboarding {
            hasCompletedWelcomeBootstrap = false
            welcomeGuide.reset()
        }
        persistProfile()
    }

    /// 退出登录时清理商业旁路状态（不重置活动 / 消息目录）。
    private func clearCommerceSideStateOnSignOut() {
        walletStore.resetAll()
        walletPassStore.resetAll()
        ActivityPaymentStore.resetAll()
        refundFlowService.resetAll()
        membershipStore.clearLocalEntitlement()
        UserDefaults.standard.removeObject(forKey: "profile.wallet.balanceCents")
    }

    func clearLocalCaches() {
        blockedUserNames = []
        moderationTickets = []
        buddies.blockedUserNames = []
        community.blockedUserNames = []
        persistProfile()
    }

    func resetLocalDemoData() async {
        await quiesceAllPersistence()
        await AppPersistence.resetLocalDemoData()
        activityEngagementStore.reloadFromDisk()
        try? await profileRecentBrowseStore.clearSynchronously()
        reloadFromLocalState(keepSignedIn: true)
    }

    func deleteLocalAccount() async {
        await quiesceAllPersistence()
        await AppPersistence.resetLocalDemoData()
        activityEngagementStore.reloadFromDisk()
        try? await profileRecentBrowseStore.clearSynchronously()
        auth.resetStoredSession()
        reloadFromLocalState(keepSignedIn: false)
    }
}

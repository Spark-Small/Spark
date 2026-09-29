//
//  WelcomeGuideStore.swift
//  坐标系
//
//  首启半屏欢迎引导的唯一状态源；完成后 bootstrap 资料兴趣。
//

import CoordinateModels
import Foundation

@MainActor
@Observable
final class WelcomeGuideStore {
    static let storageKey = AppWelcomeGuideCopy.storageKey

    var hasSeenGuide: Bool {
        didSet { UserDefaults.standard.set(hasSeenGuide, forKey: Self.storageKey) }
    }

    init() {
        hasSeenGuide = UserDefaults.standard.bool(forKey: Self.storageKey)
    }

    /// 欢迎引导完成或跳过：写标记并 bootstrap 兴趣（幂等）。
    func finish(app: AppModel, intent: AppWelcomeIntent = .browse) {
        guard !hasSeenGuide else { return }
        hasSeenGuide = true
        app.selectedTab = intent.landingTab

        if let message = app.activities.applyWelcomeLanding(for: intent) {
            app.activities.flashLight(message)
        } else if intent == .meetPeople {
            app.buddies.showSocialPage()
            app.buddies.pendingShowCircleDiscover = true
            app.activities.flashLight(AppWelcomeGuideCopy.meetPeopleConfirmed)
        }

        guard !app.hasCompletedWelcomeBootstrap else { return }
        let interests = app.user.interests.isEmpty
            ? intent.profileInterests
            : app.user.interests
        app.bootstrapProfileAfterWelcomeGuide(interests: interests)
    }

    /// 登出 / 删号时与 `hasCompletedWelcomeBootstrap` 一并重置。
    func reset() {
        hasSeenGuide = false
    }

    /// 旧版仅完成全屏兴趣引导、未写欢迎标记的账号迁移。
    func migrateLegacyOnboardingIfNeeded(app: AppModel) {
        if app.hasCompletedWelcomeBootstrap, !hasSeenGuide {
            hasSeenGuide = true
        }
    }
}

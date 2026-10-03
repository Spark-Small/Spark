//
//  WelcomeGuideStore.swift
//  坐标系
//
//  首启欢迎意图的唯一状态源；完成后落地 Tab / 筛选（兴趣由 InterestOnboardingView 写入）。
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

    /// 欢迎引导完成或跳过：写标记、落地 Tab / 筛选；兴趣仅由兴趣选择页写入。
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
    }

    /// 登出 / 删号时与 `hasCompletedInterestSelection` 一并重置。
    func reset() {
        hasSeenGuide = false
    }

    /// 旧版仅完成全屏兴趣引导、未写欢迎标记的账号迁移。
    func migrateLegacyOnboardingIfNeeded(app: AppModel) {
        if app.hasCompletedInterestSelection, !hasSeenGuide {
            hasSeenGuide = true
        }
    }
}

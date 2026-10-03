//
//  InterestAnalytics.swift
//  坐标系
//
//  兴趣选择漏斗埋点（与 AuthAnalytics 同构；事件名稳定）。
//

import Foundation

enum InterestAnalytics {
    static func onboardingPresented(draftCount: Int) {
        Analytics.track("interest_onboarding_present", [
            "draft_count": "\(draftCount)"
        ])
    }

    static func onboardingCompleted(count: Int) {
        Analytics.track("interest_onboarding_complete", [
            "count": "\(count)"
        ])
    }

    static func onboardingAbandoned(count: Int, reason: String) {
        Analytics.track("interest_onboarding_abandon", [
            "count": "\(count)",
            "reason": String(reason.prefix(40))
        ])
    }

    static func selectionLimitReached(count: Int) {
        Analytics.track("interest_selection_limit", [
            "count": "\(count)"
        ])
    }
}

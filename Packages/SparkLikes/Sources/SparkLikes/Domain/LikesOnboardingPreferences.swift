// Module: SparkLikes — Onboarding flag boundary (Domain protocol).

import Foundation

public protocol LikesOnboardingPreferences: Sendable {
    var hasSeenOnboarding: Bool { get }
    func markOnboardingSeen()
}

// Module: SparkLikes — First-visit discover onboarding flag.

import Foundation

public enum LikesOnboardingStore: Sendable {
    private static let seenKey = "likes.onboarding.seen"

    public static var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: seenKey)
    }

    public static func markOnboardingSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }
}

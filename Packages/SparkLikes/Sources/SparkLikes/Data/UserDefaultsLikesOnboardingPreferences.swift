// Module: SparkLikes — UserDefaults-backed onboarding flag.

import Foundation

// REASONING: UserDefaults is process-local; callers serialize reads/writes on @MainActor.
public final class UserDefaultsLikesOnboardingPreferences: LikesOnboardingPreferences, @unchecked Sendable {
    private static let seenKey = "likes.onboarding.seen"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var hasSeenOnboarding: Bool {
        defaults.bool(forKey: Self.seenKey)
    }

    public func markOnboardingSeen() {
        defaults.set(true, forKey: Self.seenKey)
    }
}

// Module: SparkLikes — In-memory onboarding flag for tests and previews.

import Foundation

public final class InMemoryLikesOnboardingPreferences: LikesOnboardingPreferences, @unchecked Sendable {
    public var hasSeenOnboarding: Bool

    public init(hasSeenOnboarding: Bool = false) {
        self.hasSeenOnboarding = hasSeenOnboarding
    }

    public func markOnboardingSeen() {
        hasSeenOnboarding = true
    }
}

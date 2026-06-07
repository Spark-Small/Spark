// Module: SparkLikes — In-memory preferences for tests and previews.

import Foundation

public final class InMemoryLikesPreferencesStore: LikesPreferencesStoring, @unchecked Sendable {
    public var stored: LikesPreferences

    public init(stored: LikesPreferences = LikesPreferences()) {
        self.stored = stored
    }

    public func load() -> LikesPreferences {
        stored
    }

    public func save(_ preferences: LikesPreferences) {
        stored = preferences
    }
}

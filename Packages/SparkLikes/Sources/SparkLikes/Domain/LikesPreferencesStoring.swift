// Module: SparkLikes — Discover preferences persistence boundary.

import Foundation

public protocol LikesPreferencesStoring: Sendable {
    func load() -> LikesPreferences
    func save(_ preferences: LikesPreferences)
}

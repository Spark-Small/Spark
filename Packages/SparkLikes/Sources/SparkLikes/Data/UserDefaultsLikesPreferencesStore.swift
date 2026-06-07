// Module: SparkLikes — UserDefaults-backed discover preferences.

import Foundation

public final class UserDefaultsLikesPreferencesStore: LikesPreferencesStoring, @unchecked Sendable {
    private static let genderKey = "likes.pref.gender"
    private static let intentKey = "likes.pref.intent"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> LikesPreferences {
        let gender = LikesGenderPreference(rawValue: defaults.string(forKey: Self.genderKey) ?? "") ?? .all
        let intent = LikesIntent(rawValue: defaults.string(forKey: Self.intentKey) ?? "") ?? .match
        return LikesPreferences(genderPreference: gender, intent: intent)
    }

    public func save(_ preferences: LikesPreferences) {
        defaults.set(preferences.genderPreference.rawValue, forKey: Self.genderKey)
        defaults.set(preferences.intent.rawValue, forKey: Self.intentKey)
    }
}

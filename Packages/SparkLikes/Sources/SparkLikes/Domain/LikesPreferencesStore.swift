// Module: SparkLikes — Local discover preferences (non-sensitive).

import Foundation

public struct LikesPreferences: Sendable, Equatable {
    public var genderPreference: LikesGenderPreference
    public var intent: LikesIntent

    public init(
        genderPreference: LikesGenderPreference = .all,
        intent: LikesIntent = .match
    ) {
        self.genderPreference = genderPreference
        self.intent = intent
    }
}

public enum LikesPreferencesStore: Sendable {
    private static let genderKey = "likes.pref.gender"
    private static let intentKey = "likes.pref.intent"

    public static func load() -> LikesPreferences {
        let defaults = UserDefaults.standard
        let gender = LikesGenderPreference(rawValue: defaults.string(forKey: genderKey) ?? "") ?? .all
        let intent = LikesIntent(rawValue: defaults.string(forKey: intentKey) ?? "") ?? .match
        return LikesPreferences(genderPreference: gender, intent: intent)
    }

    public static func save(_ preferences: LikesPreferences) {
        let defaults = UserDefaults.standard
        defaults.set(preferences.genderPreference.rawValue, forKey: genderKey)
        defaults.set(preferences.intent.rawValue, forKey: intentKey)
    }
}

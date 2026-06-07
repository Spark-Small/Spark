// Module: SparkLikes — Discover preference model.

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

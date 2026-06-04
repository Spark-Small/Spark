// Module: SparkLikes — Feed filter preferences.

import Foundation

public enum LikesGenderPreference: String, Sendable, CaseIterable, Identifiable {
    case all
    case same
    case opposite

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "likes.pref.gender.all", defaultValue: "全部", comment: "Gender pref")
        case .same:
            String(localized: "likes.pref.gender.same", defaultValue: "同性", comment: "Gender pref")
        case .opposite:
            String(localized: "likes.pref.gender.opposite", defaultValue: "异性", comment: "Gender pref")
        }
    }

    public var wireValue: String { rawValue }
}

public enum LikesIntent: String, Sendable, CaseIterable, Identifiable {
    case friends
    case match

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .friends:
            String(localized: "likes.pref.intent.friends", defaultValue: "交朋友", comment: "Intent")
        case .match:
            String(localized: "likes.pref.intent.match", defaultValue: "配对", comment: "Intent")
        }
    }

    public var wireValue: String { rawValue }
}

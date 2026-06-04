// Module: SparkLikes — Profile gender (display / filter only).

import Foundation

public enum DiscoverGender: String, Sendable, Codable, CaseIterable, Identifiable {
    case male
    case female
    case other

    public var id: String { rawValue }

    public var localizedLabel: String {
        switch self {
        case .male:
            String(localized: "likes.gender.male", defaultValue: "男", comment: "Gender")
        case .female:
            String(localized: "likes.gender.female", defaultValue: "女", comment: "Gender")
        case .other:
            String(localized: "likes.gender.other", defaultValue: "其他", comment: "Gender")
        }
    }

    public init?(wireValue: String) {
        self.init(rawValue: wireValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}

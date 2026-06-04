// Module: SparkLikes — Viewer profile gate for discover actions.

import Foundation

public struct LikesViewerProfile: Sendable, Equatable {
    public var displayName: String
    public var hasPhoto: Bool

    public init(displayName: String = "", hasPhoto: Bool = false) {
        self.displayName = displayName
        self.hasPhoto = hasPhoto
    }

    public var isComplete: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasPhoto
    }
}

/// Non-PII local hint only — profile data comes from `GET /v1/likes/viewer-profile`.
public enum LikesViewerProfileStore: Sendable {
    private static let gateCompleteKey = "likes.viewer.gateComplete"

    public static var isGateMarkedComplete: Bool {
        UserDefaults.standard.bool(forKey: gateCompleteKey)
    }

    public static func markGateComplete(_ isComplete: Bool) {
        UserDefaults.standard.set(isComplete, forKey: gateCompleteKey)
    }
}

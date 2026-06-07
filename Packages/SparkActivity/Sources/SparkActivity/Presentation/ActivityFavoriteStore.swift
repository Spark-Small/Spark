// Module: SparkActivity — Local saved activities (list-card heart toggle).

import Foundation
import Observation

@MainActor
@Observable
public final class ActivityFavoriteStore {
    private static let storageKey = "spark.activity.favoriteIDs"

    public private(set) var favoriteIDs: Set<String>

    public init(favoriteIDs: Set<String>? = nil) {
        if let favoriteIDs {
            self.favoriteIDs = favoriteIDs
        } else if let stored = UserDefaults.standard.array(forKey: Self.storageKey) as? [String] {
            self.favoriteIDs = Set(stored)
        } else {
            self.favoriteIDs = []
        }
    }

    public func isFavorite(activityID: String) -> Bool {
        favoriteIDs.contains(activityID)
    }

    public func toggle(activityID: String) {
        if favoriteIDs.contains(activityID) {
            favoriteIDs.remove(activityID)
        } else {
            favoriteIDs.insert(activityID)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: Self.storageKey)
    }
}

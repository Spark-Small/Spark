// Module: SparkCommunity — Stable mock author avatar URLs (Data layer only).

import Foundation

enum MockCommunityAvatarCatalog {
    /// Mock CDN path used in feed DTOs and previews — never constructed in Views.
    static func authorAvatarURL(userID: String) -> URL? {
        URL(string: "https://cdn.spark.mock/avatars/\(userID).jpg")
    }
}

// Module: SparkActivity — Deterministic cover art for list cards until API ships `cover_url`.

import Foundation

enum ActivityCoverImage {
    static func url(
        activityID: String,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool = false
    ) -> URL? {
        if coverIsVideo, let coverPosterURL {
            return coverPosterURL
        }
        if let coverURL {
            return coverURL
        }
        let seed = activityID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? activityID
        return URL(string: "https://picsum.photos/seed/spark-activity-\(seed)/800/450")
    }
}

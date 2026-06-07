// Module: SparkCore — Gallery item for Community posts and Activity share.

import Foundation

public enum SparkGalleryMediaKind: String, Sendable, Codable, Hashable {
    case image
    case video
}

public struct SparkGalleryMedia: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let url: URL
    public let kind: SparkGalleryMediaKind
    public let posterURL: URL?

    public init(
        id: String,
        url: URL,
        kind: SparkGalleryMediaKind = .image,
        posterURL: URL? = nil
    ) {
        self.id = id
        self.url = url
        self.kind = kind
        self.posterURL = posterURL
    }
}

public enum SparkGalleryMediaFactory {
    /// Deterministic mock activity gallery until activity media upload ships.
    public static func mockActivityGallery(activityID: String, count: Int = 3) -> [SparkGalleryMedia] {
        (1 ... count).compactMap { index in
            guard let url = URL(string: "https://picsum.photos/seed/spark-activity-\(activityID)-\(index)/1280/960") else {
                return nil
            }
            return SparkGalleryMedia(
                id: "\(activityID)-\(index)",
                url: url,
                kind: .image
            )
        }
    }
}

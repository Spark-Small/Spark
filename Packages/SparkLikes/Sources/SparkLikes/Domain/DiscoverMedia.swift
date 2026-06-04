// Module: SparkLikes — Card media (image or video).

import Foundation

public enum DiscoverMediaKind: String, Sendable, Codable {
    case image
    case video
}

public struct DiscoverMedia: Hashable, Sendable, Equatable {
    public let kind: DiscoverMediaKind
    public let url: URL
    public let posterURL: URL?

    public init(kind: DiscoverMediaKind, url: URL, posterURL: URL? = nil) {
        self.kind = kind
        self.url = url
        self.posterURL = posterURL
    }
}

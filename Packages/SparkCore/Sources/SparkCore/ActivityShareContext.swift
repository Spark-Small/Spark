// Module: SparkCore — Cross-tab payload for sharing an ended activity to Community.

import Foundation

/// Context passed from Activity tab when opening the Community share sheet.
public struct ActivityShareContext: Sendable, Equatable {
    public let activityID: String
    public let title: String
    public let scheduleLine: String
    public let mediaGallery: [SparkGalleryMedia]

    public init(
        activityID: String,
        title: String,
        scheduleLine: String,
        coverImageURL: URL? = nil,
        mediaGallery: [SparkGalleryMedia]? = nil
    ) {
        self.activityID = activityID
        self.title = title
        self.scheduleLine = scheduleLine
        if let mediaGallery {
            self.mediaGallery = mediaGallery
        } else if let coverImageURL {
            self.mediaGallery = [
                SparkGalleryMedia(id: "\(activityID)-cover", url: coverImageURL, kind: .image)
            ]
        } else {
            self.mediaGallery = Self.mockMediaGallery(activityID: activityID)
        }
    }

    /// First image for legacy single-cover call sites.
    public var coverImageURL: URL? {
        mediaGallery.first(where: { $0.kind == .image })?.url ?? mediaGallery.first?.url
    }

    /// Deterministic activity gallery for Mock / MVP until activity media upload ships.
    public static func mockMediaGallery(activityID: String) -> [SparkGalleryMedia] {
        SparkGalleryMediaFactory.mockActivityGallery(activityID: activityID)
    }

    /// Deterministic activity cover for Mock / MVP until activity media upload ships.
    public static func mockCoverImageURL(activityID: String) -> URL? {
        mockMediaGallery(activityID: activityID).first?.url
    }
}

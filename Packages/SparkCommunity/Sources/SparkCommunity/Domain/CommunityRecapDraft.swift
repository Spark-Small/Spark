// Module: SparkCommunity — Post-event activity share payload (published to Community feed).

import Foundation
import SparkCore

public struct CommunityRecapDraft: Sendable, Equatable {
    public static let maxBodyLength = 2_000

    public let activityID: String
    public let activityTitle: String
    public let scheduleLine: String
    public let body: String
    public let mediaGallery: [SparkGalleryMedia]
    public let includesCoverImage: Bool

    public init(
        activityID: String,
        activityTitle: String,
        scheduleLine: String,
        body: String,
        coverImageURL: URL? = nil,
        mediaGallery: [SparkGalleryMedia]? = nil,
        includesCoverImage: Bool = true
    ) {
        self.activityID = activityID
        self.activityTitle = activityTitle
        self.scheduleLine = scheduleLine
        self.body = body
        if let mediaGallery {
            self.mediaGallery = mediaGallery
        } else if let coverImageURL {
            self.mediaGallery = [
                SparkGalleryMedia(id: "\(activityID)-cover", url: coverImageURL, kind: .image)
            ]
        } else {
            self.mediaGallery = []
        }
        self.includesCoverImage = includesCoverImage
    }

    public var normalizedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var publishedMedia: [SparkGalleryMedia] {
        includesCoverImage ? mediaGallery : []
    }

    public var shareImageURL: URL? {
        publishedMedia.first(where: { $0.kind == .image })?.url ?? publishedMedia.first?.url
    }

    public var postTitle: String {
        let format = String(
            localized: "community.activityShare.postTitle.format",
            defaultValue: "「%@」局后随拍",
            comment: "Activity share post title; %@ activity title"
        )
        return String(format: format, locale: .current, activityTitle)
    }

    public static func validate(_ draft: CommunityRecapDraft) throws {
        let body = draft.normalizedBody
        guard !body.isEmpty else {
            throw CommunityError.emptyInput
        }
        if body.count > maxBodyLength {
            throw CommunityError.fieldTooLong
        }
    }
}

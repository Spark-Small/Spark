// Module: SparkCommunity — Text post draft (MODULE-E).

import Foundation
import SparkCore

public struct CreateCommunityPostDraft: Sendable, Equatable {
    public var title: String
    public var body: String
    public var mediaItems: [SparkGalleryMedia]

    public init(title: String = "", body: String = "", mediaItems: [SparkGalleryMedia] = []) {
        self.title = title
        self.body = body
        self.mediaItems = mediaItems
    }

    public var imageURL: URL? {
        mediaItems.first(where: { $0.kind == .image })?.url ?? mediaItems.first?.url
    }

    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

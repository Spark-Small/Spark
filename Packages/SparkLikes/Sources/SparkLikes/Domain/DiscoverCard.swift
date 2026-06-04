// Module: SparkLikes — One discover feed card.

import Foundation
import SparkCore

public struct DiscoverCard: Identifiable, Hashable, Sendable, Equatable {
    public let userID: UserID
    public let displayName: String
    public let bio: String
    public let gender: DiscoverGender?
    public let media: DiscoverMedia
    public let mediaItems: [DiscoverMedia]
    public let interestTags: [String]
    public let coarseLocation: String?
    public let sharedActivityTitle: String?
    public let sharedActivityID: String?

    public var id: String { userID.rawValue }

    /// All swipeable media for the card (multi-photo gallery).
    public var galleryMedia: [DiscoverMedia] {
        mediaItems.isEmpty ? [media] : mediaItems
    }

    public init(
        userID: UserID,
        displayName: String,
        bio: String,
        gender: DiscoverGender?,
        media: DiscoverMedia,
        mediaItems: [DiscoverMedia] = [],
        interestTags: [String] = [],
        coarseLocation: String? = nil,
        sharedActivityTitle: String? = nil,
        sharedActivityID: String? = nil
    ) {
        self.userID = userID
        self.displayName = displayName
        self.bio = bio
        self.gender = gender
        self.media = media
        self.mediaItems = mediaItems.isEmpty ? [media] : mediaItems
        self.interestTags = interestTags
        self.coarseLocation = coarseLocation
        self.sharedActivityTitle = sharedActivityTitle
        self.sharedActivityID = sharedActivityID
    }
}

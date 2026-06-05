// Module: SparkLikes — Someone who liked the viewer.

import Foundation
import SparkCore

public struct InboundLikeItem: Identifiable, Hashable, Sendable, Equatable {
    public let userID: UserID
    public let card: DiscoverCard
    public let likedAt: Date?
    /// When `false`, non-premium users see blurred identity (ADR-0004).
    public let isVisible: Bool
    public let intensity: LikeIntensity
    public let opener: String?
    public let likedQuestionID: String?

    public var id: String { userID.rawValue }

    public init(
        userID: UserID,
        card: DiscoverCard,
        likedAt: Date? = nil,
        isVisible: Bool = true,
        intensity: LikeIntensity = .like,
        opener: String? = nil,
        likedQuestionID: String? = nil
    ) {
        self.userID = userID
        self.card = card
        self.likedAt = likedAt
        self.isVisible = isVisible
        self.intensity = intensity
        self.opener = opener
        self.likedQuestionID = likedQuestionID
    }
}

public struct LikesInboundPage: Sendable, Equatable {
    public let items: [InboundLikeItem]
    public let nextCursor: String?

    public init(items: [InboundLikeItem], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

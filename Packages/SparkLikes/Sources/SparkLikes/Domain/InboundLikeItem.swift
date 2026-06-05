// Module: SparkLikes — Someone who liked the viewer.

import Foundation
import SparkCore

public struct InboundLikeItem: Identifiable, Hashable, Sendable, Equatable {
    public let userID: UserID
    public let card: DiscoverCard
    public let likedAt: Date?
    /// When `false`, non-premium users see blurred identity (ADR-0004).
    public let isVisible: Bool

    public var id: String { userID.rawValue }

    public init(
        userID: UserID,
        card: DiscoverCard,
        likedAt: Date? = nil,
        isVisible: Bool = true
    ) {
        self.userID = userID
        self.card = card
        self.likedAt = likedAt
        self.isVisible = isVisible
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

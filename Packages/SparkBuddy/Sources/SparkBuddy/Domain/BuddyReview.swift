// Module: SparkBuddy — User review excerpt for listing social proof.

import Foundation

public struct BuddyReview: Identifiable, Equatable, Sendable {
    public let id: String
    public let authorDisplayName: String
    public let rating: Double
    public let comment: String
    public let createdAt: Date?

    public init(
        id: String,
        authorDisplayName: String,
        rating: Double,
        comment: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.authorDisplayName = authorDisplayName
        self.rating = min(5, max(1, rating))
        self.comment = comment
        self.createdAt = createdAt
    }
}

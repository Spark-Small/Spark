// Module: SparkBuddy — Companion listing row / detail model.

import Foundation

public struct BuddyListing: Identifiable, Equatable, Sendable {
    public let id: String
    /// Companion host user id for messaging and voice pre-chat.
    public let ownerUserID: String
    public let displayName: String
    public let avatarURL: URL?
    public let coverURL: URL?
    public let introVideoURL: URL?
    /// Short punchy headline for the list row.
    public let headline: String
    /// Longer description shown in detail view.
    public let description: String
    public let city: String
    public let serviceCategory: BuddyServiceCategory
    public let billingKind: BuddyBillingKind
    public let priceAmount: Decimal
    public let priceCurrencyCode: String
    /// Interest / capability tags (摄影达人, CityWalk, etc.).
    public let tags: [String]
    public let rating: Double?
    public let reviewCount: Int
    public let completedOrderCount: Int
    public let isVerified: Bool
    public let supportsOfflineMeetup: Bool
    public let supportsPaidCompanion: Bool
    public let trust: BuddyTrustProfile?
    public let matchInsight: BuddyMatchInsight?
    public let packages: [BuddyServicePackage]
    public let reviewSnapshot: BuddyReviewSnapshot?

    public init(
        id: String,
        ownerUserID: String,
        displayName: String,
        avatarURL: URL?,
        coverURL: URL?,
        introVideoURL: URL? = nil,
        headline: String,
        description: String = "",
        city: String,
        serviceCategory: BuddyServiceCategory,
        billingKind: BuddyBillingKind,
        priceAmount: Decimal,
        priceCurrencyCode: String,
        tags: [String],
        rating: Double?,
        reviewCount: Int,
        completedOrderCount: Int = 0,
        isVerified: Bool,
        supportsOfflineMeetup: Bool,
        supportsPaidCompanion: Bool,
        trust: BuddyTrustProfile? = nil,
        matchInsight: BuddyMatchInsight? = nil,
        packages: [BuddyServicePackage] = [],
        reviewSnapshot: BuddyReviewSnapshot? = nil
    ) {
        self.id = id
        self.ownerUserID = ownerUserID
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.coverURL = coverURL
        self.introVideoURL = introVideoURL
        self.headline = headline
        self.description = description
        self.city = city
        self.serviceCategory = serviceCategory
        self.billingKind = billingKind
        self.priceAmount = priceAmount
        self.priceCurrencyCode = priceCurrencyCode
        self.tags = tags
        self.rating = rating
        self.reviewCount = reviewCount
        self.completedOrderCount = completedOrderCount
        self.isVerified = isVerified
        self.supportsOfflineMeetup = supportsOfflineMeetup
        self.supportsPaidCompanion = supportsPaidCompanion
        self.trust = trust
        self.matchInsight = matchInsight
        self.packages = packages
        self.reviewSnapshot = reviewSnapshot
    }
}

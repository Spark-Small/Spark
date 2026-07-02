// Module: SparkBuddy — Listing DTOs.

import Foundation

struct BuddyListingDTO: Decodable, Sendable {
    let id: String
    let ownerUserID: String?
    let displayName: String
    let avatarURL: String?
    let coverURL: String?
    let introVideoURL: String?
    let headline: String
    let description: String?
    let city: String
    let serviceCategory: String
    let billingKind: String
    let priceAmount: String
    let priceCurrencyCode: String
    let tags: [String]?
    let rating: Double?
    let reviewCount: Int?
    let completedOrderCount: Int?
    let isVerified: Bool?
    let supportsOfflineMeetup: Bool?
    let supportsPaidCompanion: Bool?
    let trust: BuddyTrustProfileDTO?
    let matchInsight: BuddyMatchInsightDTO?
    let packages: [BuddyServicePackageDTO]?
    let reviewSnapshot: BuddyReviewSnapshotDTO?
}

struct BuddyTrustProfileDTO: Decodable, Sendable {
    let hasIdentityVerified: Bool?
    let hasPhoneVerified: Bool?
    let hasFaceVerified: Bool?
    let hasEmergencyContact: Bool?
    let authenticityScore: Int?
    let socialScore: Int?
    let talkativenessScore: Int?
    let photographyScore: Int?
    let localFamiliarityScore: Int?
}

struct BuddyMatchInsightDTO: Decodable, Sendable {
    let matchPercent: Int
    let reason: String
}

struct BuddyServicePackageDTO: Decodable, Sendable {
    let id: String
    let title: String
    let durationHours: Int
    let priceAmount: String
    let priceCurrencyCode: String
    let inclusions: [String]?
    let exclusions: [String]?
}

struct BuddyReviewSnapshotDTO: Decodable, Sendable {
    let punctuality: Double
    let communication: Double
    let expertise: Double
    let safety: Double
    let fun: Double
    let recommend: Double
    let reviews: [BuddyReviewDTO]?
    let highlightReviews: [BuddyReviewDTO]?
}

struct BuddyReviewDTO: Decodable, Sendable {
    let id: String
    let authorDisplayName: String
    let rating: Double
    let comment: String
    let createdAt: String?
}

struct BuddyListPageDTO: Decodable, Sendable {
    let items: [BuddyListingDTO]
    let nextCursor: String?
}

struct BuddyOrderConfirmationDTO: Decodable, Sendable {
    let id: String
    let listingID: String
    let packageID: String
    let escrowHeld: Bool?
}

struct BuddyCreateOrderRequestDTO: Encodable, Sendable {
    let listingID: String
    let packageID: String
    let scheduledAt: String
    let paymentMethod: String?
}

struct BuddyProviderStatusDTO: Decodable, Sendable {
    let state: String
    let submittedAt: String?
    let reviewedAt: String?
    let rejectionReason: String?
}

struct BuddyProviderApplicationRequestDTO: Encodable, Sendable {
    let displayName: String
    let city: String
    let serviceCategory: String
    let bio: String
    let capabilityTags: [String]
}

struct BuddyProviderEarningsDTO: Decodable, Sendable {
    let availableBalance: String
    let pendingEscrow: String
    let currencyCode: String
    let completedOrderCount: Int
    let monthEarnings: String
}

struct BuddyProviderOrderDTO: Decodable, Sendable {
    let id: String
    let guestDisplayName: String
    let packageTitle: String
    let scheduledAt: String
    let amount: String
    let currencyCode: String
    let state: String
}

// Module: SparkBuddy — Verification + AI trust scores for a companion.

import Foundation

/// Dual real-name verification and platform trust indices (mock-backed until Live API).
public struct BuddyTrustProfile: Equatable, Sendable {
    public let hasIdentityVerified: Bool
    public let hasPhoneVerified: Bool
    public let hasFaceVerified: Bool
    public let hasEmergencyContact: Bool
    /// 0–100 authenticity index from platform risk models.
    public let authenticityScore: Int?
    public let socialScore: Int?
    public let talkativenessScore: Int?
    public let photographyScore: Int?
    public let localFamiliarityScore: Int?

    public init(
        hasIdentityVerified: Bool,
        hasPhoneVerified: Bool,
        hasFaceVerified: Bool,
        hasEmergencyContact: Bool,
        authenticityScore: Int? = nil,
        socialScore: Int? = nil,
        talkativenessScore: Int? = nil,
        photographyScore: Int? = nil,
        localFamiliarityScore: Int? = nil
    ) {
        self.hasIdentityVerified = hasIdentityVerified
        self.hasPhoneVerified = hasPhoneVerified
        self.hasFaceVerified = hasFaceVerified
        self.hasEmergencyContact = hasEmergencyContact
        self.authenticityScore = authenticityScore
        self.socialScore = socialScore
        self.talkativenessScore = talkativenessScore
        self.photographyScore = photographyScore
        self.localFamiliarityScore = localFamiliarityScore
    }

    public var isFullyVerified: Bool {
        hasIdentityVerified && hasPhoneVerified && hasFaceVerified && hasEmergencyContact
    }
}

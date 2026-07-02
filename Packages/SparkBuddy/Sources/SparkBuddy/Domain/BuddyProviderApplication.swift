// Module: SparkBuddy — Companion provider certification application.

import Foundation

public struct BuddyProviderApplicationDraft: Sendable, Equatable {
    public let displayName: String
    public let city: String
    public let serviceCategory: BuddyServiceCategory
    public let bio: String
    public let capabilityTags: [String]

    public init(
        displayName: String,
        city: String,
        serviceCategory: BuddyServiceCategory,
        bio: String,
        capabilityTags: [String]
    ) {
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.serviceCategory = serviceCategory
        self.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        self.capabilityTags = capabilityTags
    }

    public var isValid: Bool {
        !displayName.isEmpty && !city.isEmpty && bio.count >= 10 && !capabilityTags.isEmpty
    }
}

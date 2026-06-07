// Module: SparkProfile — Profile tab domain model (trust + discover entry).

import SparkTrust

/// Aggregated state for the Profile tab; trust is sourced from `SparkTrust`.
public struct ProfileSummary: Sendable, Equatable {
    public let trustProfile: TrustProfile

    public init(trustProfile: TrustProfile) {
        self.trustProfile = trustProfile
    }
}

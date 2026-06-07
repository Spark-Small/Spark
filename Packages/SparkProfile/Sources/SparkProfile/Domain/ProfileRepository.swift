// Module: SparkProfile — Profile tab data boundary.

import SparkTrust

public protocol ProfileRepository: Sendable {
    func fetchTrustProfile() async throws -> TrustProfile
}

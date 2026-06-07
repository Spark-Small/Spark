// Module: SparkTrust — Trust data boundary.

import Foundation

public protocol TrustRepository: Sendable {
    func fetchProfile() async throws -> TrustProfile
    func verifyPhone() async throws -> TrustProfile
    func verifyRealName() async throws -> TrustProfile
    func verifyLiveness() async throws -> TrustProfile
}

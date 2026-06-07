// Module: SparkTrust — Load trust profile.

import Foundation

public struct FetchTrustProfileUseCase: Sendable {
    private let repository: any TrustRepository

    public init(repository: any TrustRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> TrustProfile {
        try await repository.fetchProfile()
    }
}

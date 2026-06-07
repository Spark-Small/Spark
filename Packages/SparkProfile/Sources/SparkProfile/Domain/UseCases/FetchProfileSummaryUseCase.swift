// Module: SparkProfile — Loads profile tab summary from profile repository.

import SparkTrust

struct FetchProfileSummaryUseCase: Sendable {
    private let repository: any ProfileRepository

    init(repository: any ProfileRepository) {
        self.repository = repository
    }

    init(trustRepository: any TrustRepository) {
        self.repository = TrustBackedProfileRepository(trustRepository: trustRepository)
    }

    func callAsFunction() async throws -> ProfileSummary {
        let profile = try await repository.fetchTrustProfile()
        return ProfileSummary(trustProfile: profile)
    }
}

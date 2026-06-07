// Module: SparkProfile — Live profile data via SparkTrust.

import SparkTrust

struct TrustBackedProfileRepository: ProfileRepository {
    private let trustRepository: any TrustRepository

    init(trustRepository: any TrustRepository) {
        self.trustRepository = trustRepository
    }

    func fetchTrustProfile() async throws -> TrustProfile {
        try await FetchTrustProfileUseCase(repository: trustRepository)()
    }
}

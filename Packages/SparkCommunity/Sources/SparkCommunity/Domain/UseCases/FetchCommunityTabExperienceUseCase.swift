// Module: SparkCommunity — Tab feed bootstrap.

import Foundation

public struct FetchCommunityTabExperienceUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> CommunityTabExperience {
        try await repository.fetchTabExperience()
    }
}

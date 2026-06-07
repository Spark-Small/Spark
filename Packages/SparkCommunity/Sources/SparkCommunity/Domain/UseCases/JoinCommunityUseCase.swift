// Module: SparkCommunity — Join a community from detail header.

import Foundation

public struct JoinCommunityUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    /// - Parameter communityID: Community identifier.
    /// - Returns: Updated community detail with `isJoined == true`.
    public func callAsFunction(communityID: String) async throws -> CommunityDetail {
        try await repository.joinCommunity(id: communityID)
    }
}

// Module: SparkProfile — Live user context API.

import Foundation
import SparkNetworking

public struct LiveUserContextRepository: UserContextRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchContext(userID: String) async throws -> UserContext {
        let path = "v1/users/\(userID)/context"
        let dto: UserContextResponseDTO = try await apiClient.get(path)
        return UserContextDTOMapper.context(from: dto.context)
    }
}

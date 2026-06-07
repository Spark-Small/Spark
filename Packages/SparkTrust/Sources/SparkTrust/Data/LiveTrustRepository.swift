// Module: SparkTrust — Network trust repository.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveTrustRepository: TrustRepository, Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchProfile() async throws -> TrustProfile {
        let dto: TrustProfileResponseDTO = try await apiClient.get(TrustAPIPath.profile)
        return TrustDTOMapper.profile(from: dto)
    }

    public func verifyPhone() async throws -> TrustProfile {
        try await postVerification(path: TrustAPIPath.phone)
    }

    public func verifyRealName() async throws -> TrustProfile {
        try await postVerification(path: TrustAPIPath.realName)
    }

    public func verifyLiveness() async throws -> TrustProfile {
        try await postVerification(path: TrustAPIPath.liveness)
    }

    private func postVerification(path: String) async throws -> TrustProfile {
        let dto: TrustProfileResponseDTO = try await apiClient.post(path, body: Data("{}".utf8))
        return TrustDTOMapper.profile(from: dto)
    }
}

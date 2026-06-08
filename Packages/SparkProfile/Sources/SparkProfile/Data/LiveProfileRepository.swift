// Module: SparkProfile — Network profile repository.

import Foundation
import os
import SparkCore
import SparkNetworking

public struct LiveProfileRepository: ProfileRepository, Sendable {
    private let apiClient: APIClient
    private let logger = Logger(subsystem: SparkLog.subsystem, category: "Profile")

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func prepareAvatarUpload(contentType: String) async throws -> AvatarUploadPrepared {
        try await request("prepareAvatarUpload") {
            let body = try JSONEncoder().encode(AvatarUploadURLRequestDTO(contentType: contentType))
            let dto: AvatarUploadURLResponseDTO = try await apiClient.post(
                ProfileAPIPath.avatarUploadURL,
                body: body,
                as: AvatarUploadURLResponseDTO.self
            )
            guard let avatarURL = URL(string: dto.avatarURL) else {
                throw ProfileError.underlying(.unknown(message: "Invalid avatar_url"))
            }
            let uploadURL = dto.uploadURL.flatMap(URL.init(string:))
            return AvatarUploadPrepared(uploadURL: uploadURL, avatarURL: avatarURL)
        }
    }

    private func request<T>(_ operation: String, _ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw logAndMap(operation, error)
        }
    }

    private func logAndMap(_ operation: String, _ error: Error) -> ProfileError {
        logger.error("Profile \(operation) failed: \(String(describing: error), privacy: .public)")
        if let profileError = error as? ProfileError {
            return profileError
        }
        if let appError = error as? AppError {
            return .underlying(appError)
        }
        return .underlying(.unknown(message: error.localizedDescription))
    }
}

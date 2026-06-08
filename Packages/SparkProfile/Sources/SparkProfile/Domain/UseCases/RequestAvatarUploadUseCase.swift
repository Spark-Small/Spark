// Module: SparkProfile — Staging avatar upload URL.

import Foundation

public struct RequestAvatarUploadUseCase: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction(contentType: String) async throws -> AvatarUploadPrepared {
        try await repository.prepareAvatarUpload(contentType: contentType)
    }
}

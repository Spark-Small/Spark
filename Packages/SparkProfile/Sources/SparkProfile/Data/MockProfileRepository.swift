// Module: SparkProfile — Preview / mock profile repository.

import Foundation

public struct MockProfileRepository: ProfileRepository, Sendable {
    public init() {}

    public func prepareAvatarUpload(contentType: String) async throws -> AvatarUploadPrepared {
        _ = contentType
        let avatarURL = URL(string: "https://picsum.photos/seed/mock-avatar/256/256")!
        return AvatarUploadPrepared(uploadURL: nil, avatarURL: avatarURL)
    }
}

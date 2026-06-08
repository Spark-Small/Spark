// Module: SparkProfile — Avatar presign response.

import Foundation

/// Result of `POST /v1/users/avatar/upload-url`.
public struct AvatarUploadPrepared: Sendable, Equatable {
    /// When non-nil, client must `PUT` JPEG bytes before using `avatarURL`.
    public let uploadURL: URL?
    public let avatarURL: URL

    public init(uploadURL: URL?, avatarURL: URL) {
        self.uploadURL = uploadURL
        self.avatarURL = avatarURL
    }
}

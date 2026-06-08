// Module: SparkProfile — Profile data boundary.

import Foundation

public protocol ProfileRepository: Sendable {
    /// Presign avatar upload (`POST /v1/users/avatar/upload-url`).
    func prepareAvatarUpload(contentType: String) async throws -> AvatarUploadPrepared
}

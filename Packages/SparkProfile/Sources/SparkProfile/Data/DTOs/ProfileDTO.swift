// Module: SparkProfile — Wire types for profile endpoints.

import Foundation

struct AvatarUploadURLResponseDTO: Decodable, Sendable {
    let uploadURL: String?
    let avatarURL: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case avatarURL = "avatar_url"
        case expiresAt = "expires_at"
    }
}

struct AvatarUploadURLRequestDTO: Encodable, Sendable {
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
    }
}

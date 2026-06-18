// Module: SparkAuth — Auth API response payloads.

import Foundation

struct AuthResponseDTO: Decodable, Sendable, Equatable {
    let accessToken: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case userId = "user_id"
    }
}

struct EmailSignInRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
}

struct PasswordResetRequestDTO: Encodable, Sendable {
    let email: String
}

struct AppleSignInRequestDTO: Encodable, Sendable {
    let identityToken: String
    let authorizationCode: String?

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
    }
}

struct PhoneOTPRequestDTO: Encodable, Sendable {
    let phone: String
}

struct PhoneSignInRequestDTO: Encodable, Sendable {
    let phone: String
    let code: String
}

struct ThirdPartySignInRequestDTO: Encodable, Sendable {
    let code: String
}

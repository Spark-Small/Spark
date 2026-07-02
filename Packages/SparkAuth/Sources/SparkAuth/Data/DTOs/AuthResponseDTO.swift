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

struct EmailSignUpRequestDTO: Encodable, Sendable {
    let email: String
    let password: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case displayName = "display_name"
    }
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

struct PhoneOTPVerifyRequestDTO: Encodable, Sendable {
    let phone: String
    let code: String
}

struct PhonePasswordResetRequestDTO: Encodable, Sendable {
    let phone: String
    let code: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case phone
        case code
        case newPassword = "new_password"
    }
}

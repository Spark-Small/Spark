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

struct AppleSignInRequestDTO: Encodable, Sendable {
    let identityToken: String
    let authorizationCode: String?

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
    }
}

struct WeChatSignInRequestDTO: Encodable, Sendable {
    let code: String
}

struct PhoneOneTapSignInRequestDTO: Encodable, Sendable {
    let provider: String
    let token: String
}

struct PhoneOtpSendRequestDTO: Encodable, Sendable {
    let phone: String
}

struct PhoneOtpSendResponseDTO: Decodable, Sendable, Equatable {
    let ok: Bool
}

struct PhoneOtpVerifyRequestDTO: Encodable, Sendable {
    let phone: String
    let code: String
}

struct AlipaySignInRequestDTO: Encodable, Sendable {
    let authCode: String

    enum CodingKeys: String, CodingKey {
        case authCode = "auth_code"
    }
}

struct AlipayPrepareResponseDTO: Decodable, Sendable {
    let authInfo: String

    enum CodingKeys: String, CodingKey {
        case authInfo = "auth_info"
    }
}

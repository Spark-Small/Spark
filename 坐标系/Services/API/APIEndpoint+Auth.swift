//
//  APIEndpoint+Auth.swift
//  坐标系
//

import CoordinateNetworking
import Foundation

struct RemoteAuthTokens: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct RemoteAuthUser: Codable, Sendable {
    let id: UUID
    let phoneMasked: String?
    let profileCompleted: Bool?
    let discoverable: Bool?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case phoneMasked = "phone_masked"
        case profileCompleted = "profile_completed"
        case discoverable
        case status
    }
}

struct RemoteSMSLoginData: Codable, Sendable {
    let tokens: RemoteAuthTokens
    let user: RemoteAuthUser
    let created: Bool?
}

struct RemoteSMSSendData: Codable, Sendable {
    let phoneMasked: String?
    let expiresIn: Int?
    let devCode: String?

    enum CodingKeys: String, CodingKey {
        case phoneMasked = "phone_masked"
        case expiresIn = "expires_in"
        case devCode = "dev_code"
    }
}

extension APIEndpoint where Response == RemoteSMSSendData {
    static func smsSend(phone: String) throws -> APIEndpoint<RemoteSMSSendData> {
        let body = try APIJSONCoding.makeEncoder().encode(["phone": phone])
        return APIEndpoint(path: "auth/sms/send", method: .post, body: body)
    }
}

extension APIEndpoint where Response == RemoteSMSLoginData {
    static func smsLogin(
        phone: String,
        code: String,
        deviceID: String,
        platform: String
    ) throws -> APIEndpoint<RemoteSMSLoginData> {
        let body = try APIJSONCoding.makeEncoder().encode([
            "phone": phone,
            "code": code,
            "device_id": deviceID,
            "platform": platform,
        ])
        return APIEndpoint(path: "auth/sms/login", method: .post, body: body)
    }
}

extension APIEndpoint where Response == RemoteAuthTokens {
    static func tokenRefresh(refreshToken: String) throws -> APIEndpoint<RemoteAuthTokens> {
        let body = try APIJSONCoding.makeEncoder().encode(["refresh_token": refreshToken])
        return APIEndpoint(path: "auth/token/refresh", method: .post, body: body)
    }
}

enum RemoteAuthAPI {
    static func sendSMS(phone: String, client: APIClient = .shared) async throws -> RemoteSMSSendData {
        try await client.send(try .smsSend(phone: phone))
    }

    static func loginSMS(
        phone: String,
        code: String,
        client: APIClient = .shared
    ) async throws -> RemoteSMSLoginData {
        let deviceID = LocalUserIdentity.current.uuidString
        let data = try await client.send(
            try .smsLogin(phone: phone, code: code, deviceID: deviceID, platform: "ios")
        )
        AuthTokenStore.save(
            access: data.tokens.accessToken,
            refresh: data.tokens.refreshToken,
            expiresIn: data.tokens.expiresIn
        )
        return data
    }

    static func refreshTokens(
        refreshToken: String,
        client: APIClient
    ) async throws -> RemoteAuthTokens {
        try await client.send(try .tokenRefresh(refreshToken: refreshToken))
    }
}

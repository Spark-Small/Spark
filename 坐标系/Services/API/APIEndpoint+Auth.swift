//
//  APIEndpoint+Auth.swift
//  坐标系
//
//  Auth 端点：短信 / Apple / 微信换票 + refresh。
//  后端约定：POST auth/sms/send|login · auth/apple/login · auth/wechat/login · auth/token/refresh
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

/// 短信 / Apple / 微信登录统一响应。
struct RemoteAuthLoginData: Codable, Sendable {
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

extension APIEndpoint where Response == RemoteAuthLoginData {
    static func smsLogin(
        phone: String,
        code: String,
        deviceID: String,
        platform: String
    ) throws -> APIEndpoint<RemoteAuthLoginData> {
        let body = try APIJSONCoding.makeEncoder().encode([
            "phone": phone,
            "code": code,
            "device_id": deviceID,
            "platform": platform,
        ])
        return APIEndpoint(path: "auth/sms/login", method: .post, body: body)
    }

    /// Sign in with Apple：服务端校验 `identity_token` 后发 JWT。
    static func appleLogin(
        identityToken: String,
        authorizationCode: String?,
        deviceID: String,
        platform: String,
        fullName: String?,
        email: String?
    ) throws -> APIEndpoint<RemoteAuthLoginData> {
        var payload: [String: String] = [
            "identity_token": identityToken,
            "device_id": deviceID,
            "platform": platform,
        ]
        if let authorizationCode, !authorizationCode.isEmpty {
            payload["authorization_code"] = authorizationCode
        }
        if let fullName, !fullName.isEmpty {
            payload["full_name"] = fullName
        }
        if let email, !email.isEmpty {
            payload["email"] = email
        }
        let body = try APIJSONCoding.makeEncoder().encode(payload)
        return APIEndpoint(path: "auth/apple/login", method: .post, body: body)
    }

    /// 微信 OAuth：用 `code` 换服务端会话。
    static func wechatLogin(
        code: String,
        deviceID: String,
        platform: String
    ) throws -> APIEndpoint<RemoteAuthLoginData> {
        let body = try APIJSONCoding.makeEncoder().encode([
            "code": code,
            "device_id": deviceID,
            "platform": platform,
        ])
        return APIEndpoint(path: "auth/wechat/login", method: .post, body: body)
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
    ) async throws -> RemoteAuthLoginData {
        let data = try await verifySMSLogin(phone: phone, code: code, client: client)
        applyLoginData(data)
        return data
    }

    /// 仅校验短信验证码（走 `auth/sms/login`），**不**写入 JWT / 切换本机用户。
    /// 用于已登录用户绑定手机；专用 bind API 未接前的诚实校验路径。
    static func verifySMSLogin(
        phone: String,
        code: String,
        client: APIClient = .shared
    ) async throws -> RemoteAuthLoginData {
        let deviceID = LocalUserIdentity.current.uuidString
        return try await client.send(
            try .smsLogin(phone: phone, code: code, deviceID: deviceID, platform: "ios")
        )
    }

    static func loginApple(
        identityToken: String,
        authorizationCode: String?,
        fullName: String?,
        email: String?,
        client: APIClient = .shared
    ) async throws -> RemoteAuthLoginData {
        let deviceID = LocalUserIdentity.current.uuidString
        let data = try await client.send(
            try .appleLogin(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                deviceID: deviceID,
                platform: "ios",
                fullName: fullName,
                email: email
            )
        )
        applyLoginData(data)
        return data
    }

    static func loginWeChat(
        code: String,
        client: APIClient = .shared
    ) async throws -> RemoteAuthLoginData {
        let deviceID = LocalUserIdentity.current.uuidString
        let data = try await client.send(
            try .wechatLogin(code: code, deviceID: deviceID, platform: "ios")
        )
        applyLoginData(data)
        return data
    }

    static func refreshTokens(
        refreshToken: String,
        client: APIClient
    ) async throws -> RemoteAuthTokens {
        try await client.send(try .tokenRefresh(refreshToken: refreshToken))
    }

    /// 写入 JWT 并对齐本机 `LocalUserIdentity` 为服务端用户 ID。
    static func applyLoginData(_ data: RemoteAuthLoginData) {
        AuthTokenStore.save(
            access: data.tokens.accessToken,
            refresh: data.tokens.refreshToken,
            expiresIn: data.tokens.expiresIn
        )
        LocalUserIdentity.adopt(data.user.id)
    }
}

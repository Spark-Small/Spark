//
//  WeChatSignInService.swift
//  坐标系
//
//  微信登录接入位：API 与 AppleSignInService 对齐。
//  接入：注册 Universal Link → `isSDKConfigured = true` → 实现 `sendAuthRequest`。
//

import CoordinateFeatureFlags
import Foundation

struct WeChatSignInResult: Sendable {
    /// 微信 openid（或演示占位）。
    let openID: String
    let unionID: String?
    let nickname: String?
    /// 服务端换票用的 OAuth `code`；演示路径可为 nil。
    let authorizationCode: String?
}

enum WeChatSignInError: LocalizedError {
    case canceled
    case unavailable
    case notInstalled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .canceled:
            nil
        case .unavailable:
            "微信登录即将开放，请使用 Apple 或手机号登录。"
        case .notInstalled:
            "未安装微信，请使用 Apple 或手机号登录。"
        case .failed(let message):
            message
        }
    }
}

@MainActor
enum WeChatSignInService {
    /// 接入微信 OpenSDK 并完成 `WXApi.registerApp` 后改为 `true`。
    static var isSDKConfigured = false

    /// 是否在 UI 展示微信登录入口。
    /// Release：仅 SDK 已配置时展示；DEBUG 本地演示模式（`!useRemoteAuth`）可展示假登录。
    static var isAvailable: Bool {
        if isSDKConfigured { return true }
        #if DEBUG
        return !FeatureFlags.useRemoteAuth
        #else
        return false
        #endif
    }

    /// 发起微信授权。未配置 SDK 时：DEBUG 且非远程 Auth 返回演示凭证；否则 `unavailable`。
    static func signIn() async throws -> WeChatSignInResult {
        if isSDKConfigured {
            return try await sendAuthRequest()
        }

        #if DEBUG
        guard !FeatureFlags.useRemoteAuth else {
            throw WeChatSignInError.unavailable
        }
        return WeChatSignInResult(
            openID: "demo.wechat",
            unionID: nil,
            nickname: "demo.wechat",
            authorizationCode: nil
        )
        #else
        throw WeChatSignInError.unavailable
        #endif
    }

    // MARK: - SDK 接入点

    /// 接入后在此调用 `SendAuthReq` / 处理 `onResp`，并 resume continuation。
    private static func sendAuthRequest() async throws -> WeChatSignInResult {
        // TODO: WXApi.isWXAppInstalled() → notInstalled
        // TODO: SendAuthReq(scope: "snsapi_userinfo", state: ...)
        // TODO: 将 onResp.code 填入 authorizationCode，供 RemoteAuthAPI.loginWeChat
        throw WeChatSignInError.unavailable
    }
}

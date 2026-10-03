//
//  AuthAnalytics.swift
//  坐标系
//
//  登录漏斗埋点。事件名稳定，后续只换 Analytics.sink。
//

import Foundation

enum AuthAnalytics {
    enum Source: String {
        case login
        case createAccount = "create_account"
    }

    enum Method: String {
        case apple
        case wechat
        case phone
    }

    // MARK: - Sheet / 入口

    static func sheetPresented(source: Source = .login) {
        Analytics.track("login_sheet_present", ["source": source.rawValue])
    }

    static func methodTapped(method: Method, source: Source = .login) {
        Analytics.track("login_method_tap", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    // MARK: - 协议闸

    static func legalPrompt(method: Method, source: Source = .login) {
        Analytics.track("login_legal_prompt", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    static func legalAccepted(method: Method, source: Source = .login) {
        Analytics.track("login_legal_accept", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    static func legalRejected(method: Method, source: Source = .login) {
        Analytics.track("login_legal_reject", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    // MARK: - OAuth 链路（Apple / 微信）

    static func oauthStarted(method: Method, source: Source = .login) {
        Analytics.track("login_oauth_start", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    static func oauthCanceled(method: Method, source: Source = .login) {
        Analytics.track("login_oauth_cancel", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    static func oauthSucceeded(
        method: Method,
        source: Source = .login,
        userIDPrefix: String? = nil
    ) {
        var params = [
            "source": source.rawValue,
            "method": method.rawValue
        ]
        if let userIDPrefix, !userIDPrefix.isEmpty {
            params["user_id_prefix"] = userIDPrefix
        }
        Analytics.track("login_oauth_success", params)
    }

    static func oauthFailed(method: Method, source: Source = .login, error: String) {
        Analytics.track("login_oauth_fail", [
            "source": source.rawValue,
            "method": method.rawValue,
            "error": String(error.prefix(120))
        ])
    }

    static func oauthUnavailable(method: Method, source: Source = .login) {
        Analytics.track("login_oauth_unavailable", [
            "source": source.rawValue,
            "method": method.rawValue
        ])
    }

    // MARK: - 短信

    static func smsSendStarted(source: Source = .login) {
        Analytics.track("login_sms_send_start", ["source": source.rawValue])
    }

    static func smsSendSucceeded(source: Source = .login) {
        Analytics.track("login_sms_send_success", ["source": source.rawValue])
    }

    static func smsSendFailed(source: Source = .login, error: String) {
        Analytics.track("login_sms_send_fail", [
            "source": source.rawValue,
            "error": String(error.prefix(120))
        ])
    }

    static func smsLoginStarted(source: Source = .login) {
        Analytics.track("login_sms_login_start", ["source": source.rawValue])
    }

    static func smsLoginSucceeded(source: Source = .login, userIDPrefix: String? = nil) {
        var params = ["source": source.rawValue]
        if let userIDPrefix, !userIDPrefix.isEmpty {
            params["user_id_prefix"] = userIDPrefix
        }
        Analytics.track("login_sms_login_success", params)
    }

    static func smsLoginFailed(source: Source = .login, error: String) {
        Analytics.track("login_sms_login_fail", [
            "source": source.rawValue,
            "error": String(error.prefix(120))
        ])
    }

    // MARK: - Session

    static func sessionInvalidated(reason: String) {
        Analytics.track("login_session_invalidated", [
            "reason": String(reason.prefix(80))
        ])
    }
}

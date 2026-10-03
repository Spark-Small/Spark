//
//  AuthSMSUseCases.swift
//  坐标系
//

import Foundation

/// 发送远程短信验证码。
struct SendRemoteSMSCodeUseCase: Sendable {
    func execute(
        phone: String,
        source: AuthAnalytics.Source
    ) async -> AuthSendCodeResult {
        let trimmed = AuthCredentialFormat.sanitizedPhone(phone)
        guard AuthCredentialFormat.isValidPhone(trimmed) else {
            return .failure("请输入 11 位手机号")
        }
        AuthAnalytics.smsSendStarted(source: source)
        do {
            _ = try await RemoteAuthAPI.sendSMS(phone: trimmed)
            AuthAnalytics.smsSendSucceeded(source: source)
            return .success
        } catch {
            let message = error.localizedDescription
            AuthAnalytics.smsSendFailed(source: source, error: message)
            return .failure(message)
        }
    }
}

/// 远程短信换票登录。
struct SignInWithRemoteSMSUseCase: Sendable {
    func execute(
        phone: String,
        code: String,
        source: AuthAnalytics.Source
    ) async -> AuthSignInResult {
        let trimmed = AuthCredentialFormat.sanitizedPhone(phone)
        guard AuthCredentialFormat.isValidPhone(trimmed) else {
            return .failure(.message("请输入 11 位手机号"))
        }
        AuthAnalytics.smsLoginStarted(source: source)
        do {
            let data = try await RemoteAuthAPI.loginSMS(phone: trimmed, code: code)
            let success = AuthSignInSuccess(
                snapshot: AuthSessionSnapshot(
                    isSignedIn: true,
                    provider: .phone,
                    phoneNumber: trimmed
                ),
                userIDPrefix: String(data.user.id.uuidString.prefix(8))
            )
            AuthAnalytics.smsLoginSucceeded(source: source, userIDPrefix: success.userIDPrefix)
            return .success(success)
        } catch {
            let message = error.localizedDescription
            AuthAnalytics.smsLoginFailed(source: source, error: message)
            return .failure(.message(message))
        }
    }
}

/// DEBUG 本地演示码登录（不换 JWT）。
struct SignInWithDemoSMSUseCase: Sendable {
    let demoCode: String

    func execute(
        phone: String,
        code: String,
        source: AuthAnalytics.Source
    ) -> AuthSignInResult {
        #if DEBUG
        let trimmed = AuthCredentialFormat.sanitizedPhone(phone)
        guard AuthCredentialFormat.isValidPhone(trimmed), code == demoCode else {
            return .failure(.message("手机号或验证码不正确"))
        }
        let success = AuthSignInSuccess(
            snapshot: AuthSessionSnapshot(
                isSignedIn: true,
                provider: .phone,
                phoneNumber: trimmed
            ),
            userIDPrefix: nil
        )
        AuthAnalytics.smsLoginSucceeded(source: source)
        return .success(success)
        #else
        return .failure(.message("请使用短信验证码登录。"))
        #endif
    }
}

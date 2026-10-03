//
//  AuthOAuthUseCases.swift
//  坐标系
//

import CoordinateFeatureFlags
import Foundation

/// Sign in with Apple → 可选远程换票。
@MainActor
struct SignInWithAppleUseCase {
    func execute(source: AuthAnalytics.Source) async -> AuthSignInResult {
        AuthAnalytics.oauthStarted(method: .apple, source: source)
        do {
            let result = try await AppleSignInService.signIn()
            return await finish(result: result, source: source)
        } catch AppleSignInError.canceled {
            AuthAnalytics.oauthCanceled(method: .apple, source: source)
            return .failure(.canceled)
        } catch {
            let message = error.localizedDescription
            AuthAnalytics.oauthFailed(method: .apple, source: source, error: message)
            return .failure(.message(message))
        }
    }

    private func finish(
        result: AppleSignInResult,
        source: AuthAnalytics.Source
    ) async -> AuthSignInResult {
        AuthTokenStore.appleUserID = result.userID

        if FeatureFlags.useRemoteAuth {
            guard let tokenData = result.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  !identityToken.isEmpty
            else {
                let message = "无法完成 Apple 登录"
                AuthAnalytics.oauthFailed(method: .apple, source: source, error: message)
                return .failure(.message(message))
            }
            let fullName = [result.fullName?.givenName, result.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let authorizationCode = result.authorizationCode.flatMap {
                String(data: $0, encoding: .utf8)
            }
            do {
                let data = try await RemoteAuthAPI.loginApple(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: result.email
                )
                let success = AuthSignInSuccess(
                    snapshot: AuthSessionSnapshot(
                        isSignedIn: true,
                        provider: .apple,
                        phoneNumber: ""
                    ),
                    userIDPrefix: String(data.user.id.uuidString.prefix(8))
                )
                AuthAnalytics.oauthSucceeded(
                    method: .apple,
                    source: source,
                    userIDPrefix: success.userIDPrefix
                )
                return .success(success)
            } catch {
                let message = error.localizedDescription
                AuthAnalytics.oauthFailed(method: .apple, source: source, error: message)
                return .failure(.message(message))
            }
        }

        let success = AuthSignInSuccess(
            snapshot: AuthSessionSnapshot(
                isSignedIn: true,
                provider: .apple,
                phoneNumber: ""
            ),
            userIDPrefix: String(result.userID.prefix(8))
        )
        AuthAnalytics.oauthSucceeded(
            method: .apple,
            source: source,
            userIDPrefix: success.userIDPrefix
        )
        return .success(success)
    }
}

/// 微信授权 → 可选远程换票。
@MainActor
struct SignInWithWeChatUseCase {
    func execute(source: AuthAnalytics.Source) async -> AuthSignInResult {
        AuthAnalytics.oauthStarted(method: .wechat, source: source)
        do {
            let result = try await WeChatSignInService.signIn()
            if FeatureFlags.useRemoteAuth {
                guard let code = result.authorizationCode, !code.isEmpty else {
                    let message = "微信授权码无效，请重试。"
                    AuthAnalytics.oauthFailed(method: .wechat, source: source, error: message)
                    return .failure(.message(message))
                }
                let data = try await RemoteAuthAPI.loginWeChat(code: code)
                let success = AuthSignInSuccess(
                    snapshot: AuthSessionSnapshot(
                        isSignedIn: true,
                        provider: .wechat,
                        phoneNumber: ""
                    ),
                    userIDPrefix: String(data.user.id.uuidString.prefix(8))
                )
                AuthAnalytics.oauthSucceeded(
                    method: .wechat,
                    source: source,
                    userIDPrefix: success.userIDPrefix
                )
                return .success(success)
            }

            let success = AuthSignInSuccess(
                snapshot: AuthSessionSnapshot(
                    isSignedIn: true,
                    provider: .wechat,
                    phoneNumber: ""
                ),
                userIDPrefix: String(result.openID.prefix(8))
            )
            AuthAnalytics.oauthSucceeded(
                method: .wechat,
                source: source,
                userIDPrefix: success.userIDPrefix
            )
            return .success(success)
        } catch let error as WeChatSignInError {
            switch error {
            case .canceled:
                AuthAnalytics.oauthCanceled(method: .wechat, source: source)
                return .failure(.canceled)
            case .unavailable, .notInstalled:
                AuthAnalytics.oauthUnavailable(method: .wechat, source: source)
                return .failure(.message(
                    error.errorDescription ?? "微信登录即将开放，请使用 Apple 或手机号登录。"
                ))
            case .failed(let message):
                AuthAnalytics.oauthFailed(method: .wechat, source: source, error: message)
                return .failure(.message(message))
            }
        } catch {
            let message = error.localizedDescription
            AuthAnalytics.oauthFailed(method: .wechat, source: source, error: message)
            return .failure(.message(message))
        }
    }
}

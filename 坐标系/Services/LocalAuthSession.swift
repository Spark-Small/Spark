//
//  LocalAuthSession.swift
//  坐标系
//
//  可观察会话状态门面；登录业务在独立 UseCase 中。
//

import Foundation
import Observation
import CoordinateFeatureFlags

/// 本机账号登录渠道。
enum LocalAccountProvider: String, Codable, Sendable {
    case phone
    case apple
    case wechat
    /// 旧访客数据解码用；加载时会被规范为未登录。
    case guest

    var displayName: String {
        switch self {
        case .guest: "未登录"
        case .phone: "手机号"
        case .apple: "Apple"
        case .wechat: "微信"
        }
    }
}

@MainActor
@Observable
final class LocalAuthSession {
    static let demoCode = "123456"

    private let store: any AuthSessionPersisting
    private let sendSMSCode = SendRemoteSMSCodeUseCase()
    private let signInRemoteSMS = SignInWithRemoteSMSUseCase()
    private let signInDemoSMS = SignInWithDemoSMSUseCase(demoCode: demoCode)
    private let signInApple = SignInWithAppleUseCase()
    private let signInWeChat = SignInWithWeChatUseCase()
    private let reconcile = ReconcileAuthSessionUseCase()
    private let invalidateRemote = InvalidateRemoteAuthSessionUseCase()

    private(set) var isSignedIn: Bool
    private(set) var phoneNumber: String
    private(set) var provider: LocalAccountProvider

    var accountStatusLabel: String {
        isSignedIn ? "已登录" : "未登录"
    }

    var loginMethodLabel: String {
        guard isSignedIn else { return "未登录" }
        return provider.displayName
    }

    var maskedPhoneLabel: String {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSignedIn, provider == .phone, trimmed.count >= 7 else { return "—" }
        return "\(trimmed.prefix(3))****\(trimmed.suffix(4))"
    }

    init(store: any AuthSessionPersisting = KeychainAuthSessionStore()) {
        self.store = store
        LocalUserIdentity.ensure()
        let snapshot = store.load()
        isSignedIn = snapshot.isSignedIn
        phoneNumber = snapshot.phoneNumber
        provider = snapshot.provider
        if !snapshot.isSignedIn {
            store.clear()
            AuthTokenStore.clear()
        }
    }

    func reconcilePersistedSession() {
        if reconcile.executeIfNeeded(isSignedIn: isSignedIn) {
            signOut()
        }
    }

    @discardableResult
    func signIn(
        phone: String,
        code: String,
        source: AuthAnalytics.Source = .login
    ) -> Bool {
        switch signInDemoSMS.execute(phone: phone, code: code, source: source) {
        case .success(let success):
            applySuccess(success)
            return true
        case .failure:
            return false
        }
    }

    @discardableResult
    func signInRemote(
        phone: String,
        code: String,
        source: AuthAnalytics.Source = .login
    ) async -> String? {
        applySignInResult(
            await signInRemoteSMS.execute(phone: phone, code: code, source: source)
        )
    }

    @discardableResult
    func sendRemoteSMSCode(
        phone: String,
        source: AuthAnalytics.Source = .login
    ) async -> String? {
        switch await sendSMSCode.execute(phone: phone, source: source) {
        case .success: nil
        case .failure(let message): message
        }
    }

    @discardableResult
    func signInWithApple(source: AuthAnalytics.Source = .login) async -> String? {
        applySignInResult(await signInApple.execute(source: source))
    }

    @discardableResult
    func signInWithWeChat(source: AuthAnalytics.Source = .login) async -> String? {
        applySignInResult(await signInWeChat.execute(source: source))
    }

    func signOut() {
        applySnapshot(.signedOut)
        AuthTokenStore.clear()
    }

    func resetStoredSession() {
        applySnapshot(.signedOut)
        AuthTokenStore.clearAllIncludingAppleUser()
        store.clear()
        LocalUserIdentity.regenerate()
    }

    func invalidateRemoteSession() {
        invalidateRemote.execute()
        signOut()
    }

    // MARK: - Private

    @discardableResult
    private func applySignInResult(_ result: AuthSignInResult) -> String? {
        switch result {
        case .success(let success):
            applySuccess(success)
            return nil
        case .failure(.canceled):
            return nil
        case .failure(.message(let message)):
            return message
        }
    }

    private func applySuccess(_ success: AuthSignInSuccess) {
        LocalUserIdentity.ensure()
        applySnapshot(success.snapshot)
    }

    private func applySnapshot(_ snapshot: AuthSessionSnapshot) {
        isSignedIn = snapshot.isSignedIn
        provider = snapshot.provider
        phoneNumber = snapshot.phoneNumber
        if snapshot.isSignedIn {
            store.save(snapshot)
        } else {
            store.clear()
        }
    }
}

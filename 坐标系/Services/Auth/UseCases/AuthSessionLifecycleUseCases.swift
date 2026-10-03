//
//  AuthSessionLifecycleUseCases.swift
//  坐标系
//

import CoordinateFeatureFlags
import Foundation

/// 冷启动核对：远程 Auth 下无可用 token 则应退登。
struct ReconcileAuthSessionUseCase: Sendable {
    func shouldInvalidate(
        isSignedIn: Bool,
        hasUsableRemoteSession: Bool,
        useRemoteAuth: Bool
    ) -> Bool {
        guard isSignedIn, useRemoteAuth else { return false }
        return !hasUsableRemoteSession
    }

    func executeIfNeeded(
        isSignedIn: Bool,
        hasUsableRemoteSession: Bool = AuthTokenStore.hasUsableRemoteSession,
        useRemoteAuth: Bool = FeatureFlags.useRemoteAuth
    ) -> Bool {
        let invalidate = shouldInvalidate(
            isSignedIn: isSignedIn,
            hasUsableRemoteSession: hasUsableRemoteSession,
            useRemoteAuth: useRemoteAuth
        )
        if invalidate {
            AuthAnalytics.sessionInvalidated(reason: "missing_tokens")
        }
        return invalidate
    }
}

/// 远程会话失效（refresh 失败等）。
struct InvalidateRemoteAuthSessionUseCase: Sendable {
    func execute() {
        AuthAnalytics.sessionInvalidated(reason: "token_refresh_failed")
    }
}

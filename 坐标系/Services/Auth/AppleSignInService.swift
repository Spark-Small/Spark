//
//  AppleSignInService.swift
//  坐标系
//
//  Sign in with Apple（AuthenticationServices · Apple HIG / 审核 4.8）。
//

import AuthenticationServices
import Foundation
import UIKit

struct AppleSignInResult: Sendable {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: Data?
    let authorizationCode: Data?
}

enum AppleSignInError: LocalizedError {
    case canceled
    case failed(String)
    case missingCredential

    var errorDescription: String? {
        switch self {
        case .canceled:
            nil
        case .failed(let message):
            message
        case .missingCredential:
            "无法完成 Apple 登录"
        }
    }
}

@MainActor
enum AppleSignInService {
    static func signIn() async throws -> AppleSignInResult {
        try await AppleSignInController().performRequest()
    }

    /// App 启动后检查已存 Apple 用户凭证是否仍有效。
    /// - Returns: `true` 表示凭证已撤销，调用方应退出登录。
    @discardableResult
    static func refreshCredentialStateIfNeeded() async -> Bool {
        guard let userID = AuthTokenStore.appleUserID, !userID.isEmpty else { return false }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<ASAuthorizationAppleIDProvider.CredentialState, Error>) in
                provider.getCredentialState(forUserID: userID) { state, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: state)
                    }
                }
            }
            switch state {
            case .revoked, .notFound:
                AuthTokenStore.clearAllIncludingAppleUser()
                return true
            case .authorized, .transferred:
                return false
            @unknown default:
                return false
            }
        } catch {
            assertionFailure("Apple credential state failed: \(error)")
            return false
        }
    }
}

// MARK: - Controller

@MainActor
private final class AppleSignInController: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    func performRequest() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let key = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return key
        }
        if let window = scenes.flatMap(\.windows).first {
            return window
        }
        guard let scene = scenes.first else {
            preconditionFailure("Sign in with Apple requires an active UIWindowScene")
        }
        return UIWindow(windowScene: scene)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(.failure(AppleSignInError.missingCredential))
            return
        }
        finish(.success(AppleSignInResult(
            userID: credential.user,
            email: credential.email,
            fullName: credential.fullName,
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode
        )))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let ns = error as NSError
        if ns.domain == ASAuthorizationError.errorDomain,
           ns.code == ASAuthorizationError.canceled.rawValue {
            finish(.failure(AppleSignInError.canceled))
        } else {
            finish(.failure(AppleSignInError.failed(error.localizedDescription)))
        }
    }

    private func finish(_ result: Result<AppleSignInResult, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

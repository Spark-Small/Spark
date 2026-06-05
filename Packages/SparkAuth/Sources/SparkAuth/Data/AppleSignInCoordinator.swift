// Module: SparkAuth — Presents Sign in with Apple (AuthenticationServices).

import AuthenticationServices
import Foundation
import UIKit

public enum AppleSignInCoordinatorError: Error, Sendable {
    case credentialMissing
    case cancelled
}

@MainActor
public final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleSignInCredential, Error>?

    public func signIn() async throws -> AppleSignInCredential {
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

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let token = credential.identityToken else {
            continuation?.resume(throwing: AppleSignInCoordinatorError.credentialMissing)
            continuation = nil
            return
        }
        continuation?.resume(
            returning: AppleSignInCredential(
                identityToken: token,
                authorizationCode: credential.authorizationCode
            )
        )
        continuation = nil
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            continuation?.resume(throwing: AppleSignInCoordinatorError.cancelled)
        } else {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // REASONING: Uses first key window; inject anchor when supporting multi-scene iPad layouts.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.first?.windows.first { $0.isKeyWindow } ?? scenes.first?.windows.first
        return window ?? UIWindow()
    }
}

// Module: SparkAuth — Shared Preview / canvas fixtures for auth screens.

import SparkPersistence
import SwiftUI

#if DEBUG
enum AuthPreviewSupport {
    @MainActor
    static func viewModel() -> AuthViewModel {
        AuthViewModel(
            authService: MockAuthService(
                sessionStore: AuthSessionStore(),
                tokenProvider: KeychainAccessTokenProvider()
            )
        )
    }

    @MainActor
    static func phoneOTPExpandedViewModel() -> AuthViewModel {
        let viewModel = viewModel()
        viewModel.configurePreviewPhoneOTP(phoneNumber: "188 1234 5678", otpSent: true)
        return viewModel
    }

    @MainActor
    static func phoneReadyViewModel() -> AuthViewModel {
        let viewModel = viewModel()
        viewModel.phoneNumber = "188 1234 5678"
        return viewModel
    }

    @MainActor
    static func phoneCooldownViewModel() -> AuthViewModel {
        let viewModel = phoneOTPExpandedViewModel()
        viewModel.configurePreviewOTPCooldown(seconds: 45)
        return viewModel
    }

    @MainActor
    static func signingInViewModel() -> AuthViewModel {
        let viewModel = phoneOTPExpandedViewModel()
        viewModel.configurePreviewSigningIn()
        return viewModel
    }

    @MainActor
    static func failureViewModel() -> AuthViewModel {
        let viewModel = phoneOTPExpandedViewModel()
        viewModel.configurePreviewLoginFailure()
        return viewModel
    }
}
#endif

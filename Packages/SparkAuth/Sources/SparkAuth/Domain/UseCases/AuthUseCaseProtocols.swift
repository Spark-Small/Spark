// Module: SparkAuth — UseCase protocols for ViewModel testability.

import Foundation

public protocol RestoreSessionUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> AuthSession?
}

public protocol SignInWithAppleUseCaseProtocol: Sendable {
    func callAsFunction(_ credential: AppleSignInCredential) async throws -> AuthSession
}

public protocol SignInWithEmailUseCaseProtocol: Sendable {
    func callAsFunction(email: String, password: String) async throws -> AuthSession
}

public protocol SignUpWithEmailUseCaseProtocol: Sendable {
    func callAsFunction(email: String, password: String, displayName: String) async throws -> AuthSession
}

public protocol RequestPasswordResetUseCaseProtocol: Sendable {
    func callAsFunction(email: String) async throws
}

public protocol SignOutUseCaseProtocol: Sendable {
    func callAsFunction() async throws
}

public protocol DeleteAccountUseCaseProtocol: Sendable {
    func callAsFunction() async throws
}

public protocol SendPhoneOTPUseCaseProtocol: Sendable {
    func callAsFunction(phone: String) async throws
}

public protocol SignInWithPhoneOTPUseCaseProtocol: Sendable {
    func callAsFunction(phone: String, code: String) async throws -> AuthSession
}

extension RestoreSessionUseCase: RestoreSessionUseCaseProtocol {}
extension SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {}
extension SignInWithEmailUseCase: SignInWithEmailUseCaseProtocol {}
extension SignUpWithEmailUseCase: SignUpWithEmailUseCaseProtocol {}
extension RequestPasswordResetUseCase: RequestPasswordResetUseCaseProtocol {}
extension SignOutUseCase: SignOutUseCaseProtocol {}
extension DeleteAccountUseCase: DeleteAccountUseCaseProtocol {}
extension SendPhoneOTPUseCase: SendPhoneOTPUseCaseProtocol {}
extension SignInWithPhoneOTPUseCase: SignInWithPhoneOTPUseCaseProtocol {}

public protocol ResetPasswordWithPhoneOTPUseCaseProtocol: Sendable {
    func callAsFunction(phone: String, code: String, newPassword: String) async throws -> AuthSession
}

extension ResetPasswordWithPhoneOTPUseCase: ResetPasswordWithPhoneOTPUseCaseProtocol {}

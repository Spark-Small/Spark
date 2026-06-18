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

public protocol RequestPhoneOTPUseCaseProtocol: Sendable {
    func callAsFunction(phoneNumber: String) async throws
}

public protocol SignInWithPhoneOTPUseCaseProtocol: Sendable {
    func callAsFunction(phoneNumber: String, code: String) async throws -> AuthSession
}

public protocol SignInWithThirdPartyUseCaseProtocol: Sendable {
    func callAsFunction(_ credential: ThirdPartyOAuthCredential) async throws -> AuthSession
}

public protocol ClearLocalSessionUseCaseProtocol: Sendable {
    func callAsFunction() async throws
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

extension RestoreSessionUseCase: RestoreSessionUseCaseProtocol {}
extension SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {}
extension SignInWithEmailUseCase: SignInWithEmailUseCaseProtocol {}
extension RequestPhoneOTPUseCase: RequestPhoneOTPUseCaseProtocol {}
extension SignInWithPhoneOTPUseCase: SignInWithPhoneOTPUseCaseProtocol {}
extension SignInWithThirdPartyUseCase: SignInWithThirdPartyUseCaseProtocol {}
extension ClearLocalSessionUseCase: ClearLocalSessionUseCaseProtocol {}
extension RequestPasswordResetUseCase: RequestPasswordResetUseCaseProtocol {}
extension SignOutUseCase: SignOutUseCaseProtocol {}
extension DeleteAccountUseCase: DeleteAccountUseCaseProtocol {}

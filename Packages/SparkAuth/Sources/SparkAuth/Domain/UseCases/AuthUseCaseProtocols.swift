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

public protocol SignOutUseCaseProtocol: Sendable {
    func callAsFunction() async throws
}

public protocol DeleteAccountUseCaseProtocol: Sendable {
    func callAsFunction() async throws
}

extension RestoreSessionUseCase: RestoreSessionUseCaseProtocol {}
extension SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {}
extension SignInWithEmailUseCase: SignInWithEmailUseCaseProtocol {}
extension SignOutUseCase: SignOutUseCaseProtocol {}
extension DeleteAccountUseCase: DeleteAccountUseCaseProtocol {}

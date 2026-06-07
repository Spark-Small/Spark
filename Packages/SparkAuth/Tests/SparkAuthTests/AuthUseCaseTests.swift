// Module: SparkAuthTests — Auth use case coverage.

import SparkAuth
import SparkPersistence
import Testing

struct AuthUseCaseTests {
    private func makeService() -> MockAuthService {
        let keychain = InMemoryKeychainManager()
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
        service.simulatedDelayNanoseconds = 0
        return service
    }

    @Test func restoreSessionUseCaseReturnsNilWhenEmpty() async throws {
        let useCase = RestoreSessionUseCase(authService: makeService())
        let session = try await useCase()
        #expect(session == nil)
    }

    @Test func signInWithEmailUseCasePersistsSession() async throws {
        let service = makeService()
        let useCase = SignInWithEmailUseCase(authService: service)
        let session = try await useCase(email: "test@spark.app", password: "secret1")
        #expect(session.userID.rawValue == "test")
        let restored = try await RestoreSessionUseCase(authService: service)()
        #expect(restored?.accessToken == session.accessToken)
    }

    @Test func signOutUseCaseClearsSession() async throws {
        let service = makeService()
        _ = try await SignInWithEmailUseCase(authService: service)(email: "a@b.co", password: "secret1")
        try await SignOutUseCase(authService: service)()
        let restored = try await RestoreSessionUseCase(authService: service)()
        #expect(restored == nil)
    }
}

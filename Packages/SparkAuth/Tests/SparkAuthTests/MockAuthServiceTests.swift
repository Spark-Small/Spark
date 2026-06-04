// Module: SparkAuthTests

import SparkAuth
import SparkPersistence
import Testing

struct MockAuthServiceTests {
    @Test func signInPersistsRestorableSession() async throws {
        let keychain = InMemoryKeychainManager()
        let store = AuthSessionStore(keychain: keychain)
        let tokenProvider = KeychainAccessTokenProvider(keychain: keychain)
        let service = MockAuthService(sessionStore: store, tokenProvider: tokenProvider)
        service.simulatedDelayNanoseconds = 0

        _ = try await service.signInWithEmail(email: "a@b.co", password: "secret1")
        let restored = try await service.restoreSession()
        #expect(restored?.userID.rawValue == "a")
    }
}

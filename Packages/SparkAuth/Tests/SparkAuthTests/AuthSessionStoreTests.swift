// Module: SparkAuthTests — AuthSessionStore coverage.

import Foundation
import SparkAuth
import SparkCore
import SparkPersistence
import Testing

struct AuthSessionStoreTests {
    @Test func saveLoadAndClearRoundTrip() async throws {
        let keychain = InMemoryKeychainManager()
        let store = AuthSessionStore(keychain: keychain)
        let session = AuthSession(userID: UserID("user_1"), accessToken: "token_abc")

        try await store.save(session)
        let loaded = await store.load()
        #expect(loaded?.userID == session.userID)
        #expect(loaded?.accessToken == session.accessToken)

        try await store.clear()
        #expect(await store.load() == nil)
    }

    @Test func loadReturnsNilWhenMissingUserID() async throws {
        let keychain = InMemoryKeychainManager()
        try keychain.save(Data("token".utf8), account: AuthSessionStore.tokenAccount)
        let store = AuthSessionStore(keychain: keychain)
        #expect(await store.load() == nil)
    }
}

struct AuthMockServiceIntegrationTests {
    @Test func mockServiceSignInSignOutLifecycle() async throws {
        let keychain = InMemoryKeychainManager()
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
        service.simulatedDelayNanoseconds = 0

        let emailSession = try await service.signInWithEmail(email: "test@spark.app", password: "secret1")
        #expect(emailSession.accessToken.isEmpty == false)

        let restored = try await service.restoreSession()
        #expect(restored?.userID == emailSession.userID)

        try await service.signOut()
        #expect(try await service.restoreSession() == nil)
    }

    @Test func mockServiceRejectsInvalidCredentials() async {
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: InMemoryKeychainManager()),
            tokenProvider: KeychainAccessTokenProvider(keychain: InMemoryKeychainManager())
        )
        service.simulatedDelayNanoseconds = 0

        await #expect(throws: AuthError.self) {
            _ = try await service.signInWithEmail(email: "bad@spark.app", password: "wrong")
        }
    }
}

// Module: SparkPersistenceTests

import SparkPersistence
import Testing

struct KeychainAccessTokenProviderTests {
    @Test func roundTripToken() async throws {
        let keychain = InMemoryKeychainManager()
        let provider = KeychainAccessTokenProvider(keychain: keychain, account: "test")
        try await provider.store(token: "sample-token")
        let token = await provider.accessToken()
        #expect(token == "sample-token")
        try await provider.clear()
        let cleared = await provider.accessToken()
        #expect(cleared == nil)
    }
}

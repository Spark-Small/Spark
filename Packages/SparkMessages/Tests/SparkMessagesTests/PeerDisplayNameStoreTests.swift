// Module: SparkMessagesTests — Peer remark persistence.

import Foundation
import SparkMessages
import Testing

@MainActor
struct PeerDisplayNameStoreTests {
    @Test func setAliasOverridesFallbackDisplayName() {
        let store = PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
        store.setAlias("备注小雨", for: "u_like_1")
        #expect(store.resolvedDisplayName(userID: "u_like_1", fallback: "小雨") == "备注小雨")
        #expect(store.changeToken == 1)
    }

    @Test func clearingAliasRestoresFallback() {
        let storage = InMemoryPeerDisplayNameStore()
        let store = PeerDisplayNameStore(storage: storage)
        store.setAlias("备注", for: "u_like_1")
        store.setAlias(nil, for: "u_like_1")
        #expect(store.resolvedDisplayName(userID: "u_like_1", fallback: "小雨") == "小雨")
    }

    @Test func userDefaultsStorePersistsAliases() throws {
        let defaults = try #require(UserDefaults(suiteName: "PeerDisplayNameStoreTests"))
        defaults.removePersistentDomain(forName: "PeerDisplayNameStoreTests")
        let storage = UserDefaultsPeerDisplayNameStore(defaults: defaults)
        storage.setAlias("备注 Alex", for: "u_alex")
        let reloaded = UserDefaultsPeerDisplayNameStore(defaults: defaults)
        #expect(reloaded.alias(for: "u_alex") == "备注 Alex")
    }
}

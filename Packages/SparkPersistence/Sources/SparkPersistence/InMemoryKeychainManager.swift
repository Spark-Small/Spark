// Module: SparkPersistence — Deterministic secrets store for unit tests (no Keychain entitlements).

import Foundation

/// In-process secrets storage; use in tests when `KeychainManager` returns `errSecMissingEntitlement`.
public final class InMemoryKeychainManager: @unchecked Sendable, KeychainStoring {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    private let namespace: String

    public init(namespace: String = UUID().uuidString) {
        self.namespace = namespace
    }

    public func save(_ data: Data, account: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key(for: account)] = data
    }

    public func load(account: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        guard let data = storage[key(for: account)] else {
            throw KeychainError.itemNotFound
        }
        return data
    }

    public func delete(account: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key(for: account))
    }

    private func key(for account: String) -> String {
        "\(namespace).\(account)"
    }
}

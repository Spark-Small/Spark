// Module: SparkPersistence — Keychain abstraction for Live and in-memory tests.

import Foundation

public protocol KeychainStoring: Sendable {
    func save(_ data: Data, account: String) throws
    func load(account: String) throws -> Data
    func delete(account: String) throws
}

extension KeychainManager: KeychainStoring {}

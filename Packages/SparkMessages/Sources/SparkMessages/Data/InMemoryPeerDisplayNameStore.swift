// Module: SparkMessages — In-memory peer remark store for previews and tests.

import Foundation

public final class InMemoryPeerDisplayNameStore: PeerDisplayNameStoring, @unchecked Sendable {
    private var aliases: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func alias(for userID: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return aliases[userID]
    }

    public func setAlias(_ alias: String?, for userID: String) {
        lock.lock()
        defer { lock.unlock() }
        if let alias {
            aliases[userID] = alias
        } else {
            aliases.removeValue(forKey: userID)
        }
    }
}

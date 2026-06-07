// Module: SparkMessages — UserDefaults-backed peer remark store.

import Foundation

// REASONING: Local display aliases are non-secret; UserDefaults matches other Spark preference stores.
public final class UserDefaultsPeerDisplayNameStore: PeerDisplayNameStoring, @unchecked Sendable {
    private static let storageKey = "messages.peer.aliases"
    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func alias(for userID: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return loadAliases()[userID]
    }

    public func setAlias(_ alias: String?, for userID: String) {
        lock.lock()
        defer { lock.unlock() }
        var aliases = loadAliases()
        if let alias {
            aliases[userID] = alias
        } else {
            aliases.removeValue(forKey: userID)
        }
        saveAliases(aliases)
    }

    private func loadAliases() -> [String: String] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    private func saveAliases(_ aliases: [String: String]) {
        guard let data = try? JSONEncoder().encode(aliases) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}

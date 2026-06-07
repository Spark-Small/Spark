// Module: SparkMessages — Observable peer remark resolver for inbox and conversation UI.

import Foundation
import Observation

@MainActor
@Observable
public final class PeerDisplayNameStore {
    private let storage: any PeerDisplayNameStoring

    /// Bumps when aliases change so dependent views can refresh lists.
    public private(set) var changeToken = 0

    public init(storage: any PeerDisplayNameStoring) {
        self.storage = storage
    }

    public func resolvedDisplayName(userID: String, fallback: String) -> String {
        guard let alias = storage.alias(for: userID)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !alias.isEmpty
        else {
            return fallback
        }
        return alias
    }

    public func alias(for userID: String) -> String? {
        storage.alias(for: userID)
    }

    public func setAlias(_ alias: String?, for userID: String) {
        let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (trimmed?.isEmpty == true) ? nil : trimmed
        storage.setAlias(value, for: userID)
        changeToken += 1
    }
}

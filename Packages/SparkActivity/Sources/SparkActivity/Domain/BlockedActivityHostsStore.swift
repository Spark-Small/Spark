// Module: SparkActivity — Local block list after report (Phase 23; Mock + client-only).

import Foundation

public actor BlockedActivityHostsStore {
    private var hostIDs: Set<String> = []

    public init() {}

    public func block(hostID: String) {
        let trimmed = hostID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        hostIDs.insert(trimmed)
    }

    public func isBlocked(hostID: String?) -> Bool {
        guard let hostID else { return false }
        return hostIDs.contains(hostID)
    }

    public func resetForTesting() {
        hostIDs.removeAll()
    }
}

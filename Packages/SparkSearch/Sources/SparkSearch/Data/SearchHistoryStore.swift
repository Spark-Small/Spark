// Module: SparkSearch — Persisted recent search queries.

import Foundation

public enum SearchHistoryStore: Sendable {
    private static let key = "spark.search.history"
    private static let maxEntries = 10

    public static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    public static func record(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var history = load().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        history.insert(trimmed, at: 0)
        if history.count > maxEntries {
            history = Array(history.prefix(maxEntries))
        }
        UserDefaults.standard.set(history, forKey: key)
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

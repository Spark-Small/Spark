//
//  TrustBehaviorLedger.swift
//  坐标系
//
//  行为事件账本（注册→注销）。
//

import Foundation

@MainActor
final class TrustBehaviorLedger {
    static let shared = TrustBehaviorLedger()

    private static let fileName = "trust_behavior_events.json"

    private(set) var allEvents: [TrustBehaviorEvent] = []

    private init() {
        allEvents = Self.load()
    }

    func append(_ event: TrustBehaviorEvent) {
        allEvents.insert(event, at: 0)
        if allEvents.count > 2_000 {
            allEvents = Array(allEvents.prefix(2_000))
        }
        persist()
    }

    func events(
        for actorKey: String,
        since: Date? = nil,
        names: Set<TrustEventName>? = nil
    ) -> [TrustBehaviorEvent] {
        allEvents.filter { event in
            guard event.actorKey.caseInsensitiveCompare(actorKey) == .orderedSame
                || event.subjectKey?.caseInsensitiveCompare(actorKey) == .orderedSame
            else { return false }
            if let since, event.createdAt < since { return false }
            if let names, !names.contains(event.name) { return false }
            return true
        }
    }

    func resetAll() {
        allEvents = []
        persist()
        Self.purgeLegacyStarReviewFiles()
    }

    /// 清理人对人星级评价遗留文件（行为信用上线后不再写入）。
    private static func purgeLegacyStarReviewFiles() {
        let root = documents
        for name in ["trust_reviews.json", "buddy_reviews.json", "user_reputation_reviews.json"] {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(name))
        }
    }

    private static func load() -> [TrustBehaviorEvent] {
        let url = documents.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TrustBehaviorEvent].self, from: data)
        else { return [] }
        return decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() {
        let url = Self.documents.appendingPathComponent(Self.fileName)
        guard let data = try? JSONEncoder().encode(allEvents) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

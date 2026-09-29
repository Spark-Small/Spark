//
//  RemoteSyncStatus.swift
//  坐标系
//
//  DEBUG 联调：记录最近一次远程快照同步结果。
//

import Foundation

@MainActor
enum RemoteSyncStatus {
    struct Entry: Equatable {
        let domain: String
        let ok: Bool
        let detail: String
        let at: Date
    }

    private(set) static var entries: [Entry] = []

    static func recordSuccess(_ domain: String, detail: String = "ok") {
        entries.insert(Entry(domain: domain, ok: true, detail: detail, at: .now), at: 0)
        trim()
    }

    static func recordFailure(_ domain: String, error: Error) {
        entries.insert(
            Entry(domain: domain, ok: false, detail: error.localizedDescription, at: .now),
            at: 0
        )
        trim()
    }

    static func recordSkipped(_ domain: String) {
        entries.insert(Entry(domain: domain, ok: true, detail: "skipped (flag off)", at: .now), at: 0)
        trim()
    }

    static var summaryLine: String {
        guard !entries.isEmpty else { return "尚未同步" }
        let recent = entries.prefix(4)
        return recent.map { e in
            "\(e.domain):\(e.ok ? "✓" : "✗")"
        }.joined(separator: " · ")
    }

    private static func trim() {
        if entries.count > 12 {
            entries = Array(entries.prefix(12))
        }
    }
}

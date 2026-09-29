//
//  RecentBrowseModelActor.swift
//  坐标系
//
//  最近浏览写入的 @ModelActor 隔离；UI 仍用 @Query 读主上下文。
//

import CoordinateModels
import Foundation
import SwiftData

@ModelActor
actor RecentBrowseModelActor {
    private static let legacyFileName = "profile_recent_browse.json"

    func migrateLegacyIfNeeded(maxItems: Int) throws {
        let existing = try modelContext.fetch(FetchDescriptor<RecentBrowseItem>())
        guard existing.isEmpty else {
            PersistenceMigration.removeLegacyFile(Self.legacyFileName)
            return
        }

        let legacy = PersistenceMigration.loadLegacyJSON(
            Self.legacyFileName,
            fallback: ProfileRecentBrowseSnapshot.seed
        )
        guard !legacy.items.isEmpty else {
            PersistenceMigration.removeLegacyFile(Self.legacyFileName)
            return
        }

        for record in legacy.items.prefix(maxItems) {
            modelContext.insert(
                RecentBrowseItem(
                    activityID: record.activityID,
                    title: record.title,
                    viewedAt: record.viewedAt
                )
            )
        }
        try modelContext.save()
        PersistenceMigration.removeLegacyFile(Self.legacyFileName)
    }

    func record(activityID: UUID, title: String, maxItems: Int) throws {
        var existing = FetchDescriptor<RecentBrowseItem>(
            predicate: #Predicate { $0.activityID == activityID }
        )
        existing.fetchLimit = 1
        if let hit = try modelContext.fetch(existing).first {
            hit.title = title
            hit.viewedAt = .now
        } else {
            modelContext.insert(
                RecentBrowseItem(
                    activityID: activityID,
                    title: title
                )
            )
        }
        try trimIfNeeded(maxItems: maxItems)
        try modelContext.save()
    }

    func clear() throws {
        let all = try modelContext.fetch(FetchDescriptor<RecentBrowseItem>())
        for item in all {
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    private func trimIfNeeded(maxItems: Int) throws {
        let descriptor = FetchDescriptor<RecentBrowseItem>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        let rows = try modelContext.fetch(descriptor)
        guard rows.count > maxItems else { return }
        for item in rows.dropFirst(maxItems) {
            modelContext.delete(item)
        }
    }
}

//
//  ProfileRecentBrowseStore.swift
//  坐标系
//
//  「我的」最近浏览：SwiftData 持久化；打开活动详情时写入。
//  UI 用 `@Query` 读；本 Store 只负责写入、清空与旧 JSON 迁移。
//

import Foundation
import SwiftData

@MainActor
final class ProfileRecentBrowseStore {
    static let shared = ProfileRecentBrowseStore()

    static let maxItems = 20

    private var container: ModelContainer?
    private var didMigrateLegacyJSON = false

    private init() {}

    /// App 启动后注入共享 container（与 `.modelContainer` 同源）。
    func attach(container: ModelContainer) {
        self.container = container
        migrateLegacyJSONIfNeeded()
    }

    private var context: ModelContext? {
        container?.mainContext
    }

    func record(_ activity: Activity) {
        guard let context else { return }
        let id = activity.id
        var existing = FetchDescriptor<RecentBrowseItem>(
            predicate: #Predicate { $0.activityID == id }
        )
        existing.fetchLimit = 1
        if let hit = try? context.fetch(existing).first {
            hit.title = activity.title
            hit.viewedAt = .now
        } else {
            context.insert(
                RecentBrowseItem(
                    activityID: activity.id,
                    title: activity.title,
                    viewedAt: .now
                )
            )
        }
        trimIfNeeded(in: context)
        try? context.save()
    }

    func clear() {
        guard let context else { return }
        let all = (try? context.fetch(FetchDescriptor<RecentBrowseItem>())) ?? []
        for item in all {
            context.delete(item)
        }
        try? context.save()
    }

    private func trimIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<RecentBrowseItem>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        guard rows.count > Self.maxItems else { return }
        for item in rows.dropFirst(Self.maxItems) {
            context.delete(item)
        }
    }

    private func migrateLegacyJSONIfNeeded() {
        guard !didMigrateLegacyJSON, let context else { return }
        didMigrateLegacyJSON = true

        let existing = (try? context.fetch(FetchDescriptor<RecentBrowseItem>())) ?? []
        guard existing.isEmpty else {
            AppPersistence.clearRecentBrowseFile()
            return
        }

        let legacy = AppPersistence.loadRecentBrowse()
        guard !legacy.items.isEmpty else {
            AppPersistence.clearRecentBrowseFile()
            return
        }

        for record in legacy.items.prefix(Self.maxItems) {
            context.insert(
                RecentBrowseItem(
                    activityID: record.activityID,
                    title: record.title,
                    viewedAt: record.viewedAt
                )
            )
        }
        try? context.save()
        AppPersistence.clearRecentBrowseFile()
    }
}

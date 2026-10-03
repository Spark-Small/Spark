//
//  AppSwiftDataSchema.swift
//  坐标系
//
//  SwiftData VersionedSchema + SchemaMigrationPlan（Apple 生产推荐）。
//  新增 @Model 或改字段时（强制）：
//  1. 新增 AppSwiftDataSchemaVn（versionIdentifier 递增）
//  2. MigrationPlan.schemas 追加；stages 增加 lightweight 或自定义 MigrationStage
//  3. AppSwiftDataContainer 的 Schema(versionedSchema:) 指向最新 schema
//  禁止：删库、seed 覆盖用户容器、依赖「清 App」完成迁移。
//

import CoordinateModels
import Foundation
import os
import SwiftData

// MARK: - V1

enum AppSwiftDataSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    /// 与历史落盘实体同名：仅活动足迹。
    @Model
    final class RecentBrowseItem {
        @Attribute(.unique) var activityID: UUID
        var title: String
        var viewedAt: Date

        init(activityID: UUID, title: String, viewedAt: Date = .now) {
            self.activityID = activityID
            self.title = title
            self.viewedAt = viewedAt
        }
    }

    static var models: [any PersistentModel.Type] {
        [
            DomainSnapshotEntity.self,
            RecentBrowseItem.self,
        ]
    }
}

// MARK: - V2（最近浏览多类型）

enum AppSwiftDataSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 1, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            DomainSnapshotEntity.self,
            RecentBrowseItem.self,
        ]
    }
}

// MARK: - Migration plan

enum AppSwiftDataMigrationPlan: SchemaMigrationPlan {
    /// willMigrate → didMigrate 传递活动足迹快照（Swift 6：锁保护可变全局态）。
    private static let pendingActivityBrowse = OSAllocatedUnfairLock(
        initialState: [(UUID, String, Date)]()
    )

    static var schemas: [any VersionedSchema.Type] {
        [AppSwiftDataSchemaV1.self, AppSwiftDataSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// 活动-only 足迹 → 多类型 `RecentBrowseItem`（kind=activity）。
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: AppSwiftDataSchemaV1.self,
        toVersion: AppSwiftDataSchemaV2.self,
        willMigrate: { context in
            let legacy = try context.fetch(FetchDescriptor<AppSwiftDataSchemaV1.RecentBrowseItem>())
            let snapshots = legacy.map { ($0.activityID, $0.title, $0.viewedAt) }
            pendingActivityBrowse.withLock { $0 = snapshots }
            for row in legacy {
                context.delete(row)
            }
            try context.save()
        },
        didMigrate: { context in
            let snapshots = pendingActivityBrowse.withLock { state in
                let copy = state
                state = []
                return copy
            }
            for row in snapshots {
                context.insert(
                    RecentBrowseItem(
                        kind: .activity,
                        targetID: row.0,
                        title: row.1,
                        viewedAt: row.2
                    )
                )
            }
            try context.save()
        }
    )
}

// MARK: - Container factory

enum AppSwiftDataContainer {
    static func makeProduction() throws -> ModelContainer {
        let schema = Schema(versionedSchema: AppSwiftDataSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppSwiftDataMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeInMemory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: AppSwiftDataSchemaV2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppSwiftDataMigrationPlan.self,
            configurations: [configuration]
        )
    }
}

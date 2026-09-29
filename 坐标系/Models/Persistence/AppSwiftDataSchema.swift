//
//  AppSwiftDataSchema.swift
//  坐标系
//
//  SwiftData VersionedSchema + SchemaMigrationPlan（Apple 生产推荐）。
//  新增 @Model 或改字段时（强制）：
//  1. 新增 AppSwiftDataSchemaV2（versionIdentifier 递增）
//  2. MigrationPlan.schemas 追加 V2；stages 增加 lightweight 或自定义 MigrationStage
//  3. AppSwiftDataContainer 的 Schema(versionedSchema:) 指向最新 schema
//  禁止：删库、seed 覆盖用户容器、依赖「清 App」完成迁移。
//

import SwiftData

// MARK: - V1

enum AppSwiftDataSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
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
    static var schemas: [any VersionedSchema.Type] {
        [AppSwiftDataSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Container factory

enum AppSwiftDataContainer {
    static func makeProduction() throws -> ModelContainer {
        let schema = Schema(versionedSchema: AppSwiftDataSchemaV1.self)
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
        let schema = Schema(versionedSchema: AppSwiftDataSchemaV1.self)
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

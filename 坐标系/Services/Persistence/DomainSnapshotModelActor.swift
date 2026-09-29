//
//  DomainSnapshotModelActor.swift
//  坐标系
//
//  五域 + engagement 快照的 @ModelActor 隔离读写（Apple SwiftData 后台上下文模式）。
//  跨 actor 只传递 Sendable 的 Codable 快照，不传递 @Model 实例。
//

import CoordinateData
import Foundation
import SwiftData

@ModelActor
actor DomainSnapshotModelActor {
    typealias AfterLoad<Snapshot> = @Sendable (Snapshot) -> (snapshot: Snapshot, shouldPersist: Bool)
        where Snapshot: Codable & Sendable

    func migrateLegacyJSONIfNeeded<Snapshot: Codable & Sendable>(
        domainKey: String,
        legacyFileName: String,
        fallback: @Sendable @escaping () -> Snapshot,
        afterLoad: (@Sendable (Snapshot) -> (snapshot: Snapshot, shouldPersist: Bool))?
    ) throws {
        if try fetchEntity(domainKey: domainKey) != nil {
            PersistenceMigration.removeLegacyFile(legacyFileName)
            return
        }

        guard PersistenceMigration.legacyFileExists(legacyFileName) else { return }

        var snapshot = PersistenceMigration.loadLegacyJSON(legacyFileName, fallback: fallback())
        if let afterLoad {
            snapshot = afterLoad(snapshot).snapshot
        }
        try persist(snapshot, domainKey: domainKey)
        PersistenceMigration.removeLegacyFile(legacyFileName)
    }

    func loadSnapshot<Snapshot: Codable & Sendable>(
        domainKey: String,
        fallback: @Sendable @escaping () -> Snapshot,
        afterLoad: (@Sendable (Snapshot) -> (snapshot: Snapshot, shouldPersist: Bool))?
    ) throws -> Snapshot {
        if let entity = try fetchEntity(domainKey: domainKey) {
            if let snapshot = decodeSnapshot(Snapshot.self, from: entity.payload) {
                if let afterLoad {
                    let outcome = afterLoad(snapshot)
                    if outcome.shouldPersist {
                        try persist(outcome.snapshot, domainKey: domainKey)
                    }
                    return outcome.snapshot
                }
                return snapshot
            }

            // 实体存在但解码失败：备份坏 payload，禁止用种子覆盖写回。
            try backupCorruptPayload(entity.payload, domainKey: domainKey)
            return fallback()
        }

        let seed = fallback()
        try persist(seed, domainKey: domainKey)
        return seed
    }

    func saveSnapshot<Snapshot: Codable & Sendable>(
        _ snapshot: Snapshot,
        domainKey: String
    ) throws {
        try persist(snapshot, domainKey: domainKey)
    }

    func clearSnapshot(domainKey: String) throws {
        if let entity = try fetchEntity(domainKey: domainKey) {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    // MARK: - Private

    private func fetchEntity(domainKey: String) throws -> DomainSnapshotEntity? {
        var descriptor = FetchDescriptor<DomainSnapshotEntity>(
            predicate: #Predicate { $0.domainKey == domainKey }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func decodeSnapshot<Snapshot: Decodable>(
        _ type: Snapshot.Type,
        from data: Data
    ) -> Snapshot? {
        try? JSONDecoder().decode(type, from: data)
    }

    private func persist<Snapshot: Encodable>(
        _ snapshot: Snapshot,
        domainKey: String
    ) throws {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        if let entity = try fetchEntity(domainKey: domainKey) {
            entity.payload = data
            entity.updatedAt = .now
        } else {
            modelContext.insert(
                DomainSnapshotEntity(
                    domainKey: domainKey,
                    payload: data
                )
            )
        }
        try modelContext.save()
    }

    /// 解码失败时把坏 payload 挪到旁路实体，禁止用种子覆盖用户数据。
    private func backupCorruptPayload(_ data: Data, domainKey: String) throws {
        let stamp = Int(Date().timeIntervalSince1970)
        let backupKey = "\(domainKey).corrupt.\(stamp)"
        if let entity = try fetchEntity(domainKey: domainKey) {
            modelContext.delete(entity)
        }
        modelContext.insert(
            DomainSnapshotEntity(
                domainKey: backupKey,
                payload: data
            )
        )
        try modelContext.save()
    }
}


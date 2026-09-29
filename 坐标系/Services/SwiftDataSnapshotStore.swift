//
//  SwiftDataSnapshotStore.swift
//  坐标系
//
//  MainActor 内存缓存 + @ModelActor 持久化（读缓存同步、写 actor 异步串行）。
//

import Foundation
import OSLog

private let snapshotPersistenceLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "app.zuobiaoxi.coordinate",
    category: "SwiftDataSnapshot"
)

@MainActor
final class SwiftDataSnapshotGateway<Snapshot: Codable & Sendable> {
    typealias AfterLoad = @Sendable (Snapshot) -> (snapshot: Snapshot, shouldPersist: Bool)

    private let domainKey: String
    private let legacyFileName: String
    private let fallback: @Sendable () -> Snapshot
    private let afterLoad: AfterLoad?
    private let actor: DomainSnapshotModelActor

    private var cached: Snapshot?
    private var didBootstrap = false
    private var saveTask: Task<Void, Never>?

    /// 最近一次异步落盘失败（供遥测 / 调试；UI 提示由域 Model 主路径负责）。
    private(set) var lastSaveError: Error?

    init(
        domainKey: String,
        legacyFileName: String,
        fallback: @escaping @Sendable () -> Snapshot,
        afterLoad: AfterLoad? = nil,
        actor: DomainSnapshotModelActor
    ) {
        self.domainKey = domainKey
        self.legacyFileName = legacyFileName
        self.fallback = fallback
        self.afterLoad = afterLoad
        self.actor = actor
    }

    /// 启动时从 @ModelActor 预热内存缓存并迁移旧 JSON。
    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true

        do {
            try await actor.migrateLegacyJSONIfNeeded(
                domainKey: domainKey,
                legacyFileName: legacyFileName,
                fallback: fallback,
                afterLoad: afterLoad
            )
            cached = try await actor.loadSnapshot(
                domainKey: domainKey,
                fallback: fallback,
                afterLoad: afterLoad
            )
        } catch {
            cached = fallback()
        }
    }

    /// 同步读：仅命中 MainActor 缓存（bootstrap 后可用）。
    func load() -> Snapshot {
        cached ?? fallback()
    }

    /// 同步写：先更新缓存，再串联交给 @ModelActor 落盘（避免连续写乱序）。
    func save(_ snapshot: Snapshot) {
        cached = snapshot
        let previous = saveTask
        let copy = snapshot
        let key = domainKey
        saveTask = MainActorPersistence.chained(after: previous) {
            do {
                try await self.actor.saveSnapshot(copy, domainKey: key)
                self.lastSaveError = nil
            } catch {
                self.lastSaveError = error
                snapshotPersistenceLogger.error(
                    "Snapshot save failed domain=\(key, privacy: .public) error=\(String(describing: error), privacy: .public)"
                )
                PersistenceWriteFailureReporter.record(domainKey: key, error: error)
            }
        }
    }

    func loadAsync() async throws -> Snapshot {
        let snapshot = try await actor.loadSnapshot(
            domainKey: domainKey,
            fallback: fallback,
            afterLoad: afterLoad
        )
        cached = snapshot
        return snapshot
    }

    func saveAsync(_ snapshot: Snapshot) async throws {
        let previous = saveTask
        _ = await previous?.result
        try await actor.saveSnapshot(snapshot, domainKey: domainKey)
        cached = snapshot
        lastSaveError = nil
    }

    func clear() async throws {
        let previous = saveTask
        _ = await previous?.result
        try await actor.clearSnapshot(domainKey: domainKey)
        cached = fallback()
        lastSaveError = nil
    }

    /// 等待当前串联写完成（后台 flush 用）。
    func awaitPendingSave() async {
        _ = await saveTask?.result
    }
}

/// Gateway 层写失败汇聚 → `AppPersistenceHealth` 横幅（域 Model 的 `flash` 仍是 Feature 主通道）。
@MainActor
enum PersistenceWriteFailureReporter {
    private(set) static var lastDomainKey: String?
    private(set) static var lastMessage: String?
    private(set) static var failureCount = 0
    private static var health: AppPersistenceHealth?

    static func bind(_ health: AppPersistenceHealth) {
        self.health = health
    }

    static func record(domainKey: String, error: Error) {
        lastDomainKey = domainKey
        lastMessage = String(describing: error)
        failureCount += 1
        health?.reportWriteFailure(domainKey: domainKey, error: error)
    }

    static func resetForTesting() {
        lastDomainKey = nil
        lastMessage = nil
        failureCount = 0
    }
}

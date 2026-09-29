//
//  SnapshotAsyncPersistenceBridge.swift
//  CoordinateDomain
//
//  SwiftData `@ModelActor` 等异步后端与 generation 失效机制的桥接。
//

import Foundation

/// 类型擦除的异步持久化后端；SwiftData Repository 通过 `asyncPersistenceBackend` 注入。
public protocol SnapshotAsyncPersistenceBackend: Sendable {
    func loadSnapshot() async throws -> Any
    func saveSnapshot(_ snapshot: Any, generation: Int, persistenceKey: LocalPersistenceKey) async throws
}

extension SnapshotRepository {
    /// 默认 `nil`：走同步 `load()` / `save()`（协议已 `@MainActor`）。SwiftData 实现覆写此属性。
    public var asyncPersistenceBackend: (any SnapshotAsyncPersistenceBackend)? { nil }

    public func loadAsync() async throws -> Snapshot {
        if let backend = asyncPersistenceBackend {
            let value = try await backend.loadSnapshot()
            guard let snapshot = value as? Snapshot else {
                throw SnapshotPersistenceError.typeMismatch
            }
            return snapshot
        }
        return load()
    }

    public func saveAsync(_ snapshot: Snapshot) async throws {
        let generation = currentPersistenceGeneration()
        try await saveAsync(snapshot, generation: generation)
    }

    public func saveAsync(_ snapshot: Snapshot, generation: Int) async throws {
        if let backend = asyncPersistenceBackend {
            guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
                throw CancellationError()
            }
            try await backend.saveSnapshot(snapshot, generation: generation, persistenceKey: persistenceKey)
            return
        }
        guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
            throw CancellationError()
        }
        save(snapshot)
    }
}

public enum SnapshotPersistenceError: Error, Sendable {
    case typeMismatch
}

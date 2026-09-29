//
//  SnapshotRepository.swift
//  CoordinateDomain
//

import Foundation

@MainActor
public protocol SnapshotRepository<Snapshot> where Snapshot: Sendable {
    associatedtype Snapshot
    var persistenceKey: LocalPersistenceKey { get }
    func load() -> Snapshot
    func save(_ snapshot: Snapshot)
}

extension SnapshotRepository {
    public func replace(with snapshot: Snapshot) {
        save(snapshot)
    }

    public func replaceAsync(with snapshot: Snapshot) async throws {
        try await saveAsync(snapshot)
    }

    public func replaceAsync(with snapshot: Snapshot, generation: Int) async throws {
        try await saveAsync(snapshot, generation: generation)
    }

    public func mutate(_ mutate: (inout Snapshot) -> Void) {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
    }

    public func mutateAsync(_ mutate: @escaping (inout Snapshot) -> Void) async throws {
        var snapshot = try await loadAsync()
        mutate(&snapshot)
        try await saveAsync(snapshot)
    }

    public func currentPersistenceGeneration() -> Int {
        LocalPersistenceCoordinator.currentGeneration(for: persistenceKey)
    }

    public func invalidatePendingWrites() {
        LocalPersistenceCoordinator.invalidate(persistenceKey)
    }
}

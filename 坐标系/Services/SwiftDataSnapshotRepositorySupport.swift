//
//  SwiftDataSnapshotRepositorySupport.swift
//  坐标系
//
//  SwiftData Gateway → CoordinateDomain `asyncPersistenceBackend` 适配。
//

import CoordinateDomain
import Foundation

struct SwiftDataSnapshotBackend<Snapshot: Codable & Sendable>: SnapshotAsyncPersistenceBackend {
    private let gateway: SwiftDataSnapshotGateway<Snapshot>

    init(gateway: SwiftDataSnapshotGateway<Snapshot>) {
        self.gateway = gateway
    }

    func loadSnapshot() async throws -> Any {
        try await gateway.loadAsync()
    }

    func saveSnapshot(
        _ snapshot: Any,
        generation: Int,
        persistenceKey: LocalPersistenceKey
    ) async throws {
        guard LocalPersistenceCoordinator.isCurrent(generation, for: persistenceKey) else {
            throw CancellationError()
        }
        guard let typed = snapshot as? Snapshot else {
            throw SnapshotPersistenceError.typeMismatch
        }
        try await gateway.saveAsync(typed)
    }
}

protocol SwiftDataSnapshotRepository: SnapshotRepository where Snapshot: Codable {
    var swiftDataGateway: SwiftDataSnapshotGateway<Snapshot> { get }
}

extension SwiftDataSnapshotRepository {
    var asyncPersistenceBackend: (any SnapshotAsyncPersistenceBackend)? {
        SwiftDataSnapshotBackend(gateway: swiftDataGateway)
    }
}

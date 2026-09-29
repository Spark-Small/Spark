//
//  LocalBuddiesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalBuddiesRepository: BuddiesRepository {
    public let persistenceKey: LocalPersistenceKey = .buddies

    private let fileName = "buddies_snapshot.json"
    private let policy: any BuddiesSnapshotPersistencePolicy

    public init(policy: any BuddiesSnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> BuddiesSnapshot {
        LocalSnapshotFileStore.load(fileName, fallback: policy.fallbackSnapshot())
    }

    public func save(_ snapshot: BuddiesSnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

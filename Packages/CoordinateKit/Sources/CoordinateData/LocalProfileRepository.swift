//
//  LocalProfileRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalProfileRepository: ProfileRepository {
    public let persistenceKey: LocalPersistenceKey = .profile

    private let fileName = "profile_snapshot.json"
    private let policy: any ProfileSnapshotPersistencePolicy

    public init(policy: any ProfileSnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> ProfileSnapshot {
        LocalSnapshotFileStore.load(fileName, fallback: policy.fallbackSnapshot())
    }

    public func save(_ snapshot: ProfileSnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

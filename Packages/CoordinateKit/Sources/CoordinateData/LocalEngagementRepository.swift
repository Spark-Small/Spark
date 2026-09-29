//
//  LocalEngagementRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalEngagementRepository: EngagementRepository {
    public let persistenceKey: LocalPersistenceKey = .engagement

    private let fileName = "activity_engagement_snapshot.json"
    private let policy: any EngagementSnapshotPersistencePolicy

    public init(policy: any EngagementSnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> ActivityEngagementSnapshot {
        LocalSnapshotFileStore.load(fileName, fallback: policy.fallbackSnapshot())
    }

    public func save(_ snapshot: ActivityEngagementSnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

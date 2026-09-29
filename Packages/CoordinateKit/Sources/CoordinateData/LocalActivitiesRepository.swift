//
//  LocalActivitiesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalActivitiesRepository: ActivitiesRepository {
    public let persistenceKey: LocalPersistenceKey = .activities

    private let fileName = "activities_snapshot.json"
    private let policy: any ActivitiesSnapshotPersistencePolicy

    public init(policy: any ActivitiesSnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> ActivitiesSnapshot {
        LocalSnapshotRepositorySupport.load(
            fileName: fileName,
            fallback: policy.fallbackSnapshot(),
            afterLoad: { snapshot in
                guard policy.needsRepairOnLoad(snapshot) else {
                    return (snapshot, false)
                }
                let repaired = policy.repairSnapshot(from: snapshot)
                return (repaired, true)
            }
        )
    }

    public func save(_ snapshot: ActivitiesSnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

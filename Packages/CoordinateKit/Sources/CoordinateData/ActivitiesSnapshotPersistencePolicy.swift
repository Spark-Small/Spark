//
//  ActivitiesSnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol ActivitiesSnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> ActivitiesSnapshot
    func needsRepairOnLoad(_ snapshot: ActivitiesSnapshot) -> Bool
    func repairSnapshot(from previous: ActivitiesSnapshot) -> ActivitiesSnapshot
}

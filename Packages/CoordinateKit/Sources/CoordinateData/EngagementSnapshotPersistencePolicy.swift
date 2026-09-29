//
//  EngagementSnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol EngagementSnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> ActivityEngagementSnapshot
}

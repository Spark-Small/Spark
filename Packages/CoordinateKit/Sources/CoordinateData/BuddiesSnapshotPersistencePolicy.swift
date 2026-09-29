//
//  BuddiesSnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol BuddiesSnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> BuddiesSnapshot
}

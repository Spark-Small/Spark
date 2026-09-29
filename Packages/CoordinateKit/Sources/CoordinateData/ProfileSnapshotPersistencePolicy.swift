//
//  ProfileSnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol ProfileSnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> ProfileSnapshot
}

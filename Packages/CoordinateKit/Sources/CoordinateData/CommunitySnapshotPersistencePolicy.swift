//
//  CommunitySnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol CommunitySnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> CommunitySnapshot
    func afterLoad(_ loaded: CommunitySnapshot) -> (snapshot: CommunitySnapshot, shouldPersist: Bool)
}

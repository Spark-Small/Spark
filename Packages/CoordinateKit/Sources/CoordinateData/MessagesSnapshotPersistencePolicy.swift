//
//  MessagesSnapshotPersistencePolicy.swift
//  CoordinateData
//

import CoordinateDomain

public protocol MessagesSnapshotPersistencePolicy: Sendable {
    func fallbackSnapshot() -> MessagesSnapshot
    func afterLoad(_ loaded: MessagesSnapshot) -> (snapshot: MessagesSnapshot, shouldPersist: Bool)
}

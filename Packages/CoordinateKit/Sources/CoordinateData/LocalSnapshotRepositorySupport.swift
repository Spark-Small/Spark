//
//  LocalSnapshotRepositorySupport.swift
//  CoordinateData
//

import Foundation

enum LocalSnapshotRepositorySupport {
    static func load<Snapshot: Codable & Sendable>(
        fileName: String,
        fallback: @autoclosure () -> Snapshot,
        afterLoad: (Snapshot) -> (snapshot: Snapshot, shouldPersist: Bool)
    ) -> Snapshot {
        let loaded = LocalSnapshotFileStore.load(fileName, fallback: fallback())
        let outcome = afterLoad(loaded)
        if outcome.shouldPersist {
            LocalSnapshotFileStore.save(outcome.snapshot, to: fileName)
        }
        return outcome.snapshot
    }
}

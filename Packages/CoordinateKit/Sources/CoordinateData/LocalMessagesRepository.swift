//
//  LocalMessagesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalMessagesRepository: MessagesRepository {
    public let persistenceKey: LocalPersistenceKey = .messages

    private let fileName = "messages_snapshot.json"
    private let policy: any MessagesSnapshotPersistencePolicy

    public init(policy: any MessagesSnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> MessagesSnapshot {
        LocalSnapshotRepositorySupport.load(
            fileName: fileName,
            fallback: policy.fallbackSnapshot(),
            afterLoad: policy.afterLoad
        )
    }

    public func save(_ snapshot: MessagesSnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

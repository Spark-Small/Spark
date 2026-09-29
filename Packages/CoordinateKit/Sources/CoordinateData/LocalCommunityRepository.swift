//
//  LocalCommunityRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public struct LocalCommunityRepository: CommunityRepository {
    public let persistenceKey: LocalPersistenceKey = .community

    private let fileName = "community_snapshot.json"
    private let policy: any CommunitySnapshotPersistencePolicy

    public init(policy: any CommunitySnapshotPersistencePolicy) {
        self.policy = policy
    }

    public func load() -> CommunitySnapshot {
        LocalSnapshotRepositorySupport.load(
            fileName: fileName,
            fallback: policy.fallbackSnapshot(),
            afterLoad: policy.afterLoad
        )
    }

    public func save(_ snapshot: CommunitySnapshot) {
        LocalSnapshotFileStore.save(snapshot, to: fileName)
    }
}

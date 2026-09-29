//
//  InMemoryCommunityRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryCommunityRepository: CommunityRepository {
    public let persistenceKey: LocalPersistenceKey = .community
    public var snapshot: CommunitySnapshot

    public init(snapshot: CommunitySnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> CommunitySnapshot { snapshot }

    public func save(_ snapshot: CommunitySnapshot) {
        self.snapshot = snapshot
    }
}

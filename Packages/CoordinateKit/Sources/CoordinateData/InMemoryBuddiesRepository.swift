//
//  InMemoryBuddiesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryBuddiesRepository: BuddiesRepository {
    public let persistenceKey: LocalPersistenceKey = .buddies
    public var snapshot: BuddiesSnapshot

    public init(snapshot: BuddiesSnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> BuddiesSnapshot { snapshot }

    public func save(_ snapshot: BuddiesSnapshot) {
        self.snapshot = snapshot
    }
}

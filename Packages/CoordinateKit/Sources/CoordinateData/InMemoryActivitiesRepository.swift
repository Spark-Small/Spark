//
//  InMemoryActivitiesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryActivitiesRepository: ActivitiesRepository {
    public let persistenceKey: LocalPersistenceKey = .activities
    public var snapshot: ActivitiesSnapshot

    public init(snapshot: ActivitiesSnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> ActivitiesSnapshot { snapshot }

    public func save(_ snapshot: ActivitiesSnapshot) {
        self.snapshot = snapshot
    }
}

//
//  InMemoryEngagementRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryEngagementRepository: EngagementRepository {
    public let persistenceKey: LocalPersistenceKey = .engagement
    public var snapshot: ActivityEngagementSnapshot

    public init(snapshot: ActivityEngagementSnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> ActivityEngagementSnapshot { snapshot }

    public func save(_ snapshot: ActivityEngagementSnapshot) {
        self.snapshot = snapshot
    }
}

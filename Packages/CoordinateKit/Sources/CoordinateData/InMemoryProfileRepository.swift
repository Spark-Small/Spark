//
//  InMemoryProfileRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryProfileRepository: ProfileRepository {
    public let persistenceKey: LocalPersistenceKey = .profile
    public var snapshot: ProfileSnapshot

    public init(snapshot: ProfileSnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> ProfileSnapshot { snapshot }

    public func save(_ snapshot: ProfileSnapshot) {
        self.snapshot = snapshot
    }
}

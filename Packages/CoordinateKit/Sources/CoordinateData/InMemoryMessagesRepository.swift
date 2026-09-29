//
//  InMemoryMessagesRepository.swift
//  CoordinateData
//

import CoordinateDomain
import Foundation

public final class InMemoryMessagesRepository: MessagesRepository {
    public let persistenceKey: LocalPersistenceKey = .messages
    public var snapshot: MessagesSnapshot

    public init(snapshot: MessagesSnapshot) {
        self.snapshot = snapshot
    }

    public func load() -> MessagesSnapshot { snapshot }

    public func save(_ snapshot: MessagesSnapshot) {
        self.snapshot = snapshot
    }
}

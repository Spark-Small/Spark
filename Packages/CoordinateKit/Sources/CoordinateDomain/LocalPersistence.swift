//
//  LocalPersistence.swift
//  CoordinateDomain
//

import Foundation
import os

public enum LocalPersistenceKey: Hashable, Sendable {
    case activities
    case messages
    case buddies
    case community
    case profile
    case engagement
}

/// Generation 计数：用 `OSAllocatedUnfairLock` 保护可变全局状态（Swift 6 / Apple 推荐）。
public enum LocalPersistenceCoordinator {
    private static let generations = OSAllocatedUnfairLock(initialState: [LocalPersistenceKey: Int]())

    public static func currentGeneration(for key: LocalPersistenceKey) -> Int {
        generations.withLock { $0[key, default: 0] }
    }

    @discardableResult
    public static func invalidate(_ key: LocalPersistenceKey) -> Int {
        generations.withLock { state in
            let next = state[key, default: 0] + 1
            state[key] = next
            return next
        }
    }

    public static func invalidate(_ keys: [LocalPersistenceKey]) {
        generations.withLock { state in
            for key in keys {
                state[key] = state[key, default: 0] + 1
            }
        }
    }

    public static func isCurrent(_ generation: Int, for key: LocalPersistenceKey) -> Bool {
        generations.withLock { $0[key, default: 0] == generation }
    }
}

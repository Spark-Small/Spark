//
//  SnapshotFileActor.swift
//  CoordinateDomain
//
//  串行化快照异步 I/O，替代 SnapshotRepository 扩展里的 DispatchQueue。
//

import Foundation

public actor SnapshotFileActor {
    public static let shared = SnapshotFileActor()

    public func perform<T: Sendable>(_ operation: @Sendable () throws -> T) rethrows -> T {
        try operation()
    }
}

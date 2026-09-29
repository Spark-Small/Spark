//
//  MainActorPersistence.swift
//  坐标系
//
//  域 Model 异步落盘：在 MainActor 上串联 Task，避免非隔离 Task 跨 actor 传递 Repository。
//

import Foundation

enum MainActorPersistence {
    /// 在 MainActor 上等待上一笔落盘后再执行（供 `@MainActor` Model 使用）。
    @MainActor
    static func chained(
        after previous: Task<Void, Never>?,
        operation: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            _ = await previous?.result
            guard !Task.isCancelled else { return }
            await operation()
        }
    }
}

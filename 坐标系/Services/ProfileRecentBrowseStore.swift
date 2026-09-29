//
//  ProfileRecentBrowseStore.swift
//  坐标系
//
//  「我的」最近浏览：SwiftData 持久化；打开活动详情时写入。
//  UI 用 `@Query` 读；本 Store 经 @ModelActor 写入、清空与旧 JSON 迁移。
//

import Foundation
import SwiftData
import CoordinateModels

@MainActor
final class ProfileRecentBrowseStore {
    static let maxItems = 20

    private var browseActor: RecentBrowseModelActor?
    private var didBootstrap = false

    init() {}

    /// App 启动后注入共享 container（与 `.modelContainer` 同源）。
    func attach(container: ModelContainer) {
        browseActor = RecentBrowseModelActor(modelContainer: container)
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        try? await browseActor?.migrateLegacyIfNeeded(maxItems: Self.maxItems)
    }

    func record(_ activity: Activity) {
        let actor = browseActor
        let activityID = activity.id
        let title = activity.title
        Task { @MainActor in
            try? await actor?.record(
                activityID: activityID,
                title: title,
                maxItems: Self.maxItems
            )
        }
    }

    func clear() {
        let actor = browseActor
        Task { @MainActor in
            try? await actor?.clear()
        }
    }

    func clearSynchronously() async throws {
        try await browseActor?.clear()
    }
}

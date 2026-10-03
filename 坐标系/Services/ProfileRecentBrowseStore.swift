//
//  ProfileRecentBrowseStore.swift
//  坐标系
//
//  最近浏览：SwiftData 持久化；活动 / 搭子 / 陪玩 / 俱乐部详情写入（无广场）。
//  UI 用 `@Query` 读；本 Store 经 @ModelActor 写入、清空与旧 JSON 迁移。
//

import Foundation
import SwiftData
import CoordinateModels

@MainActor
final class ProfileRecentBrowseStore {
    /// 每一 `RecentBrowseKind` 的上限。
    static let maxItemsPerKind = 20

    private var browseActor: RecentBrowseModelActor?
    private var didBootstrap = false

    init() {}

    func attach(container: ModelContainer) {
        browseActor = RecentBrowseModelActor(modelContainer: container)
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        try? await browseActor?.migrateLegacyIfNeeded(maxItems: Self.maxItemsPerKind)
    }

    func record(
        kind: RecentBrowseKind,
        targetID: UUID,
        title: String,
        subtitle: String = ""
    ) {
        let actor = browseActor
        Task { @MainActor in
            try? await actor?.record(
                kind: kind,
                targetID: targetID,
                title: title,
                subtitle: subtitle,
                maxItems: Self.maxItemsPerKind
            )
        }
    }

    func record(_ activity: Activity) {
        record(
            kind: .activity,
            targetID: activity.id,
            title: activity.title,
            subtitle: Formatters.activityEventTime(from: activity.date)
        )
    }

    func record(buddy profile: BuddyProfile) {
        record(
            kind: .buddy,
            targetID: profile.id,
            title: profile.nickname,
            subtitle: profile.city
        )
    }

    func record(companion: PaidCompanion) {
        record(
            kind: .companion,
            targetID: companion.id,
            title: companion.profile.nickname,
            subtitle: companion.priceText
        )
    }

    func record(circle: InterestCircle) {
        record(
            kind: .club,
            targetID: circle.id,
            title: circle.name,
            subtitle: "\(circle.city) · \(circle.topic)"
        )
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

extension ProfileRecentBrowseStore {
    /// 兼容旧名。
    static var maxItems: Int { maxItemsPerKind }
}

//
//  ProfileRecentBrowseStore.swift
//  坐标系
//
//  「我的」最近浏览：打开活动详情时写入，供个人页横滑展示。
//

import Foundation

@MainActor
final class ProfileRecentBrowseStore {
    static let shared = ProfileRecentBrowseStore()

    private var snapshot: ProfileRecentBrowseSnapshot

    private init() {
        snapshot = AppPersistence.loadRecentBrowse()
    }

    func items() -> [ProfileRecentBrowseRecord] {
        snapshot.items
    }

    func record(_ activity: Activity) {
        var items = snapshot.items.filter { $0.activityID != activity.id }
        items.insert(
            ProfileRecentBrowseRecord(
                activityID: activity.id,
                title: activity.title,
                viewedAt: .now
            ),
            at: 0
        )
        snapshot.items = Array(items.prefix(ProfileRecentBrowseSnapshot.maxItems))
        persist()
    }

    func clear() {
        snapshot.items = []
        persist()
    }

    func reloadFromDisk() {
        snapshot = AppPersistence.loadRecentBrowse()
    }

    private func persist() {
        AppPersistence.saveRecentBrowse(snapshot)
    }
}

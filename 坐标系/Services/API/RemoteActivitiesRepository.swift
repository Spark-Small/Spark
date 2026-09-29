//
//  RemoteActivitiesRepository.swift
//  坐标系
//
//  本地优先活动仓库：读写在本地；可选在 bootstrap 时拉远程目录覆盖。
//

import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation

@MainActor
final class RemoteActivitiesRepository: ActivitiesRepository {
    let persistenceKey: LocalPersistenceKey = .activities
    private let local: any ActivitiesRepository

    init(local: any ActivitiesRepository) {
        self.local = local
    }

    private var client: APIClient { .shared }

    func load() -> ActivitiesSnapshot {
        local.load()
    }

    func save(_ snapshot: ActivitiesSnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则落盘，失败保留本地。
    func syncRemoteCatalogIfEnabled() async {
        guard FeatureFlags.useRemoteCatalog else {
            RemoteSyncStatus.recordSkipped("catalog")
            return
        }
        do {
            let remote = try await client.send(.activitiesCatalog)
            local.save(remote)
            RemoteSyncStatus.recordSuccess(
                "catalog",
                detail: "\(remote.activities.count) activities"
            )
        } catch {
            RemoteSyncStatus.recordFailure("catalog", error: error)
        }
    }
}

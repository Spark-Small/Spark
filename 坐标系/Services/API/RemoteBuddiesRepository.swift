//
//  RemoteBuddiesRepository.swift
//  坐标系
//
//  本地优先搭子仓库：读写在本地；远程成功经 Merge UC 落盘，禁止整包覆盖。
//  始终由 AppComposition 包装；`useRemoteBuddies` 仅控制 sync。
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation

@MainActor
final class RemoteBuddiesRepository: BuddiesRepository {
    let persistenceKey: LocalPersistenceKey = .buddies
    private let local: any BuddiesRepository
    private let client: APIClient
    private let mergeRemoteSnapshot: MergeRemoteBuddiesSnapshotUseCase

    init(
        local: any BuddiesRepository,
        client: APIClient = .shared,
        mergeRemoteSnapshot: MergeRemoteBuddiesSnapshotUseCase = MergeRemoteBuddiesSnapshotUseCase()
    ) {
        self.local = local
        self.client = client
        self.mergeRemoteSnapshot = mergeRemoteSnapshot
    }

    func load() -> BuddiesSnapshot {
        local.load()
    }

    func save(_ snapshot: BuddiesSnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则 Merge 落盘，失败保留本地。
    /// 预约接单回执另见 `RemoteBookingSyncService`（`buddies/bookings`）。
    func syncRemoteBuddiesIfEnabled() async {
        guard FeatureFlags.useRemoteBuddies else {
            RemoteSyncStatus.recordSkipped("buddies")
            return
        }
        do {
            let remote = try await client.send(.buddiesSnapshot)
            let previous = local.load()
            let merged = mergeRemoteSnapshot.execute(remote: remote, previous: previous)
            local.save(merged)
            let catalogCount = (merged.discoverCatalog?.freeBuddies.count ?? 0)
                + (merged.discoverCatalog?.paidCompanions.count ?? 0)
            RemoteSyncStatus.recordSuccess(
                "buddies",
                detail: "bookings=\(merged.bookingRecords.count) invites=\(merged.inviteRecords.count) catalog=\(catalogCount)"
            )
        } catch {
            RemoteSyncStatus.recordFailure("buddies", error: error)
        }
    }
}

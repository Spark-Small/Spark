//
//  RemoteBuddiesRepository.swift
//  坐标系
//
//  本地优先搭子仓库：读写在本地；预留远程同步入口。
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

    init(
        local: any BuddiesRepository,
        client: APIClient = .shared
    ) {
        self.local = local
        self.client = client
    }

    func load() -> BuddiesSnapshot {
        local.load()
    }

    func save(_ snapshot: BuddiesSnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则落盘，失败保留本地。
    /// 预约接单回执另见 `RemoteBookingSyncService`（`buddies/bookings`）。
    func syncRemoteBuddiesIfEnabled() async {
        guard FeatureFlags.useRemoteBuddies else { return }
        do {
            let remote = try await client.send(.buddiesSnapshot)
            local.save(remote)
        } catch {
            // 本地优先
        }
    }
}

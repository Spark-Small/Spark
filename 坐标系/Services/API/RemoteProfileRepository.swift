//
//  RemoteProfileRepository.swift
//  坐标系
//
//  本地优先资料仓库：读写在本地；预留远程同步入口。
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation

@MainActor
final class RemoteProfileRepository: ProfileRepository {
    let persistenceKey: LocalPersistenceKey = .profile
    private let local: any ProfileRepository

    init(local: any ProfileRepository) {
        self.local = local
    }

    private var client: APIClient { .shared }

    func load() -> ProfileSnapshot {
        local.load()
    }

    func save(_ snapshot: ProfileSnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则落盘，失败保留本地。
    func syncRemoteProfileIfEnabled() async {
        guard FeatureFlags.useRemoteProfile else {
            RemoteSyncStatus.recordSkipped("profile")
            return
        }
        do {
            let remote = try await client.send(.profileSnapshot)
            local.save(remote)
            RemoteSyncStatus.recordSuccess("profile", detail: remote.user.name)
        } catch {
            RemoteSyncStatus.recordFailure("profile", error: error)
        }
    }
}

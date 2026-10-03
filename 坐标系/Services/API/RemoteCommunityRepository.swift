//
//  RemoteCommunityRepository.swift
//  坐标系
//
//  本地优先广场仓库：读写在本地；远程同步经 Merge，禁止整包覆盖。
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation

@MainActor
final class RemoteCommunityRepository: CommunityRepository {
    let persistenceKey: LocalPersistenceKey = .community
    private let local: any CommunityRepository
    private let mergeRemote = MergeRemoteCommunitySnapshotUseCase()

    init(local: any CommunityRepository) {
        self.local = local
    }

    private var client: APIClient { .shared }

    func load() -> CommunitySnapshot {
        local.load()
    }

    func save(_ snapshot: CommunitySnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则 Merge 落盘，失败保留本地。
    func syncRemoteCommunityIfEnabled() async {
        guard FeatureFlags.useRemoteCommunity else {
            RemoteSyncStatus.recordSkipped("community")
            return
        }
        do {
            let remote = try await client.send(.communitySnapshot)
            let previous = local.load()
            let merged = mergeRemote.execute(remote: remote, previous: previous)
            local.save(merged)
            RemoteSyncStatus.recordSuccess("community", detail: "\(merged.posts.count) posts")
        } catch {
            RemoteSyncStatus.recordFailure("community", error: error)
        }
    }
}

//
//  RemoteMessagesRepository.swift
//  坐标系
//
//  本地优先消息仓库：读写在本地；预留远程同步入口。
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateNetworking
import Foundation

@MainActor
final class RemoteMessagesRepository: MessagesRepository {
    let persistenceKey: LocalPersistenceKey = .messages
    private let local: any MessagesRepository
    private let client: APIClient

    init(
        local: any MessagesRepository,
        client: APIClient = .shared
    ) {
        self.local = local
        self.client = client
    }

    func load() -> MessagesSnapshot {
        local.load()
    }

    func save(_ snapshot: MessagesSnapshot) {
        local.save(snapshot)
    }

    /// bootstrap 阶段调用：远程成功则落盘，失败保留本地。
    func syncRemoteMessagesIfEnabled() async {
        guard FeatureFlags.useRemoteMessages else { return }
        do {
            let remote = try await client.send(.messagesSnapshot)
            local.save(remote)
        } catch {
            // 本地优先
        }
    }
}

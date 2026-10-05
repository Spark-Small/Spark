//
//  MergeRemoteWalletLedgerUseCase.swift
//  CoordinateDomain
//
//  远程流水投影合并：服务端权威时以远程页为准，禁止用「已全网同步」话术掩盖空页。
//

import Foundation

public struct MergeRemoteWalletLedgerUseCase: Sendable {
    public init() {}

    /// `useRemoteWallet` 开启时：首屏以远程 items 的 id 顺序（调用方已按时间排好）整体替换本地投影。
    /// 返回应展示的 id 列表；空远程 → 空列表（诚实空态，不保留本地假「已同步」感）。
    public func replaceProjection(remoteIDs: [UUID]) -> [UUID] {
        remoteIDs
    }

    /// 流水拉取失败时：保留本地 id；成功但空：清空（由 `replaceProjection` 表达）。
    public func idsAfterRefresh(
        previousLocalIDs: [UUID],
        remoteIDs: [UUID]?,
        remoteFetchSucceeded: Bool
    ) -> [UUID] {
        guard remoteFetchSucceeded else { return previousLocalIDs }
        return replaceProjection(remoteIDs: remoteIDs ?? [])
    }
}

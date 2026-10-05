//
//  WalletStore+Remote.swift
//  坐标系
//
//  远程钱包投影与刷新。
//

import CoordinateDomain
import CoordinateFeatureFlags
import CoordinateModels
import Foundation

extension WalletStore {
    /// 账户余额以服务端为准；流水优先拉远程首页；失败或短暂空页回落本笔投影（禁止未确认加款）。
    func projectRemoteAccount(
        _ account: WalletAccountDTO,
        fallback: WalletLedgerEntry
    ) async {
        balanceCents = account.availableCents
        let previousIDs = entries.map(\.id)
        do {
            let page = try await RemoteWalletClient.fetchLedger(cursor: nil)
            let remoteEntries = page.items.map(Self.mapRemoteLedgerItem)
            let mergedIDs = MergeRemoteWalletLedgerUseCase().idsAfterRefresh(
                previousLocalIDs: previousIDs,
                remoteIDs: remoteEntries.map(\.id),
                remoteFetchSucceeded: true
            )
            if mergedIDs.isEmpty {
                entries = [fallback]
            } else {
                let byID = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })
                entries = mergedIDs.compactMap { byID[$0] }
                    .sorted { $0.createdAt > $1.createdAt }
            }
        } catch {
            _ = MergeRemoteWalletLedgerUseCase().idsAfterRefresh(
                previousLocalIDs: previousIDs,
                remoteIDs: nil,
                remoteFetchSucceeded: false
            )
            if let index = entries.firstIndex(where: { $0.id == fallback.id }) {
                entries[index] = fallback
            } else {
                prepend(fallback)
            }
        }
        persist()
        syncLegacyBalance()
    }

    /// 用服务端账户覆盖本地余额投影，并追加一笔对应流水（同步回落路径）。
    func applyRemoteAccount(
        _ account: WalletAccountDTO,
        ledgerKind: WalletEntryKind,
        title: String,
        subtitle: String?,
        amountCents: Int,
        balanceDeltaCents: Int,
        method: PaymentMethod,
        relatedID: UUID?
    ) {
        balanceCents = account.availableCents
        prepend(
            WalletLedgerEntry(
                id: UUID(),
                kind: ledgerKind,
                title: title,
                subtitle: subtitle,
                balanceDeltaCents: balanceDeltaCents,
                amountCents: amountCents,
                method: method,
                createdAt: .now,
                relatedID: relatedID
            )
        )
        persist()
        syncLegacyBalance()
    }

    /// 拉远程账户 + 流水首页；失败保留本地投影，不弹假成功、不写「已全网同步」。
    func refreshFromRemoteIfEnabled() async {
        guard FeatureFlags.useRemoteWallet else { return }
        let previousIDs = entries.map(\.id)
        do {
            let account = try await RemoteWalletClient.fetchAccount()
            balanceCents = account.availableCents
            do {
                let page = try await RemoteWalletClient.fetchLedger(cursor: nil)
                let remoteEntries = page.items.map(Self.mapRemoteLedgerItem)
                let mergedIDs = MergeRemoteWalletLedgerUseCase().idsAfterRefresh(
                    previousLocalIDs: previousIDs,
                    remoteIDs: remoteEntries.map(\.id),
                    remoteFetchSucceeded: true
                )
                let byID = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })
                entries = mergedIDs.compactMap { byID[$0] }
                    .sorted { $0.createdAt > $1.createdAt }
            } catch {
                _ = MergeRemoteWalletLedgerUseCase().idsAfterRefresh(
                    previousLocalIDs: previousIDs,
                    remoteIDs: nil,
                    remoteFetchSucceeded: false
                )
                // 账户已更新；流水保留本地
            }
            syncLegacyBalance()
            persist()
        } catch {
            // 保留本地投影；不弹假成功
        }
    }

}

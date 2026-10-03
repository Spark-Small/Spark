//
//  MergeRemoteBuddiesSnapshotUseCase.swift
//  CoordinateDomain
//
//  远程搭子快照合并：保留本机俱乐部 / 预约 / 加入态，禁止整包覆盖。
//

import Foundation
import CoordinateModels

public struct MergeRemoteBuddiesSnapshotUseCase: Sendable {
    private let reconcileBooking: ReconcileRemoteBookingRecordUseCase

    public init(reconcileBooking: ReconcileRemoteBookingRecordUseCase = ReconcileRemoteBookingRecordUseCase()) {
        self.reconcileBooking = reconcileBooking
    }

    public func execute(
        remote: BuddiesSnapshot,
        previous: BuddiesSnapshot
    ) -> BuddiesSnapshot {
        BuddiesSnapshot(
            inviteRecords: mergeInvites(remote: remote.inviteRecords, previous: previous.inviteRecords),
            bookingRecords: mergeBookings(remote: remote.bookingRecords, previous: previous.bookingRecords),
            clubs: mergeClubs(remote: remote.clubs, previous: previous.clubs),
            joinedCircleIDs: Array(Set(previous.joinedCircleIDs).union(remote.joinedCircleIDs)),
            joinedCircleNames: Array(Set(previous.joinedCircleNames).union(remote.joinedCircleNames)),
            joinedGuildNames: Array(Set(previous.joinedGuildNames).union(remote.joinedGuildNames)),
            membershipPrefs: mergePrefs(remote: remote.membershipPrefs, previous: previous.membershipPrefs),
            // 远程下发则采信（含空目录）；未下发字段时保留本机已缓存的契约数据
            discoverCatalog: remote.discoverCatalog ?? previous.discoverCatalog
        )
    }

    private func mergeClubs(
        remote: [InterestCircle],
        previous: [InterestCircle]
    ) -> [InterestCircle] {
        let remoteIDs = Set(remote.map(\.id))
        let localOnly = previous.filter { !remoteIDs.contains($0.id) }
        return remote + localOnly
    }

    private func mergeBookings(
        remote: [BuddyBookingRecord],
        previous: [BuddyBookingRecord]
    ) -> [BuddyBookingRecord] {
        let remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        var result: [BuddyBookingRecord] = []
        var seen = Set<UUID>()

        for local in previous {
            seen.insert(local.id)
            if let remoteRecord = remoteByID[local.id],
               let reconciled = reconcileBooking.reconcile(local: local, remote: remoteRecord) {
                result.append(reconciled)
            } else {
                result.append(local)
            }
        }

        for remoteRecord in remote where !seen.contains(remoteRecord.id) {
            result.append(remoteRecord)
        }

        return result
    }

    private func mergeInvites(
        remote: [BuddyInviteRecord],
        previous: [BuddyInviteRecord]
    ) -> [BuddyInviteRecord] {
        let remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        var result: [BuddyInviteRecord] = []
        var seen = Set<UUID>()

        for local in previous {
            seen.insert(local.id)
            if let remoteRecord = remoteByID[local.id] {
                result.append(preferInvite(local: local, remote: remoteRecord))
            } else {
                result.append(local)
            }
        }

        for remoteRecord in remote where !seen.contains(remoteRecord.id) {
            result.append(remoteRecord)
        }

        return result
    }

    /// previous 优先；remote 仅在 status 前进或非空字段补缺时采信。
    private func preferInvite(
        local: BuddyInviteRecord,
        remote: BuddyInviteRecord
    ) -> BuddyInviteRecord {
        var merged = local
        if local.status == .pending, remote.status != .pending {
            merged.status = remote.status
        }
        if merged.relatedActivityID == nil, let id = remote.relatedActivityID {
            merged.relatedActivityID = id
        }
        if merged.activityTitle.isEmpty, !remote.activityTitle.isEmpty {
            merged.activityTitle = remote.activityTitle
        }
        if merged.inviteeUserID == nil, let id = remote.inviteeUserID {
            merged.inviteeUserID = id
        }
        return merged
    }

    private func mergePrefs(
        remote: [String: OrgMembershipPrefs],
        previous: [String: OrgMembershipPrefs]
    ) -> [String: OrgMembershipPrefs] {
        var merged = previous
        for (key, value) in remote where merged[key] == nil {
            merged[key] = value
        }
        return merged
    }
}

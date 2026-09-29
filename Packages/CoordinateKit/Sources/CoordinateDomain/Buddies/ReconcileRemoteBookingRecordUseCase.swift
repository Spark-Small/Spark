//
//  ReconcileRemoteBookingRecordUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

/// 将服务端预约副本合并进本地：仅在陪玩端驱动的早期生命周期转移上采信远程。
public struct ReconcileRemoteBookingRecordUseCase: Sendable {
    public init() {}

    public func reconcile(
        local: BuddyBookingRecord,
        remote: BuddyBookingRecord
    ) -> BuddyBookingRecord? {
        guard local.id == remote.id else { return nil }
        if local.status == remote.status {
            return enrichedLocalIfNeeded(local: local, remote: remote)
        }
        guard isServerAuthoritative(from: local.status, to: remote.status) else {
            return nil
        }
        return remote
    }

    private func enrichedLocalIfNeeded(
        local: BuddyBookingRecord,
        remote: BuddyBookingRecord
    ) -> BuddyBookingRecord? {
        var merged = local
        var changed = false
        if merged.confirmDueAt == nil, let confirmDueAt = remote.confirmDueAt {
            merged.confirmDueAt = confirmDueAt
            changed = true
        }
        if merged.status == .awaitingPayment {
            if merged.acceptedAt == nil, let acceptedAt = remote.acceptedAt {
                merged.acceptedAt = acceptedAt
                changed = true
            }
            if merged.paymentDueAt == nil, let paymentDueAt = remote.paymentDueAt {
                merged.paymentDueAt = paymentDueAt
                changed = true
            }
        }
        return changed ? merged : nil
    }

    private func isServerAuthoritative(
        from localStatus: BookingOrderStatus,
        to remoteStatus: BookingOrderStatus
    ) -> Bool {
        switch (localStatus, remoteStatus) {
        case (.pendingConfirm, .awaitingPayment),
             (.pendingConfirm, .cancelled),
             (.awaitingPayment, .cancelled):
            return true
        default:
            return false
        }
    }
}

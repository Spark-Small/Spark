//
//  BuddiesModel+RemoteBookings.swift
//  坐标系
//
//  远程接单：提交、轮询与本地对账（Phase C / FR-BUD-09）。
//

import CoordinateDomain
import Foundation
import CoordinateModels

extension BuddiesModel {
    func syncRemoteBookingStatusesIfNeeded() async {
        guard remoteBookingSync.isEnabled else { return }
        let pendingIDs = bookingRecords.filter {
            $0.status == .pendingConfirm || $0.status == .awaitingPayment
        }.map(\.id)
        for id in pendingIDs {
            guard !Task.isCancelled else { return }
            await syncRemoteBookingStatus(id)
        }
    }

    func submitBookingToRemote(_ id: BuddyBookingRecord.ID) async {
        guard remoteBookingSync.isEnabled,
              let record = bookingRecords.first(where: { $0.id == id }) else { return }
        do {
            let remote = try await remoteBookingSync.submit(record)
            applyRemoteBookingReconciliation(remote)
        } catch {
            // 本地优先：已落盘，轮询会继续拉取陪玩回执
        }
    }

    func syncRemoteBookingStatus(_ id: BuddyBookingRecord.ID) async {
        guard remoteBookingSync.isEnabled else { return }
        do {
            let remote = try await remoteBookingSync.fetchStatus(for: id)
            applyRemoteBookingReconciliation(remote)
        } catch {
            return
        }
    }

    func startRemoteBookingPolling(for id: BuddyBookingRecord.ID) {
        guard remoteBookingSync.isEnabled else { return }
        bookingRemotePollTasks[id]?.cancel()
        bookingRemotePollTasks[id] = Task { @MainActor in
            defer { bookingRemotePollTasks[id] = nil }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard bookingRecords.contains(where: {
                    $0.id == id && ($0.status == .pendingConfirm || $0.status == .awaitingPayment)
                }) else { return }
                await syncRemoteBookingStatus(id)
            }
        }
    }

    func applyRemoteBookingReconciliation(_ remote: BuddyBookingRecord) {
        guard let index = bookingRecords.firstIndex(where: { $0.id == remote.id }) else { return }
        let local = bookingRecords[index]
        guard let reconciled = booking.reconcileRemote.reconcile(local: local, remote: remote) else { return }
        let previousStatus = local.status
        bookingRecords[index] = reconciled

        switch (previousStatus, reconciled.status) {
        case (.pendingConfirm, .awaitingPayment):
            completeCompanionAcceptance(for: remote.id)
        case (.pendingConfirm, .cancelled):
            completeCompanionDecline(for: remote.id)
        case (.awaitingPayment, .cancelled):
            completePaymentRelease(
                for: remote.id,
                trustNote: "远程取消",
                flashMessage: BuddyBookingFlowCopy.paymentExpiredHint
            )
        default:
            if reconciled.status == .pendingConfirm {
                scheduleBookingConfirmationLifecycle(for: remote.id)
            } else if reconciled.status == .awaitingPayment, reconciled.paymentDueAt != nil {
                schedulePaymentExpiry(for: remote.id)
            }
            persist()
            onRecordsChanged?()
        }
    }
}

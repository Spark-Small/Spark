//
//  BuddiesModel+Invites.swift
//  坐标系
//
//  邀约记录编排：创建、接受/拒绝与状态推进。
//

import Foundation
import CoordinateModels

extension BuddiesModel {
    func invite(_ nickname: String) {
        presentation.inviteTarget = BuddyInviteTarget(nickname: nickname)
    }

    @discardableResult
    func recordInvite(
        nickname: String,
        activity: Activity,
        note: String? = nil,
        inviteeUserID: UUID? = nil
    ) -> BuddyInviteRecord {
        let resolvedID = inviteeUserID
            ?? item(for: nickname)?.profile.userID
        let record = inviteService.createInvite(
            nickname: nickname,
            inviteeUserID: resolvedID,
            activity: activity
        )
        inviteRecords.insert(record, at: 0)
        presentation.inviteTarget = nil
        presentation.pendingInviteSuccessID = record.id
        trustService.record(
            .inviteSent,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: resolvedID?.uuidString ?? nickname,
            note: note
        )
        persist()
        onRecordsChanged?()
        scheduleInviteReplySimulation(for: record.id)
        if remoteInviteSync.isEnabled {
            Task { await submitInviteToRemote(record.id) }
        }
        return record
    }

    func submitInviteToRemote(_ id: BuddyInviteRecord.ID) async {
        guard remoteInviteSync.isEnabled,
              let record = inviteRecords.first(where: { $0.id == id }) else { return }
        do {
            let remote = try await remoteInviteSync.submit(record)
            if let index = inviteRecords.firstIndex(where: { $0.id == id }) {
                var merged = inviteRecords[index]
                if merged.inviteeUserID == nil {
                    merged.inviteeUserID = remote.inviteeUserID
                }
                if merged.status == .pending, remote.status != .pending {
                    merged.status = remote.status
                }
                inviteRecords[index] = merged
                persist()
            }
        } catch {
            flash(BuddyFeedbackCopy.remoteInviteSubmitFailed)
        }
    }

    func dismissInviteSuccess() {
        presentation.pendingInviteSuccessID = nil
    }

    func acceptInvite(_ id: BuddyInviteRecord.ID) {
        guard let index = inviteRecords.firstIndex(where: { $0.id == id }) else { return }
        guard inviteRecords[index].status == .pending else { return }
        inviteRecords[index] = inviteService.advanceInvite(inviteRecords[index], to: .accepted)
        trustService.record(
            .inviteAccepted,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: inviteRecords[index].nickname
        )
        persist()
        onRecordsChanged?()
        flash(BuddyFeedbackCopy.inviteAccepted(inviteRecords[index].nickname))
        if let activityID = inviteRecords[index].relatedActivityID {
            presentation.pendingOpenActivityAfterInviteID = activityID
        }
    }

    func declineInvite(_ id: BuddyInviteRecord.ID) {
        guard let index = inviteRecords.firstIndex(where: { $0.id == id }) else { return }
        guard inviteRecords[index].status == .pending else { return }
        inviteRecords[index] = inviteService.advanceInvite(inviteRecords[index], to: .declined)
        trustService.record(
            .inviteDeclined,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: inviteRecords[index].nickname
        )
        persist()
        onRecordsChanged?()
        flash(BuddyFeedbackCopy.inviteDeclined(inviteRecords[index].nickname))
    }

    func deleteInvite(_ id: BuddyInviteRecord.ID) {
        inviteRecords.removeAll { $0.id == id }
        persist()
        onRecordsChanged?()
    }

    func scheduleInviteReplySimulation(for id: BuddyInviteRecord.ID) {
        #if DEBUG
        inviteSimulationTasks[id]?.cancel()
        inviteSimulationTasks[id] = Task { @MainActor in
            defer { inviteSimulationTasks[id] = nil }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            if inviteRecords.contains(where: { $0.id == id && $0.status == .pending }) {
                if abs(id.uuidString.hashValue) % 5 == 0 {
                    declineInvite(id)
                } else {
                    acceptInvite(id)
                }
            }
        }
        #endif
    }
}

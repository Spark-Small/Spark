//
//  BuddiesModel+Invites.swift
//  坐标系
//
//  邀约记录编排：创建、接受/拒绝、演示回复模拟。
//

import Foundation
import CoordinateModels

extension BuddiesModel {
    func invite(_ nickname: String) {
        inviteTarget = BuddyInviteTarget(nickname: nickname)
    }

    @discardableResult
    func recordInvite(
        nickname: String,
        activity: Activity,
        note: String? = nil
    ) -> BuddyInviteRecord {
        let record = inviteService.createInvite(nickname: nickname, activity: activity)
        inviteRecords.insert(record, at: 0)
        inviteTarget = nil
        pendingInviteSuccessID = record.id
        trustService.record(
            .inviteSent,
            domain: .buddy,
            actorKey: trustActorKey(),
            subjectKey: nickname,
            note: note
        )
        persist()
        onRecordsChanged?()
        scheduleInviteReplySimulation(for: record.id)
        return record
    }

    func dismissInviteSuccess() {
        pendingInviteSuccessID = nil
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
        flash("\(inviteRecords[index].nickname) 已接受邀约")
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
        flash("\(inviteRecords[index].nickname) 婉拒了邀约")
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

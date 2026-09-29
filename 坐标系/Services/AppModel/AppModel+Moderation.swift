//
//  AppModel+Moderation.swift
//  坐标系
//

import Foundation
import CoordinateModels

extension AppModel {
    func addModerationTicket(
        postID: UUID,
        title: String,
        reason: String,
        targetKind: ModerationTargetKind = .communityPost
    ) {
        syncOrchestrator.handle(.moderationTicketAdded(
            ModerationTicket(
                id: UUID(),
                postID: postID,
                postTitle: title,
                reason: reason,
                createdAt: .now,
                status: .received,
                targetKind: targetKind
            )
        ))
    }

    func advanceModerationTicket(_ id: ModerationTicket.ID) {
        guard let index = moderationTickets.firstIndex(where: { $0.id == id }) else { return }
        guard let next = moderationTickets[index].status.nextSimulated else { return }
        moderationTickets[index].status = next
        moderationTickets[index].updatedAt = .now
        persistProfile()
    }

    func rejectModerationTicket(_ id: ModerationTicket.ID) {
        guard let index = moderationTickets.firstIndex(where: { $0.id == id }) else { return }
        guard moderationTickets[index].status == .received
            || moderationTickets[index].status == .reviewing
        else { return }
        moderationTickets[index].status = .rejected
        moderationTickets[index].updatedAt = .now
        persistProfile()
    }

    func deleteModerationTicket(_ id: ModerationTicket.ID) {
        moderationTickets.removeAll { $0.id == id }
        persistProfile()
    }
}

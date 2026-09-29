//
//  MessagesCapabilityServices.swift
//  坐标系
//

import Foundation
import CoordinateModels

struct TransferCreationResult {
    let record: TransferRecord
    let message: ChatMessage
}

struct GroupMemberMutationResult {
    let members: [GroupMemberRecord]
    let systemMessage: String?
}

protocol CallingService {
    func startCall(
        kind: CallSessionKind,
        conversationID: UUID
    ) -> CallSessionRecord
}

protocol TransferService {
    func createTransfer(
        conversationID: UUID,
        amount: Double,
        senderName: String,
        recipientName: String
    ) -> TransferCreationResult

    func advanceStatus(
        for record: TransferRecord,
        to status: TransferStatus
    ) -> TransferRecord
}

protocol GroupAdminService {
    func bootstrapMembers(
        ownerName: String?,
        memberNames: [String]
    ) -> [GroupMemberRecord]

    func inviteMembers(
        existing: [GroupMemberRecord],
        nicknames: [String]
    ) -> GroupMemberMutationResult

    func removeMember(
        existing: [GroupMemberRecord],
        nickname: String
    ) -> GroupMemberMutationResult

    func updateRole(
        existing: [GroupMemberRecord],
        nickname: String,
        role: GroupMemberRole
    ) -> GroupMemberMutationResult
}

protocol MessageRequestService {
    func requestSource(for conversation: ChatConversation) -> MessageRequestSource
    func requestPreview(for conversation: ChatConversation) -> String
}

struct LocalCallingService: CallingService {
    func startCall(
        kind: CallSessionKind,
        conversationID: UUID
    ) -> CallSessionRecord {
        CallSessionRecord(
            conversationID: conversationID,
            kind: kind,
            direction: .outgoing,
            status: .ringing
        )
    }
}

struct LocalTransferService: TransferService {
    func createTransfer(
        conversationID: UUID,
        amount: Double,
        senderName: String,
        recipientName: String
    ) -> TransferCreationResult {
        let messageID = UUID()
        let record = TransferRecord(
            conversationID: conversationID,
            amount: amount,
            senderName: senderName,
            recipientName: recipientName,
            messageID: messageID
        )
        let message = ChatMessage(
            id: messageID,
            sender: senderName,
            text: MessagesCopy.transferTitle,
            sentAt: record.createdAt,
            isMe: true,
            messageKind: .transfer,
            transferAmount: amount,
            transferID: record.id,
            deliveryStatus: MessagingDeliveryPolicy.upgradesLocalSendToDelivered ? .delivered : .sent
        )
        return TransferCreationResult(record: record, message: message)
    }

    func advanceStatus(
        for record: TransferRecord,
        to status: TransferStatus
    ) -> TransferRecord {
        var next = record
        next.status = status
        next.updatedAt = .now
        return next
    }
}

struct LocalGroupAdminService: GroupAdminService {
    func bootstrapMembers(
        ownerName: String?,
        memberNames: [String]
    ) -> [GroupMemberRecord] {
        var seen = Set<String>()
        return memberNames.compactMap { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else { return nil }
            let role: GroupMemberRole = ownerName?.caseInsensitiveCompare(trimmed) == .orderedSame ? .owner : .member
            return GroupMemberRecord(nickname: trimmed, role: role)
        }
    }

    func inviteMembers(
        existing: [GroupMemberRecord],
        nicknames: [String]
    ) -> GroupMemberMutationResult {
        var next = existing
        var added: [String] = []
        for raw in nicknames {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if next.contains(where: { $0.nickname.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                continue
            }
            next.append(GroupMemberRecord(nickname: trimmed))
            added.append(trimmed)
        }
        let message = added.isEmpty ? nil : "\(added.joined(separator: "、"))加入了群聊"
        return GroupMemberMutationResult(members: next, systemMessage: message)
    }

    func removeMember(
        existing: [GroupMemberRecord],
        nickname: String
    ) -> GroupMemberMutationResult {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = existing.filter { $0.nickname.caseInsensitiveCompare(trimmed) != .orderedSame }
        return GroupMemberMutationResult(
            members: next,
            systemMessage: trimmed.isEmpty ? nil : MessagesCopy.memberKicked(trimmed)
        )
    }

    func updateRole(
        existing: [GroupMemberRecord],
        nickname: String,
        role: GroupMemberRole
    ) -> GroupMemberMutationResult {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = existing.map { member in
            guard member.nickname.caseInsensitiveCompare(trimmed) == .orderedSame else { return member }
            var updated = member
            updated.role = role
            return updated
        }
        let message = trimmed.isEmpty ? nil : "\(trimmed)现在是\(role.rawValue)"
        return GroupMemberMutationResult(members: next, systemMessage: message)
    }
}

struct LocalMessageRequestService: MessageRequestService {
    func requestSource(for conversation: ChatConversation) -> MessageRequestSource {
        conversation.requestSource ?? .directMessage
    }

    func requestPreview(for conversation: ChatConversation) -> String {
        conversation.requestPreview
    }
}

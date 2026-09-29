//
//  MessagesModel+Calling.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    // MARK: - Calling / transfer / group admin / requests

    @discardableResult
    func startVoiceCall(in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        startCall(kind: .voice, in: conversationID)
    }

    @discardableResult
    func startVideoCall(in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        startCall(kind: .video, in: conversationID)
    }

    @discardableResult
    func startCall(kind: CallSessionKind, in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        guard index(of: conversationID) != nil else { return nil }
        if let active = activeCall(for: conversationID) { return active }
        let call = callingService.startCall(kind: kind, conversationID: conversationID)
        callRecords.insert(call, at: 0)
        appendSystemTip("已发起\(kind.rawValue)", audience: .everyone, to: conversationID)
        persist()
        return call
    }

    func connectCall(_ callID: CallSessionRecord.ID) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }),
              callRecords[index].status == .ringing || callRecords[index].status == .connecting
        else { return }
        callRecords[index].status = .active
        callRecords[index].connectedAt = .now
        persist()
    }

    func endCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .ended)
    }

    func rejectCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .rejected)
    }

    func cancelCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .cancelled)
    }

    func missCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .missed)
    }

    func updateCall(_ callID: CallSessionRecord.ID, to status: CallSessionStatus) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }) else { return }
        guard callRecords[index].status != status else { return }
        callRecords[index].status = status
        if callRecords[index].connectedAt == nil, status == .active {
            callRecords[index].connectedAt = .now
        }
        if status == .ended || status == .missed || status == .cancelled || status == .rejected {
            callRecords[index].endedAt = .now
            appendSystemTip(callSummary(callRecords[index]), audience: .everyone, to: callRecords[index].conversationID)
        }
        persist()
    }

    func callSummary(_ record: CallSessionRecord) -> String {
        switch record.status {
        case .missed:
            return "\(record.kind.rawValue)未接听"
        case .cancelled:
            return "\(record.kind.rawValue)已取消"
        case .rejected:
            return "\(record.kind.rawValue)已拒绝"
        case .ended:
            if let connectedAt = record.connectedAt, let endedAt = record.endedAt {
                let duration = max(Int(endedAt.timeIntervalSince(connectedAt)), 0)
                let minute = duration / 60
                let second = duration % 60
                return "\(record.kind.rawValue) \(String(format: "%02d:%02d", minute, second))"
            }
            return "\(record.kind.rawValue)已结束"
        case .ringing, .connecting, .active:
            return record.kind.rawValue
        }
    }

    @discardableResult
    func sendTransfer(
        amount: Double,
        to id: ChatConversation.ID,
        currentUserName: String
    ) -> ChatMessage? {
        guard let conversation = conversations.first(where: { $0.id == id }) else { return nil }
        let cents = WalletMoney.cents(fromYuan: amount)
        guard cents > 0 else { return nil }
        let charge = walletStore.charge(
            amountCents: cents,
            method: .wallet,
            kind: .transferOut,
            title: "转账给\(conversation.kind == .direct ? conversation.title : conversation.ownerName ?? MessagesCopy.memberFallback)",
            subtitle: WalletMoney.formatted(cents: cents)
        )
        guard charge == .success else { return nil }

        let recipient = conversation.kind == .direct
            ? conversation.title
            : conversation.ownerName ?? MessagesCopy.memberFallback
        let result = transferService.createTransfer(
            conversationID: id,
            amount: amount,
            senderName: currentUserName,
            recipientName: recipient
        )
        walletStore.attachRelatedID(result.record.id, toKind: .transferOut, amountCents: cents)
        transferRecords.insert(result.record, at: 0)
        appendMessage(result.message, to: id)
        scheduleTransferExpiration(for: result.record.id)
        return result.message
    }

    /// 启动 / 重载 / 会话出现时：推进已到期转账，并为待收款重挂定时器
    func refreshTransferExpirations() {
        for task in transferExpirationTasks.values {
            task.cancel()
        }
        transferExpirationTasks.removeAll()

        for record in transferRecords where record.status == .pending {
            if record.isPastExpiration {
                expireTransfer(record.id)
            } else {
                scheduleTransferExpiration(for: record.id)
            }
        }
    }

    func acceptTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .accepted)
    }

    func cancelTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .cancelled)
    }

    func refundTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .refunded)
    }

    func expireTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .expired)
    }

    func updateTransfer(_ transferID: TransferRecord.ID, to status: TransferStatus) {
        guard let index = transferRecords.firstIndex(where: { $0.id == transferID }) else { return }
        let previousStatus = transferRecords[index].status
        guard previousStatus != status else { return }
        if previousStatus == .pending {
            cancelTransferExpiration(for: transferID)
        }
        let record = transferRecords[index]
        transferRecords[index] = transferService.advanceStatus(for: record, to: status)

        let cents = WalletMoney.cents(fromYuan: record.amount)
        switch (previousStatus, status) {
        case (.pending, .cancelled), (.pending, .expired), (.accepted, .refunded):
            // 发送方取消/过期，或收款后退回：退回发送方余额
            walletStore.credit(
                amountCents: cents,
                method: .wallet,
                kind: .transferRefund,
                title: "转账退回",
                subtitle: record.recipientName,
                relatedID: transferID
            )
        case (.pending, .accepted):
            // 收款方入账（对方发出的转账）
            walletStore.credit(
                amountCents: cents,
                method: .wallet,
                kind: .transferIn,
                title: "收到转账",
                subtitle: record.senderName,
                relatedID: transferID
            )
        default:
            break
        }

        if status == .expired {
            appendSystemTip(
                MessagesCopy.transferExpiredNotice(amount: record.amount),
                audience: .everyone,
                to: record.conversationID
            )
        } else {
            persist()
        }
    }

    func scheduleTransferExpiration(for transferID: TransferRecord.ID) {
        transferExpirationTasks[transferID]?.cancel()
        guard let index = transferRecords.firstIndex(where: { $0.id == transferID }),
              transferRecords[index].status == .pending
        else { return }

        let delay = transferRecords[index].expiresAt.timeIntervalSinceNow
        if delay <= 0 {
            expireTransfer(transferID)
            return
        }

        transferExpirationTasks[transferID] = Task { @MainActor in
            defer { transferExpirationTasks[transferID] = nil }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled,
                  let idx = transferRecords.firstIndex(where: { $0.id == transferID }),
                  transferRecords[idx].status == .pending
            else { return }
            expireTransfer(transferID)
        }
    }

    func cancelTransferExpiration(for transferID: TransferRecord.ID) {
        transferExpirationTasks[transferID]?.cancel()
        transferExpirationTasks[transferID] = nil
    }

    func inviteMembers(_ nicknames: [String], to conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.inviteMembers(existing: current, nicknames: nicknames)
        applyGroupMemberMutation(result, to: conversationID)
    }

    func removeMember(_ nickname: String, from conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.removeMember(existing: current, nickname: nickname)
        applyGroupMemberMutation(result, to: conversationID)
    }

    func updateMemberRole(_ nickname: String, role: GroupMemberRole, in conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.updateRole(existing: current, nickname: nickname, role: role)
        applyGroupMemberMutation(result, to: conversationID)
    }

    /// 群主转让：原群主降为成员，新群主唯一。
    func transferGroupOwnership(to nickname: String, in conversationID: ChatConversation.ID) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = index(of: conversationID) else { return }

        let next = groupMembers(for: conversationID).map { member -> GroupMemberRecord in
            var updated = member
            if updated.role == .owner {
                updated.role = .member
            }
            if updated.nickname.caseInsensitiveCompare(trimmed) == .orderedSame {
                updated.role = .owner
            }
            return updated
        }
        conversations[index].ownerName = trimmed
        groupMembersByConversation[conversationID] = next
        conversations[index].memberNames = next.map(\.nickname)
        appendSystemTip("「\(trimmed)」已成为群主", audience: .everyone, to: conversationID)
        persist()
        onConversationsChanged?()
    }

    /// 添加群管理员（最多 3 名，不含群主）。
    func addGroupAdmin(_ nickname: String, in conversationID: ChatConversation.ID) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let admins = groupMembers(for: conversationID).filter { $0.role == .admin }
        guard admins.count < 3 else { return }
        guard role(of: trimmed, in: conversationID) == .member else { return }
        updateMemberRole(trimmed, role: .admin, in: conversationID)
    }

    /// 移除群管理员身份（降为普通成员）。
    func removeGroupAdmin(_ nickname: String, in conversationID: ChatConversation.ID) {
        guard role(of: nickname, in: conversationID) == .admin else { return }
        updateMemberRole(nickname, role: .member, in: conversationID)
    }

    func applyGroupMemberMutation(
        _ result: GroupMemberMutationResult,
        to conversationID: ChatConversation.ID
    ) {
        groupMembersByConversation[conversationID] = result.members
        if let index = index(of: conversationID) {
            conversations[index].memberNames = result.members.map(\.nickname)
        }
        if let systemMessage = result.systemMessage, !systemMessage.isEmpty {
            appendSystemTip(systemMessage, audience: .everyone, to: conversationID)
        } else {
            persist()
        }
    }

}

//
//  MessagesModel+Transfer.swift
//  坐标系
//
//  本机转账：扣款 / 过期 / 收款退回。
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
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
}
